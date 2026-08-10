<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Http\Request;

class FusionPayService
{
    protected $apiUrl;
    protected $apiKey;
    protected $callbackUrl;
    protected $currency;
    protected $webhookSecret;

    public function __construct()
    {
        $this->apiUrl = config('fusionpay.api_url');
        $this->apiKey = config('fusionpay.api_key');
        $this->callbackUrl = config('fusionpay.callback_url');
        $this->currency = config('fusionpay.currency', 'XOF');
        $this->webhookSecret = config('fusionpay.webhook_secret');
    }

    private function request($endpoint, $data = [], $method = 'POST')
    {
        $url = $this->apiUrl . '/' . ltrim($endpoint, '/');
        try {
            $response = Http::timeout(30)->withHeaders(['Authorization' => 'Bearer ' . $this->apiKey, 'Content-Type' => 'application/json', 'Accept' => 'application/json']);
            if ($method === 'POST') $response = $response->post($url, $data);
            elseif ($method === 'GET') $response = $response->get($url, $data);
            $result = $response->json();
            Log::info('FusionPay Request', ['endpoint' => $endpoint, 'method' => $method, 'data' => $data, 'response' => $result]);
            return $result;
        } catch (\Exception $e) { Log::error('FusionPay Error: ' . $e->getMessage()); return ['status' => 'error', 'message' => $e->getMessage()]; }
    }

    public function initiatePayment($amount, $phoneNumber, $reference, $description)
    {
        return $this->request('payment/initiate', ['amount' => (float) $amount, 'phone' => $phoneNumber, 'reference' => $reference, 'description' => $description, 'currency' => $this->currency, 'callback_url' => $this->callbackUrl, 'metadata' => ['source' => 'together_we_can', 'type' => 'payment']]);
    }

    public function checkStatus($transactionId) { return $this->request('payment/status/' . $transactionId, [], 'GET'); }
    public function cancelPayment($transactionId) { return $this->request('payment/cancel/' . $transactionId, [], 'POST'); }
    public function refundPayment($transactionId, $amount = null) { $data = []; if ($amount) $data['amount'] = (float) $amount; return $this->request('payment/refund/' . $transactionId, $data); }
    public function getBalance() { return $this->request('balance', [], 'GET'); }
    public function getTransactions($limit = 50, $page = 1) { return $this->request('transactions', ['limit' => $limit, 'page' => $page], 'GET'); }

    /**
     * Vérifie que la requête webhook provient bien de FusionPay et non d'un tiers
     * malveillant qui essaierait de simuler un paiement réussi pour se créditer
     * gratuitement. Le principe : FusionPay doit signer chaque appel avec une clé
     * secrète (partagée via leur dashboard), qu'on compare ici en HMAC-SHA256.
     *
     * ⚠️ IMPORTANT : le nom exact du header et l'algorithme dépendent de la doc
     * FusionPay. Ce code utilise un schéma standard (header X-Fusionpay-Signature,
     * HMAC-SHA256 du corps brut de la requête) — à ajuster une fois que FusionPay
     * vous communique leur méthode exacte de signature.
     */
    public function verifySignature(Request $request): bool
    {
        if (empty($this->webhookSecret)) {
            // Aucun secret configuré : on ne peut pas vérifier. On log un avertissement
            // clair plutôt que d'accepter silencieusement n'importe quelle requête.
            Log::warning('FusionPay webhook reçu sans FUSIONPAY_WEBHOOK_SECRET configuré — signature non vérifiée, requête acceptée par défaut.');
            return true;
        }

        $signatureHeader = $request->header('X-Fusionpay-Signature');
        if (!$signatureHeader) {
            Log::warning('FusionPay webhook rejeté : en-tête de signature manquant.');
            return false;
        }

        $expected = hash_hmac('sha256', $request->getContent(), $this->webhookSecret);

        return hash_equals($expected, $signatureHeader);
    }

    public function handleWebhook($payload)
    {
        Log::info('FusionPay Webhook Received', ['payload' => $payload]);
        $transactionId = $payload['transaction_id'] ?? null;
        $status = $payload['status'] ?? null;
        if (!$transactionId || !$status) return ['status' => 'error', 'message' => 'Missing data'];
        $this->updateTransactionStatus($transactionId, $status, $payload);
        return ['status' => 'success'];
    }

    private function updateTransactionStatus($transactionId, $status, $payload)
    {
        $transaction = \App\Models\Transaction::where('reference', $transactionId)->orWhere('id', $transactionId)->first();
        if (!$transaction) { Log::error('Transaction not found for webhook: ' . $transactionId); return; }

        // Idempotence : si la transaction est déjà marquée "completed", on ne
        // recrédite JAMAIS le solde une deuxième fois, même si FusionPay renvoie
        // le webhook plusieurs fois (ce qui arrive en pratique, par sécurité de
        // leur côté en cas de non-réponse de notre serveur).
        if ($transaction->status === 'completed') {
            Log::info('Webhook ignoré : transaction déjà complétée.', ['transaction_id' => $transactionId]);
            return;
        }

        $statusMap = ['pending' => 'pending', 'processing' => 'pending', 'completed' => 'completed', 'success' => 'completed', 'failed' => 'failed', 'cancelled' => 'failed', 'refunded' => 'refunded'];
        $newStatus = $statusMap[$status] ?? 'pending';
        $transaction->update(['status' => $newStatus, 'metadata' => array_merge($transaction->metadata ?? [], ['fusionpay' => $payload, 'updated_at' => now()->toISOString()]), 'completed_at' => in_array($newStatus, ['completed', 'failed']) ? now() : null]);
        if ($newStatus === 'completed') {
            $user = \App\Models\User::find($transaction->user_id);
            if ($user) { $user->increment('boost_balance', $transaction->amount); $this->createNotification($user->id, 'payment', 'Votre paiement de ' . number_format($transaction->amount, 0) . ' FCFA a été confirmé.', ['transaction_id' => $transaction->id]); }
        }
        Log::info('Transaction updated via webhook', ['transaction_id' => $transactionId, 'status' => $newStatus]);
    }

    private function createNotification($userId, $type, $message, $data = []) { \App\Models\Notification::create(['user_id' => $userId, 'type' => $type, 'message' => $message, 'data' => json_encode($data), 'has_sound' => true, 'is_read' => false]); }
}
