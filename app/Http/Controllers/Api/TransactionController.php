<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use App\Models\User;
use App\Services\PaymentService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class TransactionController extends Controller
{
    use \App\Traits\ApiResponseTrait;

    protected $paymentService;

    public function __construct(PaymentService $paymentService)
    {
        $this->paymentService = $paymentService;
    }

    public function balance()
    {
        $user = auth()->user();

        return $this->successResponse([
            'boost_balance' => $user->boost_balance,
            'savings_balance' => $user->savings_balance,
        ]);
    }

    public function history(Request $request)
    {
        $query = Transaction::forUser(auth()->id());

        if ($request->filled('type')) {
            $query->where('type', $request->type);
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        $limit = $request->input('limit', 20);
        $page = $request->input('page', 1);
        $offset = ($page - 1) * $limit;

        $total = (clone $query)->count();
        $transactions = $query->orderBy('created_at', 'desc')
            ->skip($offset)
            ->take($limit)
            ->get();

        return $this->successResponse([
            'transactions' => $transactions,
            'has_more' => ($offset + $transactions->count()) < $total,
            'total' => $total,
            'page' => $page,
        ]);
    }

    public function summary()
    {
        $userId = auth()->id();

        return $this->successResponse([
            'total_deposits' => Transaction::forUser($userId)->where('type', 'deposit')->completed()->sum('amount'),
            'total_withdrawals' => Transaction::forUser($userId)->where('type', 'withdrawal')->completed()->sum('amount'),
            'total_spent' => Transaction::forUser($userId)->whereIn('type', ['boost_payment', 'marketplace_payment', 'course_payment'])->completed()->sum('amount'),
        ]);
    }

    public function show($id)
    {
        $transaction = Transaction::forUser(auth()->id())->find($id);

        if (!$transaction) {
            return $this->errorResponse('Transaction not found.', 404);
        }

        return $this->successResponse(['transaction' => $transaction]);
    }

    public function deposit(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'amount' => 'required|numeric|min:500',
            'phone' => 'required|string',
            'provider' => 'required|in:orange,mtn,vodacom,airtel,africell',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $result = $this->paymentService->depositFusionPay(auth()->id(), $request->amount, $request->phone, $request->provider);

        if (!$result['success']) {
            return $this->errorResponse($result['message'], 400);
        }

        return $this->successResponse($result);
    }

    public function withdraw(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'amount' => 'required|numeric|min:1000',
            'phone' => 'required|string',
            'provider' => 'required|in:orange,mtn,vodacom,airtel,africell',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        try {
            $transaction = $this->paymentService->withdraw(auth()->id(), $request->amount, $request->phone, $request->provider);

            return $this->successResponse([
                'message' => 'Withdrawal request submitted.',
                'transaction' => $transaction,
            ]);
        } catch (\Exception $e) {
            return $this->errorResponse($e->getMessage(), 400);
        }
    }

    public function transfer(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'to_user_id' => 'required|integer|exists:users,id',
            'amount' => 'required|numeric|min:100',
            'description' => 'nullable|string|max:255',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        try {
            $result = $this->paymentService->transfer(auth()->id(), $request->to_user_id, $request->amount, $request->description);

            return $this->successResponse([
                'message' => 'Transfer completed successfully.',
                'data' => $result,
            ]);
        } catch (\Exception $e) {
            return $this->errorResponse($e->getMessage(), 400);
        }
    }
}
