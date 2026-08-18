<?php

namespace App\Services;

use App\Models\Transaction;
use App\Models\User;
use App\Models\Notification;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class ChariowService
{
    /**
     * Vérifie la signature HMAC-SHA256 d'un Pulse Chariow.
     */
    public function verifySignature(string $rawBody, string $signature): bool
    {
        $secret = config('chariow.pulse_secret');
        if (!$secret) {
            Log::warning('Chariow: pulse_secret non configuré, signature non vérifiée.');
            return true;
        }

        $expected = 'sha256=' . hash_hmac('sha256', $rawBody, $secret);
        return hash_equals($expected, $signature);
    }

    /**
     * Traite un Pulse Chariow (webhook).
     */
    public function handleWebhook(array $payload, string $rawBody = '', string $signature = '')
    {
        $event = $payload['event'] ?? null;

        if (!$event) {
            Log::warning('Chariow webhook: event manquant.', ['payload' => array_keys($payload)]);
            return ['status' => 'ignored', 'message' => 'No event'];
        }

        switch ($event) {
            case 'successful.sale':
                return $this->handleSuccessfulSale($payload);

            case 'abandoned.sale':
                Log::info('Chariow: vente abandonnée.', ['payload' => $payload]);
                return ['status' => 'ignored', 'message' => 'Abandoned sale'];

            case 'failed.sale':
                Log::info('Chariow: vente échouée.', ['payload' => $payload]);
                return ['status' => 'ignored', 'message' => 'Failed sale'];

            default:
                Log::info('Chariow: event non géré.', ['event' => $event]);
                return ['status' => 'ignored', 'message' => 'Unhandled event: ' . $event];
        }
    }

    /**
     * Traite une vente réussie (successful.sale).
     */
    private function handleSuccessfulSale(array $payload): array
    {
        $sale = $payload['sale'] ?? [];
        $customer = $payload['customer'] ?? [];
        $product = $payload['product'] ?? [];

        $email = $customer['email'] ?? null;
        $amount = $sale['amount']['value'] ?? null;
        $saleId = $sale['id'] ?? null;
        $status = $sale['status'] ?? null;
        $metadata = $sale['custom_metadata'] ?? [];

        if (!$email || !$amount) {
            Log::error('Chariow webhook: email ou montant manquant.', [
                'email' => $email,
                'amount' => $amount,
            ]);
            return ['status' => 'error', 'message' => 'Missing email or amount'];
        }

        $user = User::where('email', $email)->first();
        if (!$user) {
            Log::error('Chariow webhook: utilisateur introuvable.', ['email' => $email]);
            return ['status' => 'error', 'message' => 'User not found for email: ' . $email];
        }

        $reference = $metadata['reference'] ?? $saleId ?? ('CHR-' . Str::random(12));

        return DB::transaction(function () use ($user, $amount, $saleId, $reference, $metadata, $payload) {
            $existing = Transaction::where('reference', $reference)->lockForUpdate()->first();

            if ($existing && $existing->status === 'completed') {
                Log::info('Chariow webhook: transaction déjà traitée (idempotent).', ['reference' => $reference]);
                return ['status' => 'already_processed'];
            }

            if ($existing) {
                $existing->update([
                    'status' => 'completed',
                    'completed_at' => now(),
                    'metadata' => array_merge($existing->metadata ?? [], [
                        'chariow_payload' => $payload,
                        'chariow_sale_id' => $saleId,
                        'pulse_processed_at' => now()->toDateTimeString(),
                    ]),
                ]);
                $transaction = $existing;
            } else {
                $transaction = Transaction::create([
                    'user_id' => $user->id,
                    'type' => 'deposit',
                    'amount' => $amount,
                    'reference' => $reference,
                    'payment_method' => 'chariow',
                    'status' => 'completed',
                    'description' => 'Dépôt via Chariow confirmé par webhook',
                    'metadata' => json_encode([
                        'chariow_payload' => $payload,
                        'chariow_sale_id' => $saleId,
                        'pulse_processed_at' => now()->toDateTimeString(),
                    ]),
                    'completed_at' => now(),
                ]);
            }

            $previousBalance = (float) ($user->boost_balance ?? 0);
            $user->increment('boost_balance', $amount);
            $newBalance = (float) $user->fresh()->boost_balance;

            Log::info('Chariow: solde crédité.', [
                'user_id' => $user->id,
                'amount' => $amount,
                'previous_balance' => $previousBalance,
                'new_balance' => $newBalance,
                'sale_id' => $saleId,
                'reference' => $reference,
            ]);

            Notification::create([
                'user_id' => $user->id,
                'type' => 'payment',
                'message' => 'Votre paiement de ' . number_format($amount, 0) . ' CDF a été confirmé via Chariow.',
                'data' => json_encode([
                    'transaction_id' => $transaction->id,
                    'sale_id' => $saleId,
                ]),
                'has_sound' => true,
            ]);

            return ['status' => 'success'];
        });
    }
}
