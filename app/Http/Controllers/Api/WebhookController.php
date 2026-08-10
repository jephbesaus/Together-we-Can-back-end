<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\FusionPayService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class WebhookController extends Controller
{
    protected $fusionPay;

    public function __construct(FusionPayService $fusionPay)
    {
        $this->fusionPay = $fusionPay;
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
}
