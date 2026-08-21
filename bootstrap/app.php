<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {
        // Render passe par un proxy : on lui fait confiance pour que url()
        // génère bien des liens en https:// (liens de téléchargement,
        // redirect_url Chariow, etc.)
        $middleware->trustProxies(at: '*');

        $middleware->alias([
            'admin' => \App\Http\Middleware\AdminMiddleware::class,
            'blocked' => \App\Http\Middleware\CheckBlocked::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions) {
        // Sans route "login", une AuthenticationException sur une route API
        // provoquait un 500 chez les clients qui n'envoient pas
        // "Accept: application/json" (navigateur, curl simple).
        $exceptions->render(function (\Illuminate\Auth\AuthenticationException $e, \Illuminate\Http\Request $request) {
            if ($request->expectsJson() || $request->is('api/*')) {
                return response()->json(['message' => 'Unauthenticated.'], 401);
            }
        });
    })->create();
