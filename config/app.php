<?php

use Illuminate\Support\Facades\Facade;

return [

    'name' => env('APP_NAME', 'Together We Can'),

    'env' => env('APP_ENV', 'production'),

    'debug' => (bool) env('APP_DEBUG', false),

    'url' => env('APP_URL', 'http://localhost'),

    'frontend_url' => env('FRONTEND_URL', env('APP_URL', 'http://localhost')),

    'timezone' => 'Africa/Kinshasa',

    'locale' => 'fr',

    'fallback_locale' => 'en',

    'faker_locale' => 'fr_FR',

    'cipher' => 'AES-256-CBC',

    'key' => env('APP_KEY'),

    'previous_keys' => [
        ...array_filter(
            explode(',', env('APP_PREVIOUS_KEYS', ''))
        ),
    ],

    'maintenance' => [
        'driver' => env('APP_MAINTENANCE_DRIVER', 'file'),
        'store' => env('APP_MAINTENANCE_STORE', 'database'),
    ],

    'providers' => \Illuminate\Support\ServiceProvider::defaultProviders()->toArray(),

    'aliases' => Facade::defaultAliases()->merge([
        //
    ])->toArray(),

];
