<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BoostOrder;
use App\Models\Transaction;
use App\Services\FullSMMService;
use App\Services\PaymentService;
use Illuminate\Http\Request;
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
    }

    public function services($platform)
    {
        $services = $this->fullSMM->getPlatformServices($platform);

        return $this->successResponse(['services' => array_values($services)]);
    }

    public function balance()
    {
        return $this->successResponse(['boost_balance' => auth()->user()->boost_balance]);
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
            return $this->errorResponse('Service not found.', 404);
        }

        $pricePerUnit = $service['rate'] ?? 0;
        $totalPrice = ($pricePerUnit * $request->quantity) / 1000;

        $user = auth()->user();

        if ($user->boost_balance < $totalPrice) {
            return $this->errorResponse('Insufficient balance.', 400);
        }

        $result = $this->fullSMM->placeOrder($request->service_id, $request->link, $request->quantity);

        if (!$result) {
            return $this->errorResponse('Failed to place order with provider.', 502);
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

        return $this->successResponse([
            'message' => 'Order placed successfully.',
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
            'provider' => 'required|in:orange,mtn,vodacom,airtel,africell',
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
