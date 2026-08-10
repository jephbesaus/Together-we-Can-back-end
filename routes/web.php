<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('landing');
});

Route::get('/terms', function () {
    return view('legal.terms');
});

Route::get('/privacy', function () {
    return view('legal.privacy');
});

Route::get('/download', function () {
    $externalUrl = config('app_release.external_url');
    if ($externalUrl) {
        return redirect($externalUrl);
    }

    $path = public_path('downloads/' . config('app_release.apk_filename'));
    if (file_exists($path)) {
        return redirect('/downloads/' . config('app_release.apk_filename'));
    }

    return response('<html><body style="background:#0B0B0B;color:#fff;font-family:sans-serif;text-align:center;padding:60px 20px;">'
        . '<h2>Téléchargement bientôt disponible</h2>'
        . '<p style="color:#999;">L\'application sera bientôt disponible en téléchargement direct.</p>'
        . '<a href="/" style="color:#00A86B;">Retour à l\'accueil</a>'
        . '</body></html>', 200)->header('Content-Type', 'text/html');
});

// Vérification technique de l'état du serveur (utile pour le monitoring),
// séparée de la page d'accueil publique.
Route::get('/status', function () {
    return response()->json([
        'app' => 'Together We Can API',
        'status' => 'running',
    ]);
});
