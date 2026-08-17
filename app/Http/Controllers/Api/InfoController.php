<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;

class InfoController extends Controller
{
    use \App\Traits\ApiResponseTrait;

    public function support()
    {
        return $this->successResponse([
            'support' => config('support'),
        ]);
    }

    public function about()
    {
        return $this->successResponse([
            'about' => config('about'),
        ]);
    }
}
