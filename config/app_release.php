<?php

return [

    'version' => env('APP_RELEASE_VERSION', '1.0.0'),

    'apk_filename' => env('APP_RELEASE_APK', 'together-we-can.apk'),

    'release_notes' => env('APP_RELEASE_NOTES', 'Première version de Together We Can.'),

    'min_android_version' => env('APP_MIN_ANDROID_VERSION', '5.0'),

    // Si renseigné (Google Drive, GitHub Releases, MediaFire...), cette URL est
    // utilisée en priorité pour le téléchargement — le disque de Render est
    // éphémère et ne conserve pas les fichiers uploadés entre les redéploiements.
    // URL par défaut codée en dur pour être déployée avec le code.
    'external_url' => env(
        'APP_RELEASE_EXTERNAL_URL',
        'https://www.mediafire.com/file/orkm67j1wqpib69/Together.apk/file'
    ),

];
