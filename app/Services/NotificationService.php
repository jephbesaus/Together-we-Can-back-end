<?php

namespace App\Services;

use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification as FirebaseNotification;
use Illuminate\Support\Facades\Log;

class NotificationService
{
    protected $messaging;

    public function __construct()
    {
        try {
            $credPath = config('firebase.credentials.file');
            Log::info('FCM: loading credentials from ' . $credPath);
            if (!file_exists($credPath)) {
                Log::error('FCM: credentials file not found: ' . $credPath);
                return;
            }
            $factory = (new Factory)->withServiceAccount($credPath)->withProjectId(config('firebase.project_id'));
            $this->messaging = $factory->createMessaging();
            Log::info('FCM: messaging initialized successfully');
        } catch (\Exception $e) {
            Log::error('FCM Initialization failed: ' . $e->getMessage());
        }
    }

    public function sendPush($deviceToken, $title, $body, $data = [])
    {
        if (!$deviceToken || !$this->messaging) return false;
        try {
            $notification = FirebaseNotification::create($title, $body);
            $message = CloudMessage::withTarget('token', $deviceToken)->withNotification($notification)->withData($data)->withPriority('high')->withTimeToLive(86400);
            $result = $this->messaging->send($message);
            Log::info('Push notification sent: ' . $result);
            return true;
        } catch (\Exception $e) { Log::error('FCM send error: ' . $e->getMessage()); return false; }
    }

    public function sendPushToMultiple(array $deviceTokens, $title, $body, $data = [])
    {
        if (empty($deviceTokens) || !$this->messaging) return false;
        try {
            $notification = FirebaseNotification::create($title, $body);
            $chunks = array_chunk($deviceTokens, 500);
            $success = 0;
            foreach ($chunks as $chunk) {
                $message = CloudMessage::new()->withNotification($notification)->withData($data)->withPriority('high')->withTimeToLive(86400);
                $result = $this->messaging->sendMulticast($message, $chunk);
                $success += $result->successes()->count();
            }
            Log::info("Push notifications sent to $success devices");
            return $success;
        } catch (\Exception $e) { Log::error('FCM send error: ' . $e->getMessage()); return false; }
    }

    public function sendToTopic($topic, $title, $body, $data = [])
    {
        if (!$this->messaging) return false;
        try {
            $notification = FirebaseNotification::create($title, $body);
            $message = CloudMessage::withTarget('topic', $topic)->withNotification($notification)->withData($data)->withPriority('high');
            $result = $this->messaging->send($message);
            Log::info('Topic notification sent: ' . $result);
            return true;
        } catch (\Exception $e) { Log::error('FCM topic send error: ' . $e->getMessage()); return false; }
    }

    public function subscribeToTopic($deviceToken, $topic)
    {
        if (!$deviceToken || !$this->messaging) return false;
        try { $result = $this->messaging->subscribeToTopic($topic, $deviceToken); return $result; } catch (\Exception $e) { Log::error('FCM subscribe error: ' . $e->getMessage()); return false; }
    }

    public function unsubscribeFromTopic($deviceToken, $topic)
    {
        if (!$deviceToken || !$this->messaging) return false;
        try { $result = $this->messaging->unsubscribeFromTopic($topic, $deviceToken); return $result; } catch (\Exception $e) { Log::error('FCM unsubscribe error: ' . $e->getMessage()); return false; }
    }
}
