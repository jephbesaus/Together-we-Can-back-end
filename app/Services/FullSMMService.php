<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class FullSMMService
{
    protected $apiUrl;
    protected $apiKey;

    public function __construct()
    {
        $this->apiUrl = config('fullsmm.api_url');
        $this->apiKey = config('fullsmm.api_key');
    }

    private function request($endpoint, $params = [], $method = 'POST')
    {
        $url = $this->apiUrl . '/' . $endpoint;
        $params['key'] = $this->apiKey;

        try {
            $response = Http::timeout(30)->$method($url, $params);

            if ($response->successful()) {
                $data = $response->json();
                if (isset($data['error'])) {
                    Log::error('FullSMM API Error: ' . $data['error']);
                    return ['success' => false, 'error' => $data['error']];
                }
                return ['success' => true, 'data' => $data];
            }

            Log::error('FullSMM API HTTP Error: ' . $response->status());
            return ['success' => false, 'error' => 'HTTP Error ' . $response->status()];
        } catch (\Exception $e) {
            Log::error('FullSMM API Exception: ' . $e->getMessage());
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    public function getBalance()
    {
        $result = $this->request('balance');
        if ($result['success']) return $result['data'];
        return null;
    }

    public function getServices()
    {
        $cacheKey = 'fullsmm_services';
        $services = Cache::get($cacheKey);
        if ($services) return $services;

        $result = $this->request('services');
        if ($result['success']) {
            Cache::put($cacheKey, $result['data'], 3600);
            return $result['data'];
        }
        return null;
    }

    public function getPlatformServices($platform)
    {
        $services = $this->getServices();
        if (!$services) return [];
        $platformLower = strtolower($platform);
        return array_filter($services, function ($service) use ($platformLower) {
            $categoryLower = strtolower($service['category'] ?? '');
            return strpos($categoryLower, $platformLower) !== false;
        });
    }

    public function getService($serviceId)
    {
        $services = $this->getServices();
        if (!$services) return null;
        foreach ($services as $service) {
            if ($service['id'] == $serviceId) return $service;
        }
        return null;
    }

    public function placeOrder($serviceId, $link, $quantity, $customData = [])
    {
        $params = ['service' => $serviceId, 'link' => $link, 'quantity' => $quantity];
        if (!empty($customData)) $params = array_merge($params, $customData);
        $result = $this->request('order', $params);
        if ($result['success']) return $result['data'];
        return null;
    }

    public function getOrderStatus($orderId)
    {
        $result = $this->request('status', ['order_id' => $orderId]);
        if ($result['success']) return $result['data'];
        return null;
    }

    public function getCategories()
    {
        $services = $this->getServices();
        if (!$services) return [];
        $categories = [];
        foreach ($services as $service) {
            if (isset($service['category']) && !in_array($service['category'], $categories)) {
                $categories[] = $service['category'];
            }
        }
        return $categories;
    }

    public function getPlatforms()
    {
        $categories = $this->getCategories();
        $platforms = [];
        $platformMap = [
            'YouTube' => ['youtube', 'yt'],
            'TikTok' => ['tiktok', 'tt'],
            'Facebook' => ['facebook', 'fb'],
            'Instagram' => ['instagram', 'ig'],
            'Twitter' => ['twitter', 'x'],
            'Telegram' => ['telegram'],
            'WhatsApp' => ['whatsapp'],
        ];

        foreach ($categories as $category) {
            $categoryLower = strtolower($category);
            foreach ($platformMap as $platform => $keywords) {
                foreach ($keywords as $keyword) {
                    if (strpos($categoryLower, $keyword) !== false) {
                        if (!in_array($platform, $platforms)) $platforms[] = $platform;
                        break 2;
                    }
                }
            }
        }
        return $platforms;
    }
}
