<?php

return [

    'api_url' => env('FULLSMM_API_URL', 'https://panel.fullsmm.com/api/v2'),

    'api_key' => env('FULLSMM_API_KEY'),

    'platforms' => [
        'YouTube' => ['icon' => 'youtube', 'color' => '#FF0000'],
        'TikTok' => ['icon' => 'tiktok', 'color' => '#000000'],
        'Facebook' => ['icon' => 'facebook', 'color' => '#1877F2'],
        'Instagram' => ['icon' => 'instagram', 'color' => '#E4405F'],
        'Twitter' => ['icon' => 'twitter', 'color' => '#1DA1F2'],
        'Telegram' => ['icon' => 'telegram', 'color' => '#26A5E4'],
        'WhatsApp' => ['icon' => 'whatsapp', 'color' => '#25D366'],
    ],

];
