<?php

return [

    'currency' => env('PAYMENT_CURRENCY', 'FCFA'),

    'methods' => [
        'orange_money' => ['label' => 'Orange Money', 'provider' => 'orange'],
        'vodacom_mpesa' => ['label' => 'Vodacom M-Pesa', 'provider' => 'vodacom'],
        'airtel_money' => ['label' => 'Airtel Money', 'provider' => 'airtel'],
        'africell_money' => ['label' => 'Africell Money', 'provider' => 'africell'],
        'wallet' => ['label' => 'Portefeuille TWC', 'provider' => 'internal'],
    ],

    'min_deposit' => env('PAYMENT_MIN_DEPOSIT', 500),

    'min_withdrawal' => env('PAYMENT_MIN_WITHDRAWAL', 1000),

];
