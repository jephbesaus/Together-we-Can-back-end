<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class AdminMiddleware
{
    public function handle(Request $request, Closure $next)
    {
        $user = $request->user();

        if (!$user) {
            return response()->json([
                'success' => false,
                'error' => 'Non authentifié.',
            ], 401);
        }

        if ($user->email !== config('admin.email')) {
            return response()->json([
                'success' => false,
                'error' => 'Accès administrateur non autorisé.',
            ], 403);
        }

        if (!$user->is_admin_activated) {
            return response()->json([
                'success' => false,
                'error' => 'Compte administrateur non activé. Veuillez entrer le code d\'activation.',
            ], 403);
        }

        if ($user->is_blocked) {
            return response()->json([
                'success' => false,
                'error' => 'Votre compte administrateur a été bloqué.',
            ], 403);
        }

        return $next($request);
    }
}
