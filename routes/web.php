<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return response()->json([
        'app' => 'Together We Can API',
        'status' => 'running',
    ]);
});
