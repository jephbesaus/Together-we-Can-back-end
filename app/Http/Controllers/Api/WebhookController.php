<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\FusionPayService;
use App\Services\ChariowService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class WebhookController extends Controller
{
    protected $fusionPay;
    protected $chariow;

    public function __construct(FusionPayService $fusionPay, ChariowService $chariow)
    {
        $this->fusionPay = $fusionPay;
        $this->chariow = $chariow;
    }

    public function fusionPay(Request $request)
    {
        if (!$this->fusionPay->verifySignature($request)) {
            Log::warning('Webhook FusionPay rejeté : signature invalide.', ['ip' => $request->ip()]);
            return response()->json(['status' => 'error', 'message' => 'Invalid signature'], 403);
        }

        $result = $this->fusionPay->handleWebhook($request->all());

        return response()->json($result);
    }

    public function chariow(Request $request)
    {
        Log::info('Chariow webhook reçu.', [
            'ip' => $request->ip(),
            'method' => $request->method(),
            'headers' => $request->headers->all(),
        ]);

        $payload = $request->all();

        if (empty($payload)) {
            Log::error('Chariow webhook : payload vide.');
            return response()->json(['status' => 'error', 'message' => 'Empty payload'], 400);
        }

        $secret = config('chariow.webhook_secret');
        if ($secret) {
            $signature = $request->header('X-Chariow-Signature') ?? $request->header('X-Signature');
            if ($signature) {
                $expected = hash_hmac('sha256', json_encode($payload), $secret);
                if (!hash_equals($expected, $signature)) {
                    Log::warning('Webhook Chariow rejeté : signature invalide.', ['ip' => $request->ip()]);
                    return response()->json(['status' => 'error', 'message' => 'Invalid signature'], 403);
                }
            }
        }

        try {
            $result = $this->chariow->handleWebhook($payload);
        } catch (\Exception $e) {
            Log::error('Chariow webhook exception : ' . $e->getMessage(), ['payload' => $payload]);
            return response()->json(['status' => 'error', 'message' => 'Internal error'], 500);
        }

        return response()->json($result);
    }
}
