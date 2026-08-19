<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Response;

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

    $filename = config('app_release.apk_filename');
    $path = public_path('downloads/' . $filename);

    if (file_exists($path)) {
        $size = filesize($path);

        return Response::stream(function () use ($path) {
            readfile($path);
        }, 200, [
            'Content-Type' => 'application/vnd.android.package-archive',
            'Content-Disposition' => 'attachment; filename="together-we-can.apk"',
            'Content-Length' => $size,
            'Cache-Control' => 'no-cache',
        ]);
    }

    return response('<html><body style="background:#0B0B0B;color:#fff;font-family:sans-serif;text-align:center;padding:60px 20px;">'
        . '<h2>Téléchargement bientôt disponible</h2>'
        . '<p style="color:#999;">L\'application sera bientôt disponible en téléchargement direct.</p>'
        . '<a href="/" style="color:#00A86B;">Retour à l\'accueil</a>'
        . '</body></html>', 200)->header('Content-Type', 'text/html');
})->name('download');

Route::get('/ref/{code}', function ($code) {
    $downloadUrl = url('/download');
    $appName = 'Together We Can';

    $html = '<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Rejoignez ' . $appName . '</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { background: #0B0B0B; color: #fff; font-family: -apple-system, sans-serif; min-height: 100vh; display: flex; align-items: center; justify-content: center; }
  .card { max-width: 400px; width: 90%; text-align: center; padding: 40px 24px; background: #1A1A1A; border-radius: 20px; box-shadow: 0 8px 32px rgba(0,168,107,0.15); }
  .logo { font-size: 48px; margin-bottom: 16px; }
  h1 { font-size: 24px; margin-bottom: 8px; color: #00A86B; }
  p { color: #999; margin-bottom: 24px; line-height: 1.5; }
  .code-box { background: #0B0B0B; border: 2px dashed #00A86B; border-radius: 12px; padding: 16px; margin-bottom: 24px; }
  .code-label { color: #999; font-size: 12px; margin-bottom: 4px; }
  .code { font-size: 28px; font-weight: bold; color: #00A86B; letter-spacing: 4px; }
  .btn { display: inline-block; background: #00A86B; color: #fff; text-decoration: none; padding: 16px 40px; border-radius: 12px; font-size: 18px; font-weight: bold; transition: background 0.2s; }
  .btn:hover { background: #008C5A; }
  .bonus { margin-top: 16px; color: #FFD700; font-size: 14px; }
  .steps { margin-top: 24px; text-align: left; }
  .steps li { color: #ccc; margin-bottom: 8px; font-size: 14px; }
  .steps li strong { color: #00A86B; }
</style>
</head>
<body>
<div class="card">
  <div class="logo">🤝</div>
  <h1>' . $appName . '</h1>
  <p>Ensemble, on avance ! Rejoins la communauté et commence à gagner.</p>
  <div class="code-box">
    <div class="code-label">Ton code de parrainage</div>
    <div class="code">' . e($code) . '</div>
  </div>
  <a href="' . e($downloadUrl) . '" class="btn">Télécharger l\'app</a>
  <div class="bonus">🎁 Gagne 500 CDF par parrainage !</div>
  <ol class="steps">
    <li><strong>1.</strong> Télécharge et installe l\'application</li>
    <li><strong>2.</strong> Crée ton compte</li>
    <li><strong>3.</strong> Entre le code <strong>' . e($code) . '</strong> lors de l\'inscription</li>
    <li><strong>4.</strong> Tu reçois <strong>500 CDF</strong> automatiquement !</li>
  </ol>
</div>
</body>
</html>';

    return response($html, 200)->header('Content-Type', 'text/html');
});

Route::get('/thank-you', function () {
    $reference = request()->query('reference', '');
    $type = request()->query('type', 'deposit');
    $courseId = request()->query('courseId', '');
    $transactionId = request()->query('transaction_id', '');

    $deepLink = 'twc://payment?reference=' . urlencode($reference) . '&type=' . urlencode($type);
    if ($courseId) {
        $deepLink .= '&courseId=' . urlencode($courseId);
    }
    if ($transactionId) {
        $deepLink .= '&transaction_id=' . urlencode($transactionId);
    }

    $html = '<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Paiement confirmé</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { background: #0B0B0B; color: #fff; font-family: -apple-system, sans-serif; min-height: 100vh; display: flex; align-items: center; justify-content: center; }
  .card { max-width: 400px; width: 90%; text-align: center; padding: 40px 24px; background: #1A1A1A; border-radius: 20px; box-shadow: 0 8px 32px rgba(0,168,107,0.15); }
  .check { font-size: 64px; margin-bottom: 16px; }
  h1 { font-size: 22px; margin-bottom: 8px; color: #00A86B; }
  p { color: #999; margin-bottom: 24px; line-height: 1.5; }
  .btn { display: inline-block; background: #00A86B; color: #fff; text-decoration: none; padding: 16px 40px; border-radius: 12px; font-size: 18px; font-weight: bold; transition: background 0.2s; }
  .btn:hover { background: #008C5A; }
  .hint { margin-top: 16px; color: #666; font-size: 13px; }
</style>
</head>
<body>
<div class="card">
  <div class="check">✅</div>
  <h1>Paiement confirmé !</h1>
  <p>Merci pour votre achat. Votre solde sera mis à jour automatiquement.</p>
  <a href="' . htmlspecialchars($deepLink) . '" class="btn">Retour à l\'application</a>
  <p class="hint">Si le bouton ne fonctionne pas, ouvrez manuellement l\'application Together We Can.</p>
</div>
<script>
  setTimeout(function() { window.location.href = "' . addslashes($deepLink) . '"; }, 1500);
</script>
</body>
</html>';

    return response($html, 200)->header('Content-Type', 'text/html');
})->name('thank-you');

// Vérification technique de l'état du serveur (utile pour le monitoring),
// séparée de la page d'accueil publique.
Route::get('/status', function () {
    return response()->json([
        'app' => 'Together We Can API',
        'status' => 'running',
    ]);
});
