<?php

namespace App\Services;

use App\Models\Transaction;
use App\Models\User;
use App\Models\Notification;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class PaymentService
{
    protected $fusionPay;

    public function __construct(FusionPayService $fusionPay)
    {
        $this->fusionPay = $fusionPay;
    }

    public function depositFusionPay($userId, $amount, $phoneNumber, $provider = 'orange')
    {
        $reference = 'DEP-' . Str::random(16);
        $transaction = Transaction::create([
            'user_id' => $userId,
            'type' => 'deposit',
            'amount' => $amount,
            'reference' => $reference,
            'payment_method' => $provider,
            'status' => 'pending',
            'description' => 'Dépôt via FusionPay (' . $provider . ')',
            'metadata' => json_encode(['phone' => $phoneNumber, 'provider' => $provider, 'initiated_at' => now()->toISOString()]),
        ]);

        try {
            $result = $this->fusionPay->initiatePayment($amount, $phoneNumber, $reference, 'Dépôt Together We Can - ' . $reference);
            if ($result['status'] === 'success') {
                $transaction->update(['metadata' => array_merge($transaction->metadata ?? [], ['fusionpay' => $result, 'transaction_id' => $result['transaction_id'] ?? null])]);
                return ['success' => true, 'transaction' => $transaction, 'payment_url' => $result['payment_url'] ?? null, 'message' => 'Demande de paiement envoyée.'];
            } else {
                $transaction->update(['status' => 'failed', 'metadata' => array_merge($transaction->metadata ?? [], ['error' => $result['message'] ?? 'Erreur inconnue'])]);
                return ['success' => false, 'message' => $result['message'] ?? 'Erreur lors du paiement.'];
            }
        } catch (\Exception $e) {
            $transaction->update(['status' => 'failed', 'metadata' => array_merge($transaction->metadata ?? [], ['error' => $e->getMessage()])]);
            return ['success' => false, 'message' => 'Erreur technique: ' . $e->getMessage()];
        }
    }

    public function depositOrangeMoney($userId, $amount, $phoneNumber) { return $this->depositFusionPay($userId, $amount, $phoneNumber, 'orange'); }
    public function depositMtnMoney($userId, $amount, $phoneNumber) { return $this->depositFusionPay($userId, $amount, $phoneNumber, 'mtn'); }

    public function checkFusionPayStatus($transactionId)
    {
        $transaction = Transaction::find($transactionId);
        if (!$transaction) return ['success' => false, 'message' => 'Transaction non trouvée.'];

        // Idempotence : si déjà complétée, on ne recrédite jamais une deuxième fois.
        if ($transaction->status === 'completed') {
            return ['success' => true, 'status' => 'completed', 'transaction' => $transaction];
        }

        $fusionpayId = $transaction->metadata['fusionpay']['transaction_id'] ?? null;
        if (!$fusionpayId) return ['success' => false, 'message' => 'ID FusionPay non trouvé.'];
        $result = $this->fusionPay->checkStatus($fusionpayId);
        if ($result['status'] === 'success') {
            $status = $result['data']['status'] ?? 'pending';
            $statusMap = ['completed' => 'completed', 'success' => 'completed', 'pending' => 'pending', 'processing' => 'pending', 'failed' => 'failed', 'cancelled' => 'failed'];
            $newStatus = $statusMap[$status] ?? 'pending';
            $transaction->update(['status' => $newStatus, 'completed_at' => in_array($newStatus, ['completed']) ? now() : null]);
            if ($newStatus === 'completed') {
                $user = User::find($transaction->user_id);
                if ($user) $user->increment('boost_balance', $transaction->amount);
            }
            return ['success' => true, 'status' => $newStatus, 'transaction' => $transaction];
        }
        return ['success' => false, 'message' => $result['message'] ?? 'Erreur lors de la vérification.'];
    }

    public function transfer($fromUserId, $toUserId, $amount, $description = null)
    {
        if ($fromUserId === $toUserId) throw new \Exception('Impossible de se transférer à soi-même.');
        $fromUser = User::find($fromUserId);
        $toUser = User::find($toUserId);
        if (!$fromUser || !$toUser) throw new \Exception('Utilisateur non trouvé.');
        if ($fromUser->boost_balance < $amount) throw new \Exception('Solde insuffisant.');

        DB::beginTransaction();
        try {
            $fromUser->decrement('boost_balance', $amount);
            $toUser->increment('boost_balance', $amount);
            $senderTransaction = Transaction::create(['user_id' => $fromUserId, 'type' => 'transfer_sent', 'amount' => $amount, 'reference' => 'TRF-' . Str::random(12), 'payment_method' => 'wallet', 'status' => 'completed', 'description' => $description ?? 'Transfert vers ' . $toUser->name, 'metadata' => json_encode(['to_user_id' => $toUserId, 'to_user_name' => $toUser->name]), 'completed_at' => now()]);
            $receiverTransaction = Transaction::create(['user_id' => $toUserId, 'type' => 'transfer_received', 'amount' => $amount, 'reference' => 'TRF-' . Str::random(12), 'payment_method' => 'wallet', 'status' => 'completed', 'description' => $description ?? 'Reçu de ' . $fromUser->name, 'metadata' => json_encode(['from_user_id' => $fromUserId, 'from_user_name' => $fromUser->name]), 'completed_at' => now()]);
            $this->createNotification($fromUserId, 'transfer_sent', 'Vous avez envoyé ' . number_format($amount, 0) . ' FCFA à ' . $toUser->name, ['transaction_id' => $senderTransaction->id]);
            $this->createNotification($toUserId, 'transfer_received', 'Vous avez reçu ' . number_format($amount, 0) . ' FCFA de ' . $fromUser->name, ['transaction_id' => $receiverTransaction->id]);
            DB::commit();
            return ['sender_transaction' => $senderTransaction, 'receiver_transaction' => $receiverTransaction];
        } catch (\Exception $e) { DB::rollBack(); throw $e; }
    }

    public function withdraw($userId, $amount, $phoneNumber, $method = 'orange_money')
    {
        $user = User::find($userId);
        if (!$user) throw new \Exception('User not found.');
        if ($user->boost_balance < $amount) throw new \Exception('Insufficient balance.');
        $reference = 'WD-' . Str::random(12);
        DB::beginTransaction();
        try {
            $user->decrement('boost_balance', $amount);
            $transaction = Transaction::create(['user_id' => $userId, 'type' => 'withdrawal', 'amount' => $amount, 'reference' => $reference, 'payment_method' => $method, 'status' => 'pending', 'description' => 'Retrait via ' . ($method === 'orange_money' ? 'Orange Money' : 'MTN Mobile Money'), 'metadata' => json_encode(['phone' => $phoneNumber, 'method' => $method])]);
            DB::commit();
            return $transaction;
        } catch (\Exception $e) { DB::rollBack(); throw $e; }
    }

    private function createNotification($userId, $type, $message, $data = [])
    {
        Notification::create(['user_id' => $userId, 'type' => $type, 'message' => $message, 'data' => json_encode($data), 'has_sound' => true, 'is_read' => false]);
    }
}
