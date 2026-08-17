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
        if (!$notification->has_sound) return;

        $user = $notification->user;
        if (!$user || !$user->device_token) return;

        $title = $notification->title ?? $this->getTitleForType($notification->type);

        $this->notificationService->sendPush(
            $user->device_token,
            $title,
            $notification->message,
            [
                'type' => $notification->type,
                'notification_id' => $notification->id,
                'data' => is_string($notification->data) ? $notification->data : json_encode($notification->data ?? []),
            ]
        );
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
