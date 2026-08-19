<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use App\Models\User;
use App\Services\PaymentService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

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

        // NEVER auto-complete deposits here — only checkChariowStatus() or admin can complete.
        // Auto-completing here was causing false balances.

        $user->refresh();

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
            return $this->errorResponse('Transaction non trouvée.', 404);
        }

        return $this->successResponse(['transaction' => $transaction]);
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

    public function checkDepositStatus($transactionId)
    {
        $transaction = Transaction::forUser(auth()->id())->find($transactionId);

        if (!$transaction) {
            return $this->errorResponse('Transaction non trouvée.', 404);
        }

        if ($transaction->status !== 'pending') {
            return $this->successResponse(['status' => $transaction->status, 'transaction' => $transaction]);
        }

        $result = $this->paymentService->checkChariowStatus($transactionId);

        if (!$result['success']) {
            return $this->errorResponse($result['message'] ?? 'Vérification impossible pour le moment.', 400);
        }

        return $this->successResponse(['status' => $result['status'], 'transaction' => $result['transaction']]);
    }

    public function withdraw(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'amount' => 'required|numeric|min:1000',
            'phone' => 'required|string',
            'provider' => 'required|in:orange,mtn,vodacom,airtel,africell,mpesa',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        try {
            $transaction = $this->paymentService->withdrawChariow(
                auth()->id(),
                $request->amount,
                $request->phone,
                $request->provider
            );

            return $this->successResponse([
                'message' => 'Demande de retrait soumise.',
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
                'message' => 'Transfert effectué avec succès.',
                'data' => $result,
            ]);
        } catch (\Exception $e) {
            return $this->errorResponse($e->getMessage(), 400);
        }
    }

    public function manualDeposit(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'amount' => 'required|numeric|min:500',
            'reference' => 'required|string|max:255',
            'provider' => 'required|in:orange,mtn,vodacom,airtel,africell,mpesa',
            'last_name' => 'nullable|string|max:100',
            'first_name' => 'nullable|string|max:100',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $reference = 'MAN-DEP-' . Str::random(16);

        $transaction = Transaction::create([
            'user_id' => auth()->id(),
            'type' => 'deposit',
            'amount' => $request->amount,
            'reference' => $reference,
            'payment_method' => 'manual_' . $request->provider,
            'status' => 'pending',
            'description' => 'Dépôt manuel via ' . $request->provider,
            'metadata' => json_encode([
                'manual' => true,
                'chariow_reference' => $request->reference,
                'provider' => $request->provider,
                'last_name' => $request->last_name,
                'first_name' => $request->first_name,
                'submitted_at' => now()->toISOString(),
            ]),
        ]);

        return $this->successResponse([
            'message' => 'Demande de dépôt soumise. En attente de vérification par l\'administrateur.',
            'transaction' => $transaction,
        ]);
    }

    public function confirmDeposit(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'last_name' => 'required|string|max:100',
            'first_name' => 'required|string|max:100',
            'chariow_reference' => 'required|string|max:255',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $transaction = Transaction::where('user_id', auth()->id())
            ->where('id', $id)
            ->where('type', 'deposit')
            ->where('status', 'pending')
            ->first();

        if (!$transaction) {
            return $this->errorResponse('Transaction non trouvée ou déjà traitée.', 404);
        }

        $transaction->update([
            'metadata' => array_merge($transaction->metadata ?? [], [
                'manual' => true,
                'last_name' => $request->last_name,
                'first_name' => $request->first_name,
                'chariow_reference' => $request->chariow_reference,
                'confirmed_at' => now()->toISOString(),
            ]),
        ]);

        return $this->successResponse([
            'message' => 'Informations enregistrées. En attente de vérification par l\'administrateur.',
            'transaction' => $transaction->fresh(),
        ]);
    }
}
