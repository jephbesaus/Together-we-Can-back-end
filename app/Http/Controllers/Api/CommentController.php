<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Comment;
use App\Models\Post;
use App\Models\Notification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class CommentController extends Controller
{
    use \App\Traits\ApiResponseTrait;

    public function index($postId)
    {
        $post = Post::find($postId);

        if (!$post) {
            return $this->errorResponse('Post not found.', 404);
        }

        $comments = Comment::where('post_id', $postId)
            ->whereNull('parent_id')
            ->with(['user', 'replies.user'])
            ->orderBy('created_at', 'asc')
            ->get();

        return $this->successResponse(['comments' => $comments]);
    }

    public function store(Request $request, $postId)
    {
        $post = Post::find($postId);

        if (!$post) {
            return $this->errorResponse('Post not found.', 404);
        }

        $validator = Validator::make($request->all(), [
            'content' => 'required|string|max:2000',
            'parent_id' => 'nullable|integer|exists:comments,id',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $comment = Comment::create([
            'post_id' => $postId,
            'user_id' => auth()->id(),
            'parent_id' => $request->parent_id,
            'content' => $request->content,
            'likes_count' => 0,
        ]);

        $post->incrementComments();

        if ($post->user_id !== auth()->id()) {
            Notification::create([
                'user_id' => $post->user_id,
                'type' => 'comment',
                'message' => auth()->user()->name . ' a commenté votre publication.',
                'data' => json_encode(['post_id' => $post->id, 'comment_id' => $comment->id]),
                'has_sound' => true,
            ]);
        }

        return $this->successResponse([
            'message' => 'Comment added successfully.',
            'comment' => $comment->load('user'),
        ], 201);
    }

    public function update(Request $request, $id)
    {
        $comment = Comment::where('user_id', auth()->id())->find($id);

        if (!$comment) {
            return $this->errorResponse('Comment not found.', 404);
        }

        $validator = Validator::make($request->all(), [
            'content' => 'required|string|max:2000',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $comment->update(['content' => $request->content]);

        return $this->successResponse([
            'message' => 'Comment updated successfully.',
            'comment' => $comment->load('user'),
        ]);
    }

    public function destroy($id)
    {
        $comment = Comment::where('user_id', auth()->id())->find($id);

        if (!$comment) {
            return $this->errorResponse('Comment not found.', 404);
        }

        $post = Post::find($comment->post_id);
        $comment->delete();

        if ($post) {
            $post->decrement('comments_count');
        }

        return $this->successResponse(['message' => 'Comment deleted successfully.']);
    }

    public function toggleLike($id)
    {
        $comment = Comment::find($id);

        if (!$comment) {
            return $this->errorResponse('Comment not found.', 404);
        }

        $userId = auth()->id();
        $existingLike = \App\Models\Like::where('user_id', $userId)
            ->where('comment_id', $id)
            ->first();

        if ($existingLike) {
            $existingLike->delete();
            $comment->decrement('likes_count');

            return $this->successResponse([
                'liked' => false,
                'likes_count' => $comment->likes_count,
            ]);
        }

        \App\Models\Like::create([
            'user_id' => $userId,
            'comment_id' => $id,
        ]);
        $comment->increment('likes_count');

        return $this->successResponse([
            'liked' => true,
            'likes_count' => $comment->likes_count,
        ]);
    }
}
