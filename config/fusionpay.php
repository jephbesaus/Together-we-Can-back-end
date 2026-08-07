<?php

return [

    'api_url' => env('FUSIONPAY_API_URL', 'https://api.fusionpay.com/v1'),

    'api_key' => env('FUSIONPAY_API_KEY'),

    'currency' => env('FUSIONPAY_CURRENCY', 'XOF'),

    'callback_url' => env('FUSIONPAY_CALLBACK_URL', env('APP_URL') . '/api/webhooks/fusionpay'),

];
