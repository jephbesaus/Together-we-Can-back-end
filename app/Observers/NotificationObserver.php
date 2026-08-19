<?php

namespace App\Observers;

use App\Models\Notification;
use App\Services\NotificationService;
use Illuminate\Support\Facades\Log;

class NotificationObserver
{
    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }

    public function created(Notification $notification)
    {
        Log::info('NotificationObserver: notification created', [
            'id' => $notification->id,
            'type' => $notification->type,
            'user_id' => $notification->user_id,
            'has_sound' => $notification->has_sound,
        ]);

        if (!$notification->has_sound) {
            Log::info('NotificationObserver: skipped (has_sound=false)');
            return;
        }

        $user = $notification->user;
        if (!$user) {
            Log::warning('NotificationObserver: user not found for notification ' . $notification->id);
            return;
        }
        if (!$user->device_token) {
            Log::warning('NotificationObserver: no device_token for user ' . $user->id);
            return;
        }

        $title = $notification->title ?? $this->getTitleForType($notification->type);

        Log::info('NotificationObserver: sending push', [
            'token' => substr($user->device_token, 0, 20) . '...',
            'title' => $title,
        ]);

        $result = $this->notificationService->sendPush(
            $user->device_token,
            $title,
            $notification->message,
            [
                'type' => $notification->type,
                'notification_id' => $notification->id,
                'data' => is_string($notification->data) ? $notification->data : json_encode($notification->data ?? []),
            ]
        );

        Log::info('NotificationObserver: sendPush result=' . ($result ? 'true' : 'false'));
    }

    private function getTitleForType(string $type): string
    {
        $titles = [
            'message' => 'Nouveau message',
            'like' => 'Nouveau like',
            'comment' => 'Nouveau commentaire',
            'share' => 'Publication partagée',
            'follow' => 'Nouvel abonné',
            'premium' => 'Demande premium',
            'premium_approved' => 'Premium approuvé',
            'premium_rejected' => 'Premium refusé',
            'marketplace' => 'Marketplace',
            'boost' => 'Commande Boost',
            'boost_completed' => 'Boost terminé',
            'boost_failed' => 'Boost échoué',
            'announcement' => 'Nouvelle annonce',
            'payment' => 'Paiement',
            'course_enrollment' => 'Inscription cours',
            'account_blocked' => 'Compte bloqué',
            'account_unblocked' => 'Compte débloqué',
            'product_approved' => 'Produit approuvé',
            'product_rejected' => 'Produit refusé',
            'transfer_sent' => 'Transfert envoyé',
            'transfer_received' => 'Transfert reçu',
            'new_post' => 'Nouvelle publication',
            'report' => 'Signalement',
            'course_approved' => 'Cours approuvé',
            'course_rejected' => 'Cours refusé',
        ];

        return $titles[$type] ?? 'Together We Can';
    }
}
