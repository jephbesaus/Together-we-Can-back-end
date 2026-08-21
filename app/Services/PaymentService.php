<?php

namespace App\Services;

use App\Models\Transaction;
use App\Models\User;
use App\Models\Notification;
use Illuminate\Support\Facades\DB;
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
                'amount' => $amount,
                'initiated_at' => now()->toISOString(),
            ]),
        ]);

        try {
            $storeUrl = config('chariow.store_url') ?: 'https://epazzsvw.mychariow.store';
            $depositProductId = config('chariow.deposit_product_id') ?: 'prd_dd7c35ic';
            $apiKey = config('chariow.api_key');

            if ($apiKey) {
                $response = \Illuminate\Support\Facades\Http::timeout(15)
                    ->withHeaders([
                        'Authorization' => 'Bearer ' . $apiKey,
                        'Content-Type' => 'application/json',
                    ])
                    ->post('https://api.chariow.com/v1/checkout', [
                        'product_id' => $depositProductId,
                        'email' => $email,
                        'first_name' => $user->name ?? 'Utilisateur',
                        'last_name' => 'TWC',
                        'phone' => [
                            'number' => $user->phone ?? '000000000',
                            'country_code' => 'CD',
                        ],
                        'payment_currency' => 'CDF',
                        'redirect_url' => url('/thank-you?reference=' . $reference . '&type=deposit&transaction_id=' . $transaction->id),
                        'custom_metadata' => [
                            'user_id' => (string) $userId,
                            'reference' => $reference,
                            'type' => 'deposit',
                            'amount' => (string) $amount,
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
            }
        } catch (\Exception $e) {
            Log::warning('Chariow API checkout failed, falling back to store redirect: ' . $e->getMessage());
        }

        $storeUrl = config('chariow.store_url') ?: 'https://epazzsvw.mychariow.store';
        $depositProductId = config('chariow.deposit_product_id') ?: 'prd_dd7c35ic';
        $paymentUrl = rtrim($storeUrl, '/') . '/' . $depositProductId;

        return [
            'success' => true,
            'transaction' => $transaction,
            'payment_url' => $paymentUrl,
            'message' => 'Redirection vers la boutique Chariow...',
        ];
    }

    public function depositOrangeMoney($userId, $amount, $email)
    {
        return $this->depositChariow($userId, $amount, $email, 'orange');
    }

    /**
     * Dépôt via FusionPay (moneyfusion.net) : le montant est dynamique,
     * le client paie EXACTEMENT le montant saisi en CDF.
     */
    public function depositFusionPay($userId, $amount, $phone, $provider = 'orange')
    {
        $user = User::find($userId);
        if (!$user) throw new \Exception('Utilisateur non trouvé.');

        $apiUrl = rtrim((string) config('fusionpay.api_url'), '/');
        if (!$apiUrl) {
            return ['success' => false, 'message' => 'Paiement mobile non configuré. Utilisez le paiement manuel.'];
        }

        $reference = 'FUP-DEP-' . Str::random(14);

        $transaction = Transaction::create([
            'user_id' => $userId,
            'type' => 'deposit',
            'amount' => $amount,
            'reference' => $reference,
            'payment_method' => 'fusionpay_' . $provider,
            'status' => 'pending',
            'description' => 'Dépôt via FusionPay (' . $provider . ')',
            'metadata' => [
                'provider' => $provider,
                'phone' => $phone,
                'amount' => $amount,
                'initiated_at' => now()->toISOString(),
            ],
        ]);

        try {
            $payload = [
                'totalPrice' => (float) $amount,
                'article' => [
                    ['Depot Together We Can ' . $reference => (float) $amount],
                ],
                'personal_Info' => [
                    [
                        'user_id' => (string) $userId,
                        'transaction_id' => (string) $transaction->id,
                        'reference' => $reference,
                    ],
                ],
                'numeroSend' => preg_replace('/\D/', '', (string) $phone),
                'nomclient' => $user->name ?: 'Client TWC',
                'return_url' => url('/thank-you?reference=' . $reference . '&type=deposit&transaction_id=' . $transaction->id),
                'webhook_url' => url('/api/webhooks/fusionpay'),
            ];

            $http = \Illuminate\Support\Facades\Http::timeout(20);
            if (config('fusionpay.api_key')) {
                $http = $http->withHeaders(['Authorization' => 'Bearer ' . config('fusionpay.api_key')]);
            }
            $response = $http->post($apiUrl, $payload);

            Log::info('FusionPay checkout response', [
                'transaction_id' => $transaction->id,
                'status' => $response->status(),
                'body' => mb_substr($response->body(), 0, 500),
            ]);

            if (!$response->successful()) {
                throw new \Exception('HTTP ' . $response->status());
            }

            $data = $response->json();
            $paymentUrl = $data['url'] ?? $data['data']['url'] ?? $data['link'] ?? null;
            $token = $data['token'] ?? $data['tokenPay'] ?? $data['data']['token'] ?? null;

            if (!$paymentUrl && !$token) {
                throw new \Exception('Réponse FusionPay invalide (ni url ni token).');
            }

            $transaction->update([
                'metadata' => array_merge($transaction->metadata ?? [], [
                    'fusionpay_token' => $token,
                    'payment_url' => $paymentUrl,
                ]),
            ]);

            return [
                'success' => true,
                'transaction' => $transaction->fresh(),
                'payment_url' => $paymentUrl,
                'message' => 'Redirection vers le paiement...',
            ];
        } catch (\Exception $e) {
            Log::warning('FusionPay checkout failed: ' . $e->getMessage());
            $transaction->update([
                'status' => 'failed',
                'description' => 'Échec initiation FusionPay : ' . $e->getMessage(),
            ]);
            return [
                'success' => false,
                'message' => 'Impossible d\'initier le paiement. Réessayez ou utilisez le paiement manuel.',
            ];
        }
    }

    /**
     * Vérifie le statut d'un dépôt FusionPay auprès de l'agrégateur
     * et crédite le solde si le paiement est confirmé.
     */
    public function checkFusionPayStatus($transaction)
    {
        $token = $transaction->metadata['fusionpay_token'] ?? null;
        if (!$token) {
            return ['success' => false, 'message' => 'Token FusionPay manquant.'];
        }

        try {
            $response = \Illuminate\Support\Facades\Http::timeout(15)
                ->get(rtrim((string) config('fusionpay.status_base_url'), '/') . '/' . $token);

            if (!$response->successful()) {
                return ['success' => false, 'message' => 'Vérification impossible pour le moment.'];
            }

            $data = $response->json();
            $statut = strtolower($data['data']['statut'] ?? $data['statut'] ?? '');

            if ($statut === 'paid') {
                $this->completeDeposit($transaction, 'fusionpay_status_check');
                return ['success' => true, 'status' => $transaction->fresh()->status, 'transaction' => $transaction->fresh()];
            }

            if (in_array($statut, ['failed', 'no paid', 'no_paid', 'canceled', 'cancelled'])) {
                $transaction->update(['status' => 'failed']);
                return ['success' => true, 'status' => 'failed', 'transaction' => $transaction->fresh()];
            }

            return ['success' => true, 'status' => $transaction->fresh()->status, 'transaction' => $transaction->fresh()];
        } catch (\Exception $e) {
            Log::warning('FusionPay status check failed: ' . $e->getMessage());
            return ['success' => false, 'message' => 'Vérification impossible pour le moment.'];
        }
    }

    /**
     * Finalise un dépôt : marque la transaction comme complétée et
     * crédite le solde de l'utilisateur. Idempotent.
     */
    public function completeDeposit(Transaction $transaction, $source = 'manual')
    {
        if ($transaction->type !== 'deposit' || $transaction->status !== 'pending') {
            return false;
        }

        DB::beginTransaction();
        try {
            // Re-verrouille la transaction pour éviter un double crédit concurrent.
            $fresh = Transaction::where('id', $transaction->id)->where('status', 'pending')->lockForUpdate()->first();
            if (!$fresh) {
                DB::rollBack();
                return false;
            }

            $fresh->update([
                'status' => 'completed',
                'completed_at' => now(),
                'metadata' => array_merge($fresh->metadata ?? [], [
                    'completed_via' => $source,
                    'completed_at' => now()->toISOString(),
                ]),
            ]);

            User::where('id', $fresh->user_id)->increment('boost_balance', $fresh->amount);

            DB::commit();
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Deposit completion failed: ' . $e->getMessage());
            return false;
        }

        Notification::create([
            'user_id' => $fresh->user_id,
            'type' => 'payment_approved',
            'message' => 'Votre dépôt de ' . number_format($fresh->amount, 0, ',', '.') . ' CDF a été confirmé et crédité sur votre compte.',
            'has_sound' => true,
        ]);

        return true;
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

    public function coursePayment($userId, $courseId, $amount, $email)
    {
        $user = User::find($userId);
        if (!$user) throw new \Exception('Utilisateur non trouvé.');

        $reference = 'CHR-CRS-' . Str::random(16);

        $transaction = Transaction::create([
            'user_id' => $userId,
            'type' => 'course_payment',
            'amount' => $amount,
            'reference' => $reference,
            'payment_method' => 'chariow',
            'status' => 'pending',
            'description' => 'Paiement formation #' . $courseId,
            'metadata' => json_encode([
                'course_id' => $courseId,
                'email' => $email,
                'amount' => $amount,
                'initiated_at' => now()->toISOString(),
            ]),
        ]);

        try {
            $storeUrl = config('chariow.store_url') ?: 'https://epazzsvw.mychariow.store';
            $depositProductId = config('chariow.deposit_product_id') ?: 'prd_dd7c35ic';
            $apiKey = config('chariow.api_key');

            if ($apiKey) {
                $response = \Illuminate\Support\Facades\Http::timeout(15)
                    ->withHeaders([
                        'Authorization' => 'Bearer ' . $apiKey,
                        'Content-Type' => 'application/json',
                    ])
                    ->post('https://api.chariow.com/v1/checkout', [
                        'product_id' => $depositProductId,
                        'email' => $email,
                        'first_name' => $user->name ?? 'Utilisateur',
                        'last_name' => 'TWC',
                        'phone' => [
                            'number' => $user->phone ?? '000000000',
                            'country_code' => 'CD',
                        ],
                        'payment_currency' => 'CDF',
                        'redirect_url' => url('/thank-you?reference=' . $reference . '&type=course&courseId=' . $courseId),
                        'custom_metadata' => [
                            'user_id' => (string) $userId,
                            'reference' => $reference,
                            'type' => 'course_payment',
                            'course_id' => (string) $courseId,
                            'amount' => (string) $amount,
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
                        ];
                    }

                    if ($step === 'completed') {
                        $transaction->update([
                            'status' => 'completed',
                            'completed_at' => now(),
                        ]);

                        return [
                            'success' => true,
                            'transaction' => $transaction,
                            'payment_url' => null,
                            'message' => 'Paiement confirmé.',
                        ];
                    }
                }
            }
        } catch (\Exception $e) {
            Log::warning('Chariow API course checkout failed, using store redirect: ' . $e->getMessage());
        }

        $storeUrl = config('chariow.store_url') ?: 'https://epazzsvw.mychariow.store';
        $depositProductId = config('chariow.deposit_product_id') ?: 'prd_dd7c35ic';
        $paymentUrl = rtrim($storeUrl, '/') . '/' . $depositProductId;

        return [
            'success' => true,
            'transaction' => $transaction,
            'payment_url' => $paymentUrl,
            'message' => 'Redirection vers la boutique Chariow...',
        ];
    }

    public function checkChariowStatus($transactionId)
    {
        $transaction = Transaction::find($transactionId);
        if (!$transaction) return ['success' => false, 'message' => 'Transaction non trouvée.'];

        // NO auto-complete here — all deposits now require admin approval
        // after the user fills the confirmation form.

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
