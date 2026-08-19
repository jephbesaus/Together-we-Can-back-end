<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Message;
use App\Models\Conversation;
use App\Models\User;
use App\Models\Notification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Storage;

class MessageController extends Controller
{
    use \App\Traits\ApiResponseTrait;

    private function findOrCreateConversation($user1Id, $user2Id)
    {
        $conversation = Conversation::where(function ($q) use ($user1Id, $user2Id) {
            $q->where('user1_id', $user1Id)->where('user2_id', $user2Id);
        })->orWhere(function ($q) use ($user1Id, $user2Id) {
            $q->where('user1_id', $user2Id)->where('user2_id', $user1Id);
        })->first();

        if (!$conversation) {
            $conversation = Conversation::create([
                'user1_id' => $user1Id,
                'user2_id' => $user2Id,
            ]);
        }

        return $conversation;
    }

    public function conversations()
    {
        $userId = auth()->id();

        $conversations = Conversation::forUser($userId)
            ->with(['user1', 'user2', 'lastMessage'])
            ->orderBy('last_message_at', 'desc')
            ->get()
            ->map(function ($conversation) use ($userId) {
                $conversation->other_user = $conversation->getOtherUser($userId);
                $conversation->unread_count = $conversation->getUnreadCount($userId);
                return $conversation;
            });

        return $this->successResponse(['conversations' => $conversations]);
    }

    public function unreadCount()
    {
        $count = Message::where('receiver_id', auth()->id())
            ->where('is_read', false)
            ->count();

        return $this->successResponse(['unread_count' => $count]);
    }

    public function conversation($userId)
    {
        $myId = auth()->id();

        $targetUser = User::find($userId);
        if (!$targetUser) {
            return $this->errorResponse('User not found.', 404);
        }

        $conversation = $this->findOrCreateConversation($myId, $userId);

        $messages = Message::where(function ($q) use ($myId, $userId) {
            $q->where('sender_id', $myId)->where('receiver_id', $userId);
        })->orWhere(function ($q) use ($myId, $userId) {
            $q->where('sender_id', $userId)->where('receiver_id', $myId);
        })->with('sender')->orderBy('created_at', 'asc')->get();

        return $this->successResponse([
            'conversation' => $conversation,
            'messages' => $messages,
            'other_user' => $targetUser,
        ]);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'receiver_id' => 'required|integer|exists:users,id',
            'content' => 'nullable|string|max:5000',
            'media' => 'nullable|file|mimes:jpeg,png,gif,mp4,mov|max:51200',
            'reply_to_id' => 'nullable|integer|exists:messages,id',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $senderId = auth()->id();
        $receiverId = $request->receiver_id;

        if ($senderId === (int) $receiverId) {
            return $this->errorResponse('You cannot message yourself.', 400);
        }

        $conversation = $this->findOrCreateConversation($senderId, $receiverId);

        if ($conversation->isBlockedFor($receiverId) || $conversation->isBlockedFor($senderId)) {
            return $this->errorResponse('Cannot send message in this conversation.', 403);
        }

        $mediaUrl = null;
        $mediaType = null;

        if ($request->hasFile('media')) {
            $file = $request->file('media');
            $path = $file->store('messages/' . date('Y/m/d'), 'public');
            $mediaUrl = \App\Support\MediaHelper::absoluteUrl($path);
            $mediaType = str_starts_with($file->getMimeType(), 'video') ? 'video' : 'image';
        }

        $message = Message::create([
            'sender_id' => $senderId,
            'receiver_id' => $receiverId,
            'conversation_id' => $conversation->id,
            'content' => $request->content,
            'media_url' => $mediaUrl,
            'media_type' => $mediaType,
            'reply_to_id' => $request->reply_to_id,
            'is_read' => false,
            'delivered_at' => now(),
        ]);

        $conversation->update([
            'last_message_id' => $message->id,
            'last_message_at' => now(),
        ]);

        Notification::create([
            'user_id' => $receiverId,
            'type' => 'message',
            'message' => auth()->user()->name . ' vous a envoyé un message.',
            'data' => json_encode(['message_id' => $message->id, 'sender_id' => $senderId]),
            'has_sound' => true,
        ]);

        return $this->successResponse([
            'message' => 'Message sent successfully.',
            'data' => $message->load('sender'),
        ], 201);
    }

    public function markAsRead($id)
    {
        $message = Message::where('receiver_id', auth()->id())->find($id);

        if (!$message) {
            return $this->errorResponse('Message not found.', 404);
        }

        $message->update(['is_read' => true, 'read_at' => now(), 'seen_at' => now()]);

        return $this->successResponse(['message' => 'Message marked as read.']);
    }

    public function markConversationAsRead($conversationId)
    {
        Message::where('conversation_id', $conversationId)
            ->where('receiver_id', auth()->id())
            ->where('is_read', false)
            ->update(['is_read' => true, 'read_at' => now(), 'seen_at' => now()]);

        return $this->successResponse(['message' => 'Conversation marked as read.']);
    }

    public function destroy($id)
    {
        $userId = auth()->id();
        $message = Message::where(function ($q) use ($userId) {
            $q->where('sender_id', $userId)->orWhere('receiver_id', $userId);
        })->find($id);

        if (!$message) {
            return $this->errorResponse('Message not found.', 404);
        }

        if ($message->sender_id === $userId) {
            $message->update(['is_deleted_by_sender' => true]);
        } else {
            $message->update(['is_deleted_by_receiver' => true]);
        }

        if ($message->is_deleted_by_sender && $message->is_deleted_by_receiver) {
            $message->delete();
        }

        return $this->successResponse(['message' => 'Message deleted successfully.']);
    }

    public function blockUser(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'user_id' => 'required|integer|exists:users,id',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $myId = auth()->id();
        $conversation = $this->findOrCreateConversation($myId, $request->user_id);

        if ($conversation->user1_id === $myId) {
            $conversation->update(['blocked_by_user1' => true]);
        } else {
            $conversation->update(['blocked_by_user2' => true]);
        }

        return $this->successResponse(['message' => 'User blocked in this conversation.']);
    }

    public function unblockUser(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'user_id' => 'required|integer|exists:users,id',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $myId = auth()->id();
        $conversation = $this->findOrCreateConversation($myId, $request->user_id);

        if ($conversation->user1_id === $myId) {
            $conversation->update(['blocked_by_user1' => false]);
        } else {
            $conversation->update(['blocked_by_user2' => false]);
        }

        return $this->successResponse(['message' => 'User unblocked in this conversation.']);
    }

    public function searchUsers(Request $request)
    {
        $q = $request->input('q', '');
        $myId = auth()->id();

        $query = User::where('id', '!=', $myId)
            ->where('is_blocked', false)
            ->select('id', 'name', 'profile_photo', 'is_premium', 'is_verified');

        if (strlen($q) >= 2) {
            $query->where(function ($qr) use ($q) {
                $qr->where('name', 'ilike', "%{$q}%")
                    ->orWhere('email', 'ilike', "%{$q}%");
            });
        }

        $users = $query->limit(30)->get();

        return $this->successResponse(['users' => $users]);
    }
}
