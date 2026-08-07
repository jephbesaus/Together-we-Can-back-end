<?php

namespace App\Traits;

trait ApiResponseTrait
{
    public function successResponse($data = null, $statusCode = 200)
    {
        return response()->json([
            'success' => true,
            'data' => $data,
        ], $statusCode);
    }

    public function errorResponse($message = null, $statusCode = 400)
    {
        return response()->json([
            'success' => false,
            'error' => $message,
        ], $statusCode);
    }
}
