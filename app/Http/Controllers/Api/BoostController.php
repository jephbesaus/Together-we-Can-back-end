<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BoostOrder;
use App\Models\Transaction;
use App\Services\FullSMMService;
use App\Services\PaymentService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class BoostController extends Controller
{
    use \App\Traits\ApiResponseTrait;

    protected $fullSMM;
    protected $paymentService;

    public function __construct(FullSMMService $fullSMM, PaymentService $paymentService)
    {
        $this->fullSMM = $fullSMM;
        $this->paymentService = $paymentService;
    }

    public function platforms()
    {
        try {
            $platforms = $this->fullSMM->getPlatforms();
            $meta = config('fullsmm.platforms', []);

            $items = collect($platforms)->map(function ($platform) use ($meta) {
                $name = is_array($platform) ? ($platform['name'] ?? '') : $platform;
                $conf = $meta[$name] ?? [];
                return [
                    'id' => strtolower($name),
                    'name' => $name,
                    'icon' => $conf['icon'] ?? null,
                    'color' => $conf['color'] ?? '#00A86B',
                ];
            })->values();

            return $this->successResponse(['platforms' => $items]);
        } catch (\Exception $e) {
            return $this->successResponse(['platforms' => collect(array_keys(config('fullsmm.platforms', [])))->map(fn($name) => [
                'id' => strtolower($name),
                'name' => $name,
                'icon' => strtolower($name),
                'color' => '#00A86B',
            ])->values()]);
        }
    }

    public function services($platform)
    {
        try {
            $services = $this->fullSMM->getPlatformServices($platform);
            $usdToCdf = (float) config('fullsmm.usd_to_cdf', 3300);

            // Convertit le tarif FullSMM (USD / 1000) en CDF / 1000.
            $services = array_map(function ($service) use ($usdToCdf) {
                $service['price_per_1000'] = round((float) ($service['rate'] ?? 0) * $usdToCdf, 2);
                return $service;
            }, is_array($services) ? $services : []);

            return $this->successResponse(['services' => array_values($services)]);
        } catch (\Exception $e) {
            return $this->successResponse(['services' => []]);
        }
    }

    public function balance()
    {
        try {
            $user = auth()->user();
            $user->refresh();
            return $this->successResponse(['boost_balance' => (float) ($user->boost_balance ?? 0)]);
        } catch (\Exception $e) {
            Log::error('Boost balance error: ' . $e->getMessage());
            return $this->successResponse(['boost_balance' => 0]);
        }
    }

    public function placeOrder(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'platform' => 'required|string',
            'service_id' => 'required',
            'link' => 'required|string|max:500',
            'quantity' => 'required|integer|min:1',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $service = $this->fullSMM->getService($request->service_id);

        if (!$service) {
            Log::warning('Boost order: service not found', ['service_id' => $request->service_id]);
            return $this->errorResponse('Service not found.', 404);
        }

        $pricePerUnit = $service['rate'] ?? 0;
        // Le tarif FullSMM est en USD / 1000 : on facture en CDF.
        $totalPrice = round(($pricePerUnit * $request->quantity / 1000) * (float) config('fullsmm.usd_to_cdf', 3300), 2);

        $user = auth()->user();
        $user->refresh();
        $balance = (float) ($user->boost_balance ?? 0);

        Log::info('Boost order attempt', [
            'user_id' => $user->id,
            'boost_balance' => $balance,
            'total_price' => $totalPrice,
            'service_id' => $request->service_id,
            'quantity' => $request->quantity,
            'rate' => $pricePerUnit,
        ]);

        if ($balance < $totalPrice) {
            Log::warning('Boost order: insufficient balance', [
                'user_id' => $user->id,
                'balance' => $balance,
                'total_price' => $totalPrice,
            ]);
            return $this->errorResponse('Solde insuffisant.', 400);
        }

        $result = $this->fullSMM->placeOrder($request->service_id, $request->link, $request->quantity);

        Log::info('FullSMM order result', [
            'user_id' => $user->id,
            'service_id' => $request->service_id,
            'result' => $result,
        ]);

        if (!$result) {
            return $this->errorResponse('Échec de la commande auprès du fournisseur.', 502);
        }

        $user->decrement('boost_balance', $totalPrice);

        $boostOrder = BoostOrder::create([
            'user_id' => $user->id,
            'platform' => $request->platform,
            'service_id' => $request->service_id,
            'service_name' => $service['name'] ?? null,
            'service_category' => $service['category'] ?? null,
            'link' => $request->link,
            'quantity' => $request->quantity,
            'price' => $totalPrice,
            'price_per_unit' => $pricePerUnit,
            'fullsmm_order_id' => $result['order'] ?? null,
            'status' => 'pending',
            'started_at' => now(),
        ]);

        Transaction::create([
            'user_id' => $user->id,
            'type' => 'boost_payment',
            'amount' => $totalPrice,
            'reference' => 'BST-' . strtoupper(uniqid()),
            'payment_method' => 'wallet',
            'status' => 'completed',
            'description' => 'Boost ' . $request->platform,
            'completed_at' => now(),
        ]);

        Log::info('Boost order placed successfully', [
            'user_id' => $user->id,
            'order_id' => $boostOrder->id,
            'price' => $totalPrice,
            'remaining_balance' => $user->fresh()->boost_balance,
        ]);

        return $this->successResponse([
            'message' => 'Commande passée avec succès.',
            'order' => $boostOrder,
        ], 201);
    }

    public function orders(Request $request)
    {
        $limit = $request->input('limit', 20);
        $page = $request->input('page', 1);
        $offset = ($page - 1) * $limit;

        $baseQuery = BoostOrder::forUser(auth()->id());
        $total = (clone $baseQuery)->count();

        $orders = $baseQuery
            ->orderBy('created_at', 'desc')
            ->skip($offset)
            ->take($limit)
            ->get();

        return $this->successResponse([
            'orders' => $orders,
            'has_more' => ($offset + $orders->count()) < $total,
            'total' => $total,
            'page' => $page,
        ]);
    }

    public function orderStatus($id)
    {
        $order = BoostOrder::forUser(auth()->id())->find($id);

        if (!$order) {
            return $this->errorResponse('Order not found.', 404);
        }

        if ($order->fullsmm_order_id) {
            $status = $this->fullSMM->getOrderStatus($order->fullsmm_order_id);
            if ($status) {
                $statusMap = ['Pending' => 'pending', 'In progress' => 'processing', 'Completed' => 'completed', 'Partial' => 'partial', 'Canceled' => 'cancelled'];
                $newStatus = $statusMap[$status['status'] ?? ''] ?? $order->status;
                $order->update([
                    'status' => $newStatus,
                    'remaining' => $status['remains'] ?? $order->remaining,
                    'completed_at' => $newStatus === 'completed' ? now() : $order->completed_at,
                ]);
            }
        }

        return $this->successResponse(['order' => $order->fresh()]);
    }

    public function deposit(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'amount' => 'required|numeric|min:500',
            'email' => 'required|email',
            'provider' => 'required|in:orange,mtn,vodacom,airtel,africell,mpesa',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $result = $this->paymentService->depositChariow(
            auth()->id(),
            $request->amount,
            $request->email,
            $request->provider
        );

        if (!$result['success']) {
            return $this->errorResponse($result['message'], 400);
        }

        return $this->successResponse($result);
    }

    public function history()
    {
        $orders = BoostOrder::forUser(auth()->id())
            ->orderBy('created_at', 'desc')
            ->limit(50)
            ->get();

        return $this->successResponse(['history' => $orders]);
    }
}
