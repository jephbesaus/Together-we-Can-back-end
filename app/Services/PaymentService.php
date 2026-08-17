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
            $baseUrl = config('chariow.payment_url');

            if (!$apiKey) {
                $transaction->update([
                    'status' => 'failed',
                    'metadata' => array_merge($transaction->metadata ?? [], [
                        'error' => 'Clé API Chariow non configurée',
                    ]),
                ]);
                return ['success' => false, 'message' => 'Service de paiement non configuré.'];
            }

            $response = Http::timeout(30)->post($baseUrl . '/api/payments/initiate', [
                'api_key' => $apiKey,
                'amount' => $amount,
                'email' => $email,
                'reference' => $reference,
                'provider' => $provider,
                'currency' => config('chariow.currency', 'CDF'),
                'callback_url' => url('/api/webhooks/chariow'),
                'description' => 'Dépôt Together We Can - ' . $reference,
            ]);

            if ($response->successful()) {
                $data = $response->json();
                $transaction->update([
                    'metadata' => array_merge($transaction->metadata ?? [], [
                        'chariow' => $data,
                        'payment_url' => $data['payment_url'] ?? null,
                        'chariow_reference' => $data['reference'] ?? null,
                    ]),
                ]);

                return [
                    'success' => true,
                    'transaction' => $transaction,
                    'payment_url' => $data['payment_url'] ?? null,
                    'message' => 'Demande de paiement envoyée.',
                ];
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

    public function depositFusionPay($userId, $amount, $phoneNumber, $provider = 'orange')
    {
        $reference = 'DEP-' . Str::random(16);
        $transaction = Transaction::create([
            'user_id' => $userId,
            'type' => 'deposit',
            'amount' => $amount,
            'reference' => $reference,
            'payment_method' => $provider,
            'status' => 'pending',
            'description' => 'Dépôt via FusionPay (' . $provider . ')',
            'metadata' => json_encode(['phone' => $phoneNumber, 'provider' => $provider, 'initiated_at' => now()->toISOString()]),
        ]);

        try {
            $fusionPay = app(FusionPayService::class);
            $result = $fusionPay->initiatePayment($amount, $phoneNumber, $reference, 'Dépôt Together We Can - ' . $reference);
            if ($result['status'] === 'success') {
                $transaction->update(['metadata' => array_merge($transaction->metadata ?? [], ['fusionpay' => $result, 'transaction_id' => $result['transaction_id'] ?? null])]);
                return ['success' => true, 'transaction' => $transaction, 'payment_url' => $result['payment_url'] ?? null, 'message' => 'Demande de paiement envoyée.'];
            } else {
                $transaction->update(['status' => 'failed', 'metadata' => array_merge($transaction->metadata ?? [], ['error' => $result['message'] ?? 'Erreur inconnue'])]);
                return ['success' => false, 'message' => $result['message'] ?? 'Erreur lors du paiement.'];
            }
        } catch (\Exception $e) {
            $transaction->update(['status' => 'failed', 'metadata' => array_merge($transaction->metadata ?? [], ['error' => $e->getMessage()])]);
            return ['success' => false, 'message' => 'Erreur technique: ' . $e->getMessage()];
        }
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

            $apiKey = config('chariow.api_key');
            $baseUrl = config('chariow.payment_url');

            if ($apiKey) {
                try {
                    $response = Http::timeout(30)->post($baseUrl . '/api/payments/withdraw', [
                        'api_key' => $apiKey,
                        'amount' => $amount,
                        'phone' => $phone,
                        'provider' => $provider,
                        'reference' => $reference,
                        'currency' => config('chariow.currency', 'CDF'),
                    ]);

                    if ($response->successful()) {
                        $data = $response->json();
                        $transaction->update([
                            'status' => 'processing',
                            'metadata' => array_merge($transaction->metadata ?? [], [
                                'chariow_withdrawal' => $data,
                            ]),
                        ]);
                    } else {
                        $transaction->update([
                            'status' => 'failed',
                            'metadata' => array_merge($transaction->metadata ?? [], [
                                'error' => $response->json('message') ?? 'Erreur retrait',
                            ]),
                        ]);
                        $user->increment('boost_balance', $amount);
                        DB::rollBack();
                        return $transaction;
                    }
                } catch (\Exception $e) {
                    Log::error('Chariow withdraw API error: ' . $e->getMessage());
                    $transaction->update([
                        'status' => 'failed',
                        'metadata' => array_merge($transaction->metadata ?? [], ['error' => $e->getMessage()]),
                    ]);
                    $user->increment('boost_balance', $amount);
                    DB::rollBack();
                    return $transaction;
                }
            }

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
            $senderTransaction = Transaction::create(['user_id' => $fromUserId, 'type' => 'transfer_sent', 'amount' => $amount, 'reference' => 'TRF-' . Str::random(12), 'payment_method' => 'wallet', 'status' => 'completed', 'description' => $description ?? 'Transfert vers ' . $toUser->name, 'metadata' => json_encode(['to_user_id' => $toUserId, 'to_user_name' => $toUser->name]), 'completed_at' => now()]);
            $receiverTransaction = Transaction::create(['user_id' => $toUserId, 'type' => 'transfer_received', 'amount' => $amount, 'reference' => 'TRF-' . Str::random(12), 'payment_method' => 'wallet', 'status' => 'completed', 'description' => $description ?? 'Reçu de ' . $fromUser->name, 'metadata' => json_encode(['from_user_id' => $fromUserId, 'from_user_name' => $fromUser->name]), 'completed_at' => now()]);
            $this->createNotification($fromUserId, 'transfer_sent', 'Vous avez envoyé ' . number_format($amount, 0) . ' CDF à ' . $toUser->name, ['transaction_id' => $senderTransaction->id]);
            $this->createNotification($toUserId, 'transfer_received', 'Vous avez reçu ' . number_format($amount, 0) . ' CDF de ' . $fromUser->name, ['transaction_id' => $receiverTransaction->id]);
            DB::commit();
            return ['sender_transaction' => $senderTransaction, 'receiver_transaction' => $receiverTransaction];
        } catch (\Exception $e) { DB::rollBack(); throw $e; }
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
        Notification::create(['user_id' => $userId, 'type' => $type, 'message' => $message, 'data' => json_encode($data), 'has_sound' => true, 'is_read' => false]);
    }
}
