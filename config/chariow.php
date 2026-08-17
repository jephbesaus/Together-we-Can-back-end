<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Chariow Payment Configuration
    |--------------------------------------------------------------------------
    |
    | Configuration pour l'intégration Chariow (paiement mobile Money).
    | Les clés API doivent être définies dans le fichier .env.
    |
    */

    'api_key' => env('CHARIOW_API_KEY'),

    'payment_url' => env('CHARIOW_PAYMENT_URL', 'https://api.chariow.com'),

    'webhook_secret' => env('CHARIOW_WEBHOOK_SECRET'),

    'currency' => env('CHARIOW_CURRENCY', 'CDF'),

    'supported_providers' => [
        'orange' => 'Orange Money',
        'mtn' => 'MTN Mobile Money',
        'vodacom' => 'Vodacom M-Pesa',
        'airtel' => 'Airtel Money',
        'africell' => 'Africell Money',
    ],

];
