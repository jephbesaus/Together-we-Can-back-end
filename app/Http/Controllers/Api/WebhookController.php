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
}
