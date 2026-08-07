<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FusionPayService
{
    protected $apiUrl;
    protected $apiKey;
    protected $callbackUrl;
    protected $currency;

    public function __construct()
    {
        $this->apiUrl = config('fusionpay.api_url');
        $this->apiKey = config('fusionpay.api_key');
        $this->callbackUrl = config('fusionpay.callback_url');
        $this->currency = config('fusionpay.currency', 'XOF');
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
