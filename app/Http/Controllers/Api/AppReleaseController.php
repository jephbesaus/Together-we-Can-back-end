<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class AppReleaseController extends Controller
{
    use \App\Traits\ApiResponseTrait;

    public function info()
    {
        $filename = config('app_release.apk_filename');
        $path = public_path('downloads/' . $filename);
        $exists = file_exists($path);

        return $this->successResponse([
            'version' => config('app_release.version'),
            'release_notes' => config('app_release.release_notes'),
            'min_android_version' => config('app_release.min_android_version'),
            'download_url' => $exists ? url('/downloads/' . $filename) : null,
            'available' => $exists,
            'file_size_mb' => $exists ? round(filesize($path) / 1048576, 1) : null,
        ]);
    }
}
