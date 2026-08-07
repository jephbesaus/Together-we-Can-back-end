<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Referral;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ReferralController extends Controller
{
    use \App\Traits\ApiResponseTrait;

    public function myInfo()
    {
        $user = auth()->user();

        return $this->successResponse([
            'referral_code' => $user->referral_code,
            'referral_link' => $user->referral_link,
            'referral_count' => $user->referral_count,
            'referral_earnings' => $user->referral_earnings,
            'referrals' => Referral::where('referrer_id', $user->id)->with('referred')->orderBy('created_at', 'desc')->get(),
        ]);
    }

    public function processReferral(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'referral_code' => 'required|string|exists:users,referral_code',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $userId = auth()->id();
        $referrer = User::where('referral_code', $request->referral_code)->first();

        if (!$referrer || $referrer->id === $userId) {
            return $this->errorResponse('Invalid referral code.', 400);
        }

        $existing = Referral::where('referred_id', $userId)->first();
        if ($existing) {
            return $this->errorResponse('You have already been referred by someone.', 400);
        }

        $referral = Referral::create([
            'referrer_id' => $referrer->id,
            'referred_id' => $userId,
            'status' => 'pending',
            'reward_amount' => config('referrals.reward_amount', 500),
        ]);

        auth()->user()->update(['referred_by' => $referrer->id]);
        $referrer->increment('referral_count');

        return $this->successResponse([
            'message' => 'Referral processed successfully.',
            'referral' => $referral,
        ], 201);
    }

    public function completeReferral($id)
    {
        $referral = Referral::find($id);

        if (!$referral) {
            return $this->errorResponse('Referral not found.', 404);
        }

        if ($referral->status === 'completed') {
            return $this->errorResponse('Referral already completed.', 400);
        }

        $referral->complete();

        return $this->successResponse([
            'message' => 'Referral completed successfully.',
            'referral' => $referral->fresh(),
        ]);
    }

    public function shareLink()
    {
        $user = auth()->user();

        return $this->successResponse([
            'referral_code' => $user->referral_code,
            'referral_link' => $user->referral_link,
            'message' => 'Rejoignez Together We Can avec mon code de parrainage : ' . $user->referral_code,
        ]);
    }

    public function leaderboard()
    {
        $topReferrers = User::where('referral_count', '>', 0)
            ->orderBy('referral_count', 'desc')
            ->limit(20)
            ->get(['id', 'name', 'profile_photo', 'referral_count', 'referral_earnings']);

        return $this->successResponse(['leaderboard' => $topReferrers]);
    }
}
