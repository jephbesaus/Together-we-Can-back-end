<?php

return [

    'api_key' => env('CHARIOW_API_KEY'),

    'api_url' => 'https://api.chariow.com/v1',

    'store_url' => env('CHARIOW_STORE_URL', 'https://epazzsvw.mychariow.store'),

    'deposit_product_id' => env('CHARIOW_DEPOSIT_PRODUCT_ID', 'prd_dd7c35ic'),

    'boost_product_id' => env('CHARIOW_BOOST_PRODUCT_ID', 'prd_vd3rkixz'),

    'pulse_secret' => env('CHARIOW_PULSE_SECRET'),

    'currency' => 'CDF',

];
