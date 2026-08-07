<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Follow;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Hash;

class UserController extends Controller
{
    use \App\Traits\ApiResponseTrait;

    public function profile()
    {
        $user = auth()->user()->load(['followers', 'following']);

        return $this->successResponse([
            'user' => $user,
            'followers_count' => $user->followers()->count(),
            'following_count' => $user->following()->count(),
            'posts_count' => $user->posts()->count(),
            'posts' => $user->posts()->orderBy('created_at', 'desc')->limit(20)->get(),
        ]);
    }

    public function updateProfile(Request $request)
    {
        $user = auth()->user();

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|string|max:255',
            'bio' => 'nullable|string|max:500',
            'phone' => 'sometimes|string|unique:users,phone,' . $user->id,
            'email' => 'sometimes|email|unique:users,email,' . $user->id,
            'profile_photo' => 'nullable|file|mimes:jpeg,png,gif|max:5120',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $data = $request->only(['name', 'bio', 'phone', 'email']);

        if ($request->hasFile('profile_photo')) {
            $path = $request->file('profile_photo')->store('profiles', 'public');
            $data['profile_photo'] = $path;
        }

        $user->update($data);

        return $this->successResponse([
            'message' => 'Profile updated.',
            'user' => $user->fresh(),
        ]);
    }

    public function updateProfilePhoto(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'photo' => 'required|file|mimes:jpeg,png,gif|max:5120',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $user = auth()->user();
        $path = $request->file('photo')->store('profiles', 'public');
        $user->update(['profile_photo' => $path]);

        return $this->successResponse([
            'message' => 'Profile photo updated.',
            'profile_photo' => asset('storage/' . $path),
        ]);
    }

    public function stats()
    {
        $user = auth()->user();

        return $this->successResponse([
            'posts_count' => $user->posts()->count(),
            'followers_count' => $user->followers()->count(),
            'following_count' => $user->following()->count(),
            'boost_balance' => $user->boost_balance,
            'savings_balance' => $user->savings_balance ?? 0,
            'is_premium' => $user->is_premium,
            'is_verified' => $user->is_verified,
        ]);
    }

    public function show($id)
    {
        $user = User::with(['followers', 'following'])->find($id);

        if (!$user) {
            return $this->errorResponse('User not found.', 404);
        }

        $isFollowing = Follow::where('follower_id', auth()->id())
            ->where('following_id', $id)
            ->exists();

        return $this->successResponse([
            'user' => $user,
            'is_following' => $isFollowing,
            'followers_count' => $user->followers()->count(),
            'following_count' => $user->following()->count(),
            'posts_count' => $user->posts()->count(),
        ]);
    }

    public function search(Request $request)
    {
        $query = $request->input('q');

        if (empty($query)) {
            return $this->successResponse(['users' => []]);
        }

        $users = User::where('name', 'LIKE', "%{$query}%")
            ->orWhere('email', 'LIKE', "%{$query}%")
            ->limit(20)
            ->get();

        return $this->successResponse(['users' => $users]);
    }

    public function requestPremium()
    {
        $user = auth()->user();

        if ($user->is_premium) {
            return $this->errorResponse('You are already premium.', 400);
        }

        if ($user->premium_requested) {
            return $this->errorResponse('Premium request already pending.', 400);
        }

        $user->update(['premium_requested' => true]);

        return $this->successResponse([
            'message' => 'Premium request sent. Wait for admin approval.',
        ]);
    }

    public function premiumStatus()
    {
        $user = auth()->user();

        return $this->successResponse([
            'is_premium' => $user->is_premium,
            'premium_requested' => $user->premium_requested,
            'is_verified' => $user->is_verified,
        ]);
    }
}
