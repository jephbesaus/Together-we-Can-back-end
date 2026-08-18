<?php

return [

    'version' => env('APP_RELEASE_VERSION', '1.1.0'),

    'apk_filename' => env('APP_RELEASE_APK', 'together-we-can.apk'),

    'release_notes' => env('APP_RELEASE_NOTES', 'Splash moderne, formations complètes, Clic-Boost, Chariow, performances améliorées.'),

    'min_android_version' => env('APP_MIN_ANDROID_VERSION', '5.0'),

    // URL externe optionnelle (Google Drive, GitHub Releases…).
    // Si vide, l'APK est servi directement depuis public/downloads/.
    'external_url' => env('APP_RELEASE_EXTERNAL_URL', ''),

];
