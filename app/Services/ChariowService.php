<?php

namespace App\Services;

use App\Models\Transaction;
use App\Models\User;
use App\Models\Notification;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class ChariowService
{
    /**
     * Traite la notification de paiement envoyée par Chariow.
     *
     * ⚠️ Le format exact du payload envoyé par Chariow n'a pas encore été
     * confirmé avec un vrai exemple. Ce code essaie plusieurs noms de champs
     * probables (email, montant, statut) pour rester tolérant. Dès qu'un vrai
     * webhook aura été reçu (voir les logs Laravel), ajuster les clés ci-dessous
     * pour qu'elles correspondent exactement à leur format.
     */
    public function handleWebhook(array $payload)
    {
        Log::info('Chariow Webhook Received', ['payload' => $payload]);

        $status = $payload['status']
            ?? $payload['event']
            ?? $payload['data']['status']
            ?? null;

        $isSuccess = in_array(strtolower((string) $status), ['success', 'completed', 'sale.completed', 'paid', 'succeeded']);

        if (!$isSuccess) {
            Log::info('Chariow webhook ignoré (statut non confirmé).', ['status' => $status]);
            return ['status' => 'ignored'];
        }

        $email = $payload['customer']['email']
            ?? $payload['email']
            ?? $payload['data']['customer']['email']
            ?? null;

        $amount = $payload['amount']
            ?? $payload['total']
            ?? $payload['data']['amount']
            ?? null;

        $reference = $payload['transaction_id']
            ?? $payload['id']
            ?? $payload['data']['id']
            ?? Str::random(12);

        if (!$email || !$amount) {
            Log::error('Chariow webhook: email ou montant manquant, impossible de créditer.', ['payload' => $payload]);
            return ['status' => 'error', 'message' => 'Missing email or amount'];
        }

        $user = User::where('email', $email)->first();

        if (!$user) {
            Log::error('Chariow webhook: utilisateur introuvable pour cet email.', ['email' => $email]);
            return ['status' => 'error', 'message' => 'User not found'];
        }

        // Idempotence : si une transaction avec cette référence existe déjà
        // et est complétée, on ne crédite jamais deux fois.
        $existing = Transaction::where('reference', 'CHR-' . $reference)->first();
        if ($existing && $existing->status === 'completed') {
            Log::info('Chariow webhook ignoré : transaction déjà traitée.', ['reference' => $reference]);
            return ['status' => 'already_processed'];
        }

        $transaction = $existing ?? Transaction::create([
            'user_id' => $user->id,
            'type' => 'deposit',
            'amount' => $amount,
            'reference' => 'CHR-' . $reference,
            'payment_method' => 'chariow',
            'status' => 'pending',
            'description' => 'Dépôt via Chariow',
            'metadata' => json_encode(['chariow' => $payload]),
        ]);

        $transaction->update([
            'status' => 'completed',
            'completed_at' => now(),
            'metadata' => json_encode(['chariow' => $payload]),
        ]);

        $user->increment('boost_balance', $amount);

        Notification::create([
            'user_id' => $user->id,
            'type' => 'payment',
            'message' => 'Votre paiement de ' . number_format($amount, 0) . ' CDF a été confirmé.',
            'data' => json_encode(['transaction_id' => $transaction->id]),
            'has_sound' => true,
        ]);

        Log::info('Chariow: solde crédité avec succès.', ['user_id' => $user->id, 'amount' => $amount]);

        return ['status' => 'success'];
    }
}
