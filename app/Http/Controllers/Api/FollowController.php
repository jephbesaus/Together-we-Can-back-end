<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Follow;
use App\Models\Notification;
use Illuminate\Http\Request;

class FollowController extends Controller
{
    use \App\Traits\ApiResponseTrait;

    public function toggleFollow($id)
    {
        $userId = auth()->id();

        if ((int) $id === $userId) {
            return $this->errorResponse('You cannot follow yourself.', 400);
        }

        $targetUser = User::find($id);

        if (!$targetUser) {
            return $this->errorResponse('User not found.', 404);
        }

        $isNowFollowing = Follow::toggle($userId, $id);

        if ($isNowFollowing) {
            Notification::create([
                'user_id' => $id,
                'type' => 'follow',
                'message' => auth()->user()->name . ' a commencé à vous suivre.',
                'data' => json_encode(['user_id' => $userId]),
                'has_sound' => true,
            ]);
        }

        return $this->successResponse([
            'following' => $isNowFollowing,
            'followers_count' => $targetUser->fresh()->followers_count,
        ]);
    }

    public function followers($id, Request $request)
    {
        $user = User::find($id);

        if (!$user) {
            return $this->errorResponse('User not found.', 404);
        }

        return $this->successResponse([
            'followers' => $this->paginateRelation($user->followers(), $request),
        ]);
    }

    public function following($id, Request $request)
    {
        $user = User::find($id);

        if (!$user) {
            return $this->errorResponse('User not found.', 404);
        }

        return $this->successResponse([
            'following' => $this->paginateRelation($user->following(), $request),
        ]);
    }

    public function myFollowers(Request $request)
    {
        $user = auth()->user();

        return $this->successResponse([
            'followers' => $this->paginateRelation($user->followers(), $request),
        ]);
    }

    public function myFollowing(Request $request)
    {
        $user = auth()->user();

        return $this->successResponse([
            'following' => $this->paginateRelation($user->following(), $request),
        ]);
    }

    private function paginateRelation($relationQuery, Request $request)
    {
        $limit = $request->input('limit', 20);
        $page = $request->input('page', 1);
        $offset = ($page - 1) * $limit;

        return $relationQuery->skip($offset)->take($limit)->get();
    }

    public function isFollowing($id)
    {
        $isFollowing = Follow::isFollowing(auth()->id(), $id);

        return $this->successResponse(['is_following' => $isFollowing]);
    }

    public function mutual($id)
    {
        $userId = auth()->id();

        $myFollowingIds = Follow::where('follower_id', $userId)->pluck('following_id');
        $theirFollowerIds = Follow::where('following_id', $id)->pluck('follower_id');

        $mutualIds = $myFollowingIds->intersect($theirFollowerIds);
        $mutualUsers = User::whereIn('id', $mutualIds)->get();

        return $this->successResponse(['mutual_friends' => $mutualUsers]);
    }

    public function suggestions()
    {
        $userId = auth()->id();

        $followingIds = Follow::where('follower_id', $userId)->pluck('following_id')->toArray();
        $followingIds[] = $userId;

        $suggestions = User::whereNotIn('id', $followingIds)
            ->orderBy('followers_count', 'desc')
            ->limit(10)
            ->get();

        return $this->successResponse(['suggestions' => $suggestions]);
    }

    public function myStats()
    {
        $userId = auth()->id();

        return $this->successResponse([
            'followers_count' => Follow::where('following_id', $userId)->count(),
            'following_count' => Follow::where('follower_id', $userId)->count(),
        ]);
    }
}
