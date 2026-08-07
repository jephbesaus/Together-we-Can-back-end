<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class CheckBlocked
{
    public function handle(Request $request, Closure $next)
    {
        if ($request->user() && $request->user()->is_blocked) {
            return response()->json([
                'success' => false,
                'error' => 'Votre compte a été bloqué. Veuillez contacter l\'administration.',
            ], 403);
        }

        return $next($request);
    }
}
