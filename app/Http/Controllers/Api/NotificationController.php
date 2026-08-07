<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class NotificationController extends Controller
{
    use \App\Traits\ApiResponseTrait;

    public function index(Request $request)
    {
        $limit = $request->input('limit', 30);
        $page = $request->input('page', 1);
        $offset = ($page - 1) * $limit;

        $baseQuery = Notification::where('user_id', auth()->id());
        $total = (clone $baseQuery)->count();

        $notifications = $baseQuery
            ->orderBy('created_at', 'desc')
            ->skip($offset)
            ->take($limit)
            ->get();

        return $this->successResponse([
            'notifications' => $notifications,
            'has_more' => ($offset + $notifications->count()) < $total,
            'total' => $total,
            'page' => $page,
        ]);
    }

    public function unreadCount()
    {
        $count = Notification::where('user_id', auth()->id())->unread()->count();

        return $this->successResponse(['unread_count' => $count]);
    }

    public function markAsRead($id)
    {
        $notification = Notification::where('user_id', auth()->id())->find($id);

        if (!$notification) {
            return $this->errorResponse('Notification not found.', 404);
        }

        $notification->update(['is_read' => true]);

        return $this->successResponse(['message' => 'Notification marked as read.']);
    }

    public function markAllAsRead()
    {
        Notification::where('user_id', auth()->id())->unread()->update(['is_read' => true]);

        return $this->successResponse(['message' => 'All notifications marked as read.']);
    }

    public function destroy($id)
    {
        $notification = Notification::where('user_id', auth()->id())->find($id);

        if (!$notification) {
            return $this->errorResponse('Notification not found.', 404);
        }

        $notification->delete();

        return $this->successResponse(['message' => 'Notification deleted successfully.']);
    }

    public function updateFcmToken(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'device_token' => 'required|string',
            'device_platform' => 'nullable|string|in:android,ios,web',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        auth()->user()->update([
            'device_token' => $request->device_token,
            'device_platform' => $request->device_platform,
        ]);

        return $this->successResponse(['message' => 'Device token updated.']);
    }

    public function removeFcmToken()
    {
        auth()->user()->update(['device_token' => null]);

        return $this->successResponse(['message' => 'Device token removed.']);
    }
}
