<?php

namespace App\Services;

use App\Models\Transaction;
use App\Models\User;
use App\Models\Notification;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class PaymentService
{
    public function depositChariow($userId, $amount, $email, $provider = 'orange')
    {
        $user = User::find($userId);
        if (!$user) throw new \Exception('Utilisateur non trouvé.');

        $reference = 'CHR-DEP-' . Str::random(16);

        $transaction = Transaction::create([
            'user_id' => $userId,
            'type' => 'deposit',
            'amount' => $amount,
            'reference' => $reference,
            'payment_method' => 'chariow_' . $provider,
            'status' => 'pending',
            'description' => 'Dépôt via Chariow (' . $provider . ')',
            'metadata' => json_encode([
                'email' => $email,
                'provider' => $provider,
                'initiated_at' => now()->toISOString(),
            ]),
        ]);

        try {
            $apiKey = config('chariow.api_key');
            $productId = config('chariow.deposit_product_id', 'prd_dd7c35ic');
            $storeUrl = config('chariow.store_url', 'https://epazzsvw.mychariow.store');

            if (!$apiKey) {
                $transaction->update([
                    'status' => 'failed',
                    'metadata' => array_merge($transaction->metadata ?? [], [
                        'error' => 'Clé API Chariow non configurée',
                    ]),
                ]);
                return ['success' => false, 'message' => 'Service de paiement non configuré.'];
            }

            $response = Http::timeout(30)
                ->withHeaders([
                    'Authorization' => 'Bearer ' . $apiKey,
                    'Content-Type' => 'application/json',
                ])
                ->post('https://api.chariow.com/v1/checkout', [
                    'product_id' => $productId,
                    'email' => $email,
                    'first_name' => $user->name ?? 'Utilisateur',
                    'last_name' => 'TWC',
                    'phone' => [
                        'number' => $user->phone ?? '000000000',
                        'country_code' => 'CD',
                    ],
                    'payment_currency' => 'CDF',
                    'redirect_url' => $storeUrl . '/thank-you',
                    'custom_metadata' => [
                        'user_id' => (string) $userId,
                        'reference' => $reference,
                        'type' => 'deposit',
                    ],
                ]);

            if ($response->successful()) {
                $data = $response->json();
                $step = $data['data']['step'] ?? null;

                if ($step === 'payment') {
                    $checkoutUrl = $data['data']['payment']['checkout_url'] ?? null;
                    $saleId = $data['data']['purchase']['id'] ?? null;

                    $transaction->update([
                        'metadata' => array_merge($transaction->metadata ?? [], [
                            'chariow_sale_id' => $saleId,
                            'checkout_url' => $checkoutUrl,
                        ]),
                    ]);

                    return [
                        'success' => true,
                        'transaction' => $transaction,
                        'payment_url' => $checkoutUrl,
                        'message' => 'Redirection vers le paiement...',
                    ];
                }

                if ($step === 'completed') {
                    $transaction->update([
                        'status' => 'completed',
                        'completed_at' => now(),
                    ]);
                    $user->increment('boost_balance', $amount);

                    return [
                        'success' => true,
                        'transaction' => $transaction,
                        'payment_url' => null,
                        'message' => 'Paiement confirmé.',
                    ];
                }
            }

            $errorMsg = $response->json('message') ?? 'Erreur lors du paiement.';
            $transaction->update([
                'status' => 'failed',
                'metadata' => array_merge($transaction->metadata ?? [], ['error' => $errorMsg]),
            ]);

            return ['success' => false, 'message' => $errorMsg];
        } catch (\Exception $e) {
            Log::error('Chariow deposit exception: ' . $e->getMessage());
            $transaction->update([
                'status' => 'failed',
                'metadata' => array_merge($transaction->metadata ?? [], ['error' => $e->getMessage()]),
            ]);
            return ['success' => false, 'message' => 'Erreur technique: ' . $e->getMessage()];
        }
    }

    public function depositOrangeMoney($userId, $amount, $email)
    {
        return $this->depositChariow($userId, $amount, $email, 'orange');
    }

    public function depositMtnMoney($userId, $amount, $email)
    {
        return $this->depositChariow($userId, $amount, $email, 'mtn');
    }

    public function withdrawChariow($userId, $amount, $phone, $provider = 'orange')
    {
        $user = User::find($userId);
        if (!$user) throw new \Exception('Utilisateur non trouvé.');
        if ($user->boost_balance < $amount) throw new \Exception('Solde insuffisant.');

        $reference = 'CHR-WD-' . Str::random(12);

        DB::beginTransaction();
        try {
            $user->decrement('boost_balance', $amount);

            $transaction = Transaction::create([
                'user_id' => $userId,
                'type' => 'withdrawal',
                'amount' => $amount,
                'reference' => $reference,
                'payment_method' => 'chariow_' . $provider,
                'status' => 'pending',
                'description' => 'Retrait via Chariow',
                'metadata' => json_encode([
                    'phone' => $phone,
                    'provider' => $provider,
                    'initiated_at' => now()->toISOString(),
                ]),
            ]);

            DB::commit();
            return $transaction;
        } catch (\Exception $e) {
            DB::rollBack();
            throw $e;
        }
    }

    public function withdraw($userId, $amount, $phoneNumber, $method = 'orange')
    {
        return $this->withdrawChariow($userId, $amount, $phoneNumber, $method);
    }

    public function transfer($fromUserId, $toUserId, $amount, $description = null)
    {
        if ($fromUserId === $toUserId) throw new \Exception('Impossible de se transférer à soi-même.');
        $fromUser = User::find($fromUserId);
        $toUser = User::find($toUserId);
        if (!$fromUser || !$toUser) throw new \Exception('Utilisateur non trouvé.');
        if ($fromUser->boost_balance < $amount) throw new \Exception('Solde insuffisant.');

        DB::beginTransaction();
        try {
            $fromUser->decrement('boost_balance', $amount);
            $toUser->increment('boost_balance', $amount);
            $senderTransaction = Transaction::create([
                'user_id' => $fromUserId,
                'type' => 'transfer_sent',
                'amount' => $amount,
                'reference' => 'TRF-' . Str::random(12),
                'payment_method' => 'wallet',
                'status' => 'completed',
                'description' => $description ?? 'Transfert vers ' . $toUser->name,
                'metadata' => json_encode(['to_user_id' => $toUserId, 'to_user_name' => $toUser->name]),
                'completed_at' => now(),
            ]);
            $receiverTransaction = Transaction::create([
                'user_id' => $toUserId,
                'type' => 'transfer_received',
                'amount' => $amount,
                'reference' => 'TRF-' . Str::random(12),
                'payment_method' => 'wallet',
                'status' => 'completed',
                'description' => $description ?? 'Reçu de ' . $fromUser->name,
                'metadata' => json_encode(['from_user_id' => $fromUserId, 'from_user_name' => $fromUser->name]),
                'completed_at' => now(),
            ]);
            $this->createNotification($fromUserId, 'transfer_sent', 'Vous avez envoyé ' . number_format($amount, 0) . ' CDF à ' . $toUser->name, ['transaction_id' => $senderTransaction->id]);
            $this->createNotification($toUserId, 'transfer_received', 'Vous avez reçu ' . number_format($amount, 0) . ' CDF de ' . $fromUser->name, ['transaction_id' => $receiverTransaction->id]);
            DB::commit();
            return ['sender_transaction' => $senderTransaction, 'receiver_transaction' => $receiverTransaction];
        } catch (\Exception $e) {
            DB::rollBack();
            throw $e;
        }
    }

    public function checkChariowStatus($transactionId)
    {
        $transaction = Transaction::find($transactionId);
        if (!$transaction) return ['success' => false, 'message' => 'Transaction non trouvée.'];

        if ($transaction->status === 'completed') {
            return ['success' => true, 'status' => 'completed', 'transaction' => $transaction];
        }

        return ['success' => true, 'status' => $transaction->status, 'transaction' => $transaction];
    }

    private function createNotification($userId, $type, $message, $data = [])
    {
        Notification::create([
            'user_id' => $userId,
            'type' => $type,
            'message' => $message,
            'data' => json_encode($data),
            'has_sound' => true,
            'is_read' => false,
        ]);
    }
}
