<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\ChariowService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class WebhookController extends Controller
{
    protected $chariow;

    public function __construct(ChariowService $chariow)
    {
        $this->chariow = $chariow;
    }

    public function chariow(Request $request)
    {
        if ($request->isMethod('get')) {
            return response()->json(['status' => 'ok', 'message' => 'Chariow Pulse endpoint active']);
        }

        $rawBody = $request->getContent();
        $signature = $request->header('x-chariow-signature', '');

        Log::info('Chariow Pulse reçu.', [
            'ip' => $request->ip(),
            'event' => $request->header('x-pulse-event', 'unknown'),
            'delivery_id' => $request->header('x-pulse-delivery-id', 'unknown'),
        ]);

        if ($signature && !$this->chariow->verifySignature($rawBody, $signature)) {
            Log::warning('Chariow webhook rejeté : signature invalide.', ['ip' => $request->ip()]);
            return response()->json(['status' => 'error', 'message' => 'Invalid signature'], 401);
        }

        $payload = json_decode($rawBody, true);
        if (empty($payload)) {
            Log::error('Chariow webhook : payload invalide.');
            return response()->json(['status' => 'error', 'message' => 'Invalid payload'], 400);
        }

        try {
            $result = $this->chariow->handleWebhook($payload, $rawBody, $signature);
        } catch (\Exception $e) {
            Log::error('Chariow webhook exception: ' . $e->getMessage());
            return response()->json(['status' => 'error', 'message' => 'Internal error'], 500);
        }

        return response()->json($result);
    }

    public function fusionpay(Request $request)
    {
        if ($request->isMethod('get')) {
            return response()->json(['status' => 'ok', 'message' => 'FusionPay webhook endpoint active']);
        }

        $payload = $request->json()->all() ?: $request->all();
        Log::info('FusionPay webhook reçu.', ['ip' => $request->ip(), 'keys' => array_keys($payload)]);

        $token = $payload['tokenPay'] ?? $payload['token'] ?? null;
        $statut = strtolower((string) ($payload['statut'] ?? ''));

        // Retrouve la transaction par token, sinon via personal_Info[].transaction_id
        $transaction = null;
        if ($token) {
            $transaction = \App\Models\Transaction::where('type', 'deposit')
                ->where('metadata', 'like', '%' . $token . '%')
                ->first();
        }
        if (!$transaction && !empty($payload['personal_Info'])) {
            foreach ((array) $payload['personal_Info'] as $info) {
                if (!empty($info['transaction_id'])) {
                    $transaction = \App\Models\Transaction::where('type', 'deposit')
                        ->where('id', (int) $info['transaction_id'])
                        ->first();
                    if ($transaction) break;
                }
            }
        }

        if (!$transaction) {
            Log::warning('FusionPay webhook : transaction non trouvée.', ['token' => $token]);
            return response()->json(['status' => 'ok']);
        }

        try {
            if ($statut === 'paid') {
                // Vérifie que le montant payé correspond à la transaction.
                $montant = (float) ($payload['Montant'] ?? $payload['montant'] ?? 0);
                if ($montant > 0 && abs($montant - (float) $transaction->amount) > 1) {
                    Log::warning('FusionPay webhook : montant divergent.', [
                        'transaction_id' => $transaction->id,
                        'attendu' => $transaction->amount,
                        'recu' => $montant,
                    ]);
                }

                $completed = app(\App\Services\PaymentService::class)->completeDeposit($transaction, 'fusionpay_webhook');
                Log::info('FusionPay webhook traité.', ['transaction_id' => $transaction->id, 'completed' => $completed]);
            } elseif (in_array($statut, ['failed', 'no paid', 'no_paid', 'canceled', 'cancelled'])) {
                if ($transaction->status === 'pending') {
                    $transaction->update(['status' => 'failed']);
                }
                Log::info('FusionPay webhook : paiement échoué.', ['transaction_id' => $transaction->id]);
            }
        } catch (\Exception $e) {
            Log::error('FusionPay webhook exception: ' . $e->getMessage());
        }

        return response()->json(['status' => 'ok']);
    }
}
