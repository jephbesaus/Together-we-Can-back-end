<?php

namespace App\Traits;

use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

trait ImageUploadTrait
{
    public function uploadImage($file, $folder = 'uploads', $disk = 'public')
    {
        $filename = Str::random(20) . '.' . $file->getClientOriginalExtension();
        $path = $file->storeAs($folder, $filename, $disk);
        return Storage::url($path);
    }

    public function uploadImages($files, $folder = 'uploads', $disk = 'public')
    {
        $urls = [];
        foreach ($files as $file) {
            $urls[] = $this->uploadImage($file, $folder, $disk);
        }
        return $urls;
    }

    public function deleteImage($path, $disk = 'public')
    {
        if ($path) {
            $relativePath = str_replace('/storage/', '', $path);
            Storage::disk($disk)->delete($relativePath);
            return true;
        }
        return false;
    }
}
