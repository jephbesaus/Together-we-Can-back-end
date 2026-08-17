<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Post;
use App\Models\Like;
use App\Models\Comment;
use App\Models\Notification;
use App\Models\Follow;
use App\Models\StoryView;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class PostController extends Controller
{
    use \App\Traits\ApiResponseTrait;

    public function feed(Request $request)
    {
        $userId = auth()->id();
        $limit = $request->input('limit', 20);
        $page = $request->input('page', 1);
        $offset = ($page - 1) * $limit;

        $followingIds = Follow::where('follower_id', $userId)
            ->pluck('following_id')
            ->toArray();
        $followingIds[] = $userId;

        $posts = Post::published()
            ->notStories()
            ->with(['user', 'likes', 'comments'])
            ->where(function($query) use ($followingIds) {
                $query->whereIn('user_id', $followingIds)
                    ->orWhere('is_announcement', true);
            })
            ->orderBy('created_at', 'desc')
            ->skip($offset)
            ->take($limit)
            ->get();

        foreach ($posts as $post) {
            $post->incrementViews();
        }

        return $this->successResponse([
            'posts' => $posts,
            'has_more' => $posts->count() == $limit,
            'total' => Post::published()->notStories()->count(),
            'page' => $page,
        ]);
    }

    public function stories(Request $request)
    {
        $userId = auth()->id();

        $followingIds = Follow::where('follower_id', $userId)
            ->pluck('following_id')
            ->toArray();
        $followingIds[] = $userId;

        $stories = Post::published()
            ->stories()
            ->with('user')
            ->whereIn('user_id', $followingIds)
            ->orderBy('created_at', 'desc')
            ->get()
            ->groupBy('user_id')
            ->map(function ($items) use ($userId) {
                return $items->take(5)->map(function ($story) use ($userId) {
                    $story->viewers_count = StoryView::where('story_id', $story->id)->count();
                    $story->is_viewed_by_user = StoryView::where('story_id', $story->id)
                        ->where('user_id', $userId)->exists();
                    $story->is_liked_by_user = Like::where('post_id', $story->id)
                        ->where('user_id', $userId)->whereNull('comment_id')->exists();
                    return $story;
                });
            })
            ->flatten()
            ->values();

        return $this->successResponse(['stories' => $stories]);
    }

    public function show($id)
    {
        $post = Post::with(['user', 'comments.user', 'likes.user'])
            ->published()
            ->find($id);

        if (!$post) {
            return $this->errorResponse('Post not found.', 404);
        }

        $post->incrementViews();

        return $this->successResponse($post);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'content' => 'nullable|string|max:5000',
            'media_type' => 'required|in:text,image,video,story',
            'media' => 'nullable|array',
            'media.*' => 'file|mimes:jpeg,png,gif,mp4,mov,avi|max:102400',
            'is_announcement' => 'boolean',
            'is_story' => 'boolean',
            'story_expires_at' => 'nullable|date|after:now',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        if (auth()->user()->is_blocked) {
            return $this->errorResponse('Your account is blocked.', 403);
        }

        $mediaUrls = [];
        $thumbnailUrl = null;

        if ($request->hasFile('media')) {
            foreach ($request->file('media') as $file) {
                $path = $file->store('posts/' . date('Y/m/d'), 'public');
                $url = Storage::url($path);
                $mediaUrls[] = $url;
            }
        }

        $post = Post::create([
            'user_id' => auth()->id(),
            'content' => $request->content,
            'media_type' => $request->media_type,
            'media_url' => !empty($mediaUrls) ? json_encode($mediaUrls) : null,
            'thumbnail_url' => $thumbnailUrl,
            'is_announcement' => $request->input('is_announcement', false),
            'is_story' => $request->input('is_story', false),
            'story_expires_at' => $request->input('story_expires_at'),
            'is_published' => true,
            'likes_count' => 0,
            'comments_count' => 0,
            'shares_count' => 0,
            'views_count' => 0,
        ]);

        if (!$post->is_story) {
            $this->notifyFollowers($post);
        }

        return $this->successResponse([
            'message' => 'Post created successfully.',
            'post' => $post->load('user'),
        ], 201);
    }

    public function update(Request $request, $id)
    {
        $post = Post::where('user_id', auth()->id())->find($id);

        if (!$post) {
            return $this->errorResponse('Post not found.', 404);
        }

        $validator = Validator::make($request->all(), [
            'content' => 'nullable|string|max:5000',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $post->update(['content' => $request->input('content', $post->content)]);

        return $this->successResponse([
            'message' => 'Post updated successfully.',
            'post' => $post->load('user'),
        ]);
    }

    public function destroy($id)
    {
        $post = Post::where('user_id', auth()->id())->find($id);

        if (!$post) {
            return $this->errorResponse('Post not found.', 404);
        }

        if ($post->media_url) {
            $mediaUrls = json_decode($post->media_url, true) ?? [$post->media_url];
            foreach ($mediaUrls as $url) {
                $path = str_replace('/storage/', 'public/', $url);
                Storage::delete($path);
            }
        }

        $post->delete();

        return $this->successResponse(['message' => 'Post deleted successfully.']);
    }

    public function toggleLike($id)
    {
        $post = Post::find($id);

        if (!$post) {
            return $this->errorResponse('Post not found.', 404);
        }

        $userId = auth()->id();
        $existingLike = Like::where('user_id', $userId)
            ->where('post_id', $id)
            ->whereNull('comment_id')
            ->first();

        if ($existingLike) {
            $existingLike->delete();
            $post->decrementLikes();

            return $this->successResponse([
                'liked' => false,
                'likes_count' => $post->likes_count,
            ]);
        }

        Like::create([
            'user_id' => $userId,
            'post_id' => $id,
        ]);
        $post->incrementLikes();

        if ($post->user_id !== $userId) {
            Notification::create([
                'user_id' => $post->user_id,
                'type' => 'like',
                'message' => auth()->user()->name . ' a aimé votre publication.',
                'data' => json_encode(['post_id' => $post->id, 'user_id' => $userId]),
                'has_sound' => true,
            ]);
        }

        return $this->successResponse([
            'liked' => true,
            'likes_count' => $post->likes_count,
        ]);
    }

    public function share($id)
    {
        $post = Post::find($id);

        if (!$post) {
            return $this->errorResponse('Post not found.', 404);
        }

        $post->incrementShares();

        if ($post->user_id !== auth()->id()) {
            Notification::create([
                'user_id' => $post->user_id,
                'type' => 'share',
                'message' => auth()->user()->name . ' a partagé votre publication.',
                'data' => json_encode(['post_id' => $post->id, 'user_id' => auth()->id()]),
                'has_sound' => true,
            ]);
        }

        return $this->successResponse([
            'message' => 'Post shared successfully.',
            'shares_count' => $post->shares_count,
        ]);
    }

    public function report(Request $request, $id)
    {
        $post = Post::find($id);

        if (!$post) {
            return $this->errorResponse('Post not found.', 404);
        }

        $validator = Validator::make($request->all(), [
            'reason' => 'required|string|min:10|max:500',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $report = \App\Models\Report::create([
            'reporter_id' => auth()->id(),
            'post_id' => $id,
            'reason' => $request->reason,
            'status' => 'pending',
        ]);

        Notification::create([
            'user_id' => 1,
            'type' => 'report',
            'message' => 'Un contenu a été signalé par ' . auth()->user()->name,
            'data' => json_encode(['post_id' => $post->id, 'report_id' => $report->id]),
            'has_sound' => true,
        ]);

        return $this->successResponse([
            'message' => 'Post reported successfully.',
        ]);
    }

    public function search(Request $request)
    {
        $query = $request->input('q');
        $limit = $request->input('limit', 20);

        if (empty($query)) {
            return $this->errorResponse('Search query is required.', 422);
        }

        $posts = Post::published()
            ->notStories()
            ->with('user')
            ->where('content', 'LIKE', "%{$query}%")
            ->orderBy('created_at', 'desc')
            ->limit($limit)
            ->get();

        return $this->successResponse([
            'posts' => $posts,
            'count' => $posts->count(),
        ]);
    }

    public function viewStory($id)
    {
        $story = Post::where('is_story', true)->find($id);

        if (!$story) {
            return $this->errorResponse('Story not found.', 404);
        }

        $userId = auth()->id();

        StoryView::updateOrCreate(
            ['story_id' => $id, 'user_id' => $userId],
            ['viewed_at' => now()]
        );

        $story->incrementViews();

        return $this->successResponse([
            'viewed' => true,
            'viewers_count' => StoryView::where('story_id', $id)->count(),
        ]);
    }

    public function storyLikers($id)
    {
        $story = Post::where('is_story', true)->find($id);

        if (!$story) {
            return $this->errorResponse('Story not found.', 404);
        }

        $likers = Like::where('post_id', $id)
            ->whereNull('comment_id')
            ->with('user:id,name,profile_photo_url')
            ->get()
            ->pluck('user');

        return $this->successResponse([
            'likers' => $likers,
            'count' => $likers->count(),
        ]);
    }

    private function notifyFollowers($post)
    {
        $followers = Follow::where('following_id', $post->user_id)
            ->with('follower')
            ->get();

        foreach ($followers as $follow) {
            Notification::create([
                'user_id' => $follow->follower_id,
                'type' => 'new_post',
                'message' => auth()->user()->name . ' a publié un nouveau contenu.',
                'data' => json_encode(['post_id' => $post->id, 'user_id' => $post->user_id]),
                'has_sound' => true,
            ]);
        }
    }
}
