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

    private function request($action, $params = [], $method = 'POST')
    {
        $params['key'] = $this->apiKey;
        $params['action'] = $action;

        try {
            if ($method === 'GET') {
                $response = Http::timeout(30)->get($this->apiUrl, $params);
            } else {
                $response = Http::timeout(30)->asForm()->post($this->apiUrl, $params);
            }

            $data = $response->json();

            if ($response->successful()) {
                if (isset($data['error'])) {
                    Log::warning('FullSMM API Error [' . $action . ']: ' . $data['error']);
                    return ['success' => false, 'error' => $data['error']];
                }
                return ['success' => true, 'data' => $data];
            }

            Log::error('FullSMM API HTTP Error [' . $action . ']: ' . $response->status());
            return ['success' => false, 'error' => 'HTTP Error ' . $response->status()];
        } catch (\Exception $e) {
            Log::error('FullSMM API Exception [' . $action . ']: ' . $e->getMessage());
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    public function getBalance()
    {
        $result = $this->request('balance', [], 'GET');
        if ($result['success']) return $result['data'];
        return null;
    }

    public function getServices()
    {
        $cacheKey = 'fullsmm_services';
        $services = Cache::get($cacheKey);
        if ($services) return $services;

        $result = $this->request('services', [], 'GET');
        if ($result['success'] && is_array($result['data'])) {
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
            if ($service['service'] == $serviceId) return $service;
        }
        return null;
    }

    public function placeOrder($serviceId, $link, $quantity, $customData = [])
    {
        $params = [
            'service' => $serviceId,
            'link' => $link,
            'quantity' => $quantity,
        ];
        if (!empty($customData)) {
            $params = array_merge($params, $customData);
        }
        $result = $this->request('order', $params);
        if ($result['success']) return $result['data'];
        return null;
    }

    public function getOrderStatus($orderId)
    {
        $result = $this->request('status', ['order' => $orderId]);
        if ($result['success']) return $result['data'];
        return null;
    }

    public function getCategories()
    {
        try {
            $services = $this->getServices();
            if (!$services || !is_array($services)) return [];
            $categories = [];
            foreach ($services as $service) {
                if (isset($service['category']) && !in_array($service['category'], $categories)) {
                    $categories[] = $service['category'];
                }
            }
            return $categories;
        } catch (\Exception $e) {
            Log::error('FullSMM getCategories error: ' . $e->getMessage());
            return [];
        }
    }

    public function getPlatforms()
    {
        try {
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
        } catch (\Exception $e) {
            Log::error('FullSMM getPlatforms error: ' . $e->getMessage());
            $platforms = [];
        }

        if (empty($platforms)) {
            $platforms = array_keys(config('fullsmm.platforms', []));
        }

        return $platforms;
    }
}
