<?php

namespace App\Support;

class MediaHelper
{
    /**
     * Transforme une URL de stockage (relative, ex: /storage/posts/...) en URL
     * absolue consommable par l'application mobile.
     */
    public static function absoluteUrl(?string $url): ?string
    {
        if ($url === null || $url === '') {
            return null;
        }

        if (preg_match('#^https?://#i', $url)) {
            return $url;
        }

        if (str_starts_with($url, '//')) {
            return 'https:' . $url;
        }

        if (str_starts_with($url, '/')) {
            return rtrim(config('app.url'), '/') . $url;
        }

        return rtrim(config('app.url'), '/') . '/storage/' . ltrim($url, '/');
    }
}
