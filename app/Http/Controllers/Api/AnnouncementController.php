<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Announcement;
use App\Models\User;
use App\Models\Notification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Storage;

class AnnouncementController extends Controller
{
    use \App\Traits\ApiResponseTrait;

    public function index(Request $request)
    {
        $limit = $request->input('limit', 20);
        $page = $request->input('page', 1);
        $offset = ($page - 1) * $limit;

        $query = Announcement::active()->orderBy('is_pinned', 'desc')->orderBy('created_at', 'desc');
        $total = (clone $query)->count();
        $announcements = $query->skip($offset)->take($limit)->get();

        return $this->successResponse([
            'announcements' => $announcements,
            'has_more' => ($offset + $announcements->count()) < $total,
            'total' => $total,
            'page' => $page,
        ]);
    }

    public function show($id)
    {
        $announcement = Announcement::active()->find($id);

        if (!$announcement) {
            return $this->errorResponse('Announcement not found.', 404);
        }

        return $this->successResponse(['announcement' => $announcement]);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'image' => 'nullable|file|mimes:jpeg,png,gif|max:5120',
            'is_pinned' => 'boolean',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $imageUrl = null;
        if ($request->hasFile('image')) {
            $path = $request->file('image')->store('announcements', 'public');
            $imageUrl = Storage::url($path);
        }

        $announcement = Announcement::create([
            'title' => $request->title,
            'content' => $request->content,
            'image_url' => $imageUrl,
            'is_pinned' => $request->boolean('is_pinned'),
            'created_by' => auth()->id(),
        ]);

        if ($request->boolean('notify_all')) {
            User::chunk(200, function ($users) use ($announcement) {
                foreach ($users as $user) {
                    Notification::create([
                        'user_id' => $user->id,
                        'type' => 'announcement',
                        'message' => $announcement->title,
                        'data' => json_encode(['announcement_id' => $announcement->id]),
                        'has_sound' => true,
                    ]);
                }
            });
        }

        return $this->successResponse([
            'message' => 'Announcement created successfully.',
            'announcement' => $announcement,
        ], 201);
    }

    public function update(Request $request, $id)
    {
        $announcement = Announcement::find($id);

        if (!$announcement) {
            return $this->errorResponse('Announcement not found.', 404);
        }

        $validator = Validator::make($request->all(), [
            'title' => 'sometimes|string|max:255',
            'content' => 'sometimes|string',
            'is_pinned' => 'boolean',
            'is_active' => 'boolean',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $announcement->update($request->only(['title', 'content', 'is_pinned', 'is_active']));

        return $this->successResponse([
            'message' => 'Announcement updated successfully.',
            'announcement' => $announcement->fresh(),
        ]);
    }

    public function destroy($id)
    {
        $announcement = Announcement::find($id);

        if (!$announcement) {
            return $this->errorResponse('Announcement not found.', 404);
        }

        $announcement->delete();

        return $this->successResponse(['message' => 'Announcement deleted successfully.']);
    }
}
