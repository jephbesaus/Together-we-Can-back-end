<?php

return [

    'api_url' => env('FUSIONPAY_API_URL', 'https://api.fusionpay.com/v1'),

    'api_key' => env('FUSIONPAY_API_KEY'),

    'currency' => env('FUSIONPAY_CURRENCY', 'XOF'),

    'callback_url' => env('FUSIONPAY_CALLBACK_URL', env('APP_URL') . '/api/webhooks/fusionpay'),

    // Clé secrète fournie par FusionPay pour signer leurs appels webhook.
    // Sans elle, n'importe qui pourrait appeler notre webhook et simuler
    // un paiement réussi pour se créditer gratuitement.
    'webhook_secret' => env('FUSIONPAY_WEBHOOK_SECRET'),

];
