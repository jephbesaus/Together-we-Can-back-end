<?php

namespace App\Console\Commands;

use App\Models\BoostOrder;
use App\Models\Notification;
use App\Models\User;
use App\Services\FullSMMService;
use Illuminate\Console\Command;

class SyncBoostOrders extends Command
{
    protected $signature = 'boost:sync-orders';
    protected $description = 'Synchronise automatiquement le statut des commandes Boost avec FullSMM';

    protected $fullSMM;

    public function __construct(FullSMMService $fullSMM)
    {
        parent::__construct();
        $this->fullSMM = $fullSMM;
    }

    public function handle()
    {
        $statusMap = [
            'Pending' => 'pending',
            'In progress' => 'processing',
            'Processing' => 'processing',
            'Completed' => 'completed',
            'Partial' => 'partial',
            'Canceled' => 'cancelled',
            'Cancelled' => 'cancelled',
            'Refunded' => 'cancelled',
        ];

        $terminalStatuses = ['completed', 'cancelled', 'failed'];

        $pendingOrders = BoostOrder::whereIn('status', ['pending', 'processing', 'partial'])
            ->whereNotNull('fullsmm_order_id')
            ->where('started_at', '>', now()->subHours(48))
            ->get();

        $updated = 0;

        foreach ($pendingOrders as $order) {
            $status = $this->fullSMM->getOrderStatus($order->fullsmm_order_id);

            if (!$status || !isset($status['status'])) continue;

            $newStatus = $statusMap[$status['status']] ?? $order->status;

            if ($newStatus === $order->status) continue;

            $updateData = [
                'status' => $newStatus,
                'remaining' => $status['remains'] ?? $order->remaining,
            ];

            if ($newStatus === 'completed') {
                $updateData['completed_at'] = now();
            }

            $order->update($updateData);
            $updated++;

            if ($newStatus === 'completed') {
                Notification::create([
                    'user_id' => $order->user_id,
                    'type' => 'boost_completed',
                    'title' => 'Boost terminé',
                    'message' => "Votre commande Boost pour {$order->platform} est terminée.",
                    'data' => json_encode(['order_id' => $order->id]),
                    'has_sound' => true,
                ]);
            }

            if (in_array($newStatus, ['cancelled', 'failed'])) {
                $user = User::find($order->user_id);
                if ($user) {
                    $user->increment('boost_balance', $order->price);

                    Notification::create([
                        'user_id' => $order->user_id,
                        'type' => 'boost_failed',
                        'title' => 'Boost échoué',
                        'message' => "Votre commande Boost pour {$order->platform} a échoué. {$order->price} CDF ont été remboursés.",
                        'data' => json_encode(['order_id' => $order->id, 'refunded' => true]),
                        'has_sound' => true,
                    ]);
                }
            }
        }

        $this->info("Sync terminée. $updated commande(s) mise(s) à jour sur " . $pendingOrders->count() . " vérifiée(s).");

        return 0;
    }
}
