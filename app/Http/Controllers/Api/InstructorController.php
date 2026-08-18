<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Course;
use App\Models\CourseSection;
use App\Models\CourseLesson;
use App\Models\CourseEnrollment;
use App\Models\Transaction;
use App\Models\Notification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Storage;

class InstructorController extends Controller
{
    use \App\Traits\ApiResponseTrait;

    public function dashboard()
    {
        $userId = auth()->id();

        $courses = Course::where('instructor_id', $userId);
        $totalCourses = $courses->count();
        $publishedCourses = (clone $courses)->approved()->count();
        $totalStudents = (clone $courses)->sum('students_count');
        $totalRevenue = Transaction::where('type', 'course_payment')
            ->whereIn('course_id', $courses->pluck('id'))
            ->where('status', 'completed')
            ->sum('amount');
        $averageRating = (clone $courses)->where('reviews_count', '>', 0)->avg('rating') ?? 0;

        $recentEnrollments = CourseEnrollment::whereIn('course_id', $courses->pluck('id'))
            ->with('user', 'course')
            ->orderBy('created_at', 'desc')
            ->limit(10)
            ->get();

        $courseStats = Course::where('instructor_id', $userId)
            ->select('id', 'title', 'students_count', 'rating', 'reviews_count', 'status')
            ->get();

        return $this->successResponse([
            'stats' => [
                'total_courses' => $totalCourses,
                'published_courses' => $publishedCourses,
                'total_students' => $totalStudents,
                'total_revenue' => $totalRevenue,
                'average_rating' => round($averageRating, 1),
            ],
            'recent_enrollments' => $recentEnrollments,
            'course_stats' => $courseStats,
        ]);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'title' => 'required|string|max:255',
            'description' => 'nullable|string|max:10000',
            'cover_image' => 'nullable|image|mimes:jpeg,png,jpg|max:5120',
            'category' => 'nullable|string|max:100',
            'level' => 'required|in:beginner,intermediate,advanced,expert',
            'price' => 'required|numeric|min:0',
            'is_free' => 'boolean',
            'what_you_will_learn' => 'nullable|array',
            'what_you_will_learn.*' => 'string|max:500',
            'requirements' => 'nullable|array',
            'requirements.*' => 'string|max:500',
            'target_audience' => 'nullable|array',
            'target_audience.*' => 'string|max:500',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $coverPath = null;
        if ($request->hasFile('cover_image')) {
            $coverPath = $request->file('cover_image')->store('courses/covers', 'public');
        }

        $course = Course::create([
            'instructor_id' => auth()->id(),
            'title' => $request->title,
            'description' => $request->description,
            'cover_image' => $coverPath,
            'category' => $request->category,
            'level' => $request->level,
            'price' => $request->price,
            'is_free' => $request->boolean('is_free', $request->price == 0),
            'what_you_will_learn' => $request->what_you_will_learn,
            'requirements' => $request->requirements,
            'target_audience' => $request->target_audience,
            'status' => Course::STATUS_DRAFT,
            'is_published' => false,
        ]);

        return $this->successResponse([
            'message' => 'Formation créée avec succès.',
            'course' => $course->load('sections.lessons'),
        ], 201);
    }

    public function update(Request $request, $id)
    {
        $course = Course::where('instructor_id', auth()->id())->find($id);

        if (!$course) {
            return $this->errorResponse('Formation non trouvée.', 404);
        }

        if (in_array($course->status, [Course::STATUS_APPROVED])) {
            return $this->errorResponse('Impossible de modifier une formation approuvée.', 400);
        }

        $validator = Validator::make($request->all(), [
            'title' => 'sometimes|string|max:255',
            'description' => 'nullable|string|max:10000',
            'cover_image' => 'nullable|image|mimes:jpeg,png,jpg|max:5120',
            'category' => 'nullable|string|max:100',
            'level' => 'sometimes|in:beginner,intermediate,advanced,expert',
            'price' => 'sometimes|numeric|min:0',
            'is_free' => 'boolean',
            'what_you_will_learn' => 'nullable|array',
            'requirements' => 'nullable|array',
            'target_audience' => 'nullable|array',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $data = $request->only(['title', 'description', 'category', 'level', 'price', 'is_free', 'what_you_will_learn', 'requirements', 'target_audience']);

        if ($request->hasFile('cover_image')) {
            if ($course->cover_image) {
                Storage::disk('public')->delete($course->cover_image);
            }
            $data['cover_image'] = $request->file('cover_image')->store('courses/covers', 'public');
        }

        $data['status'] = Course::STATUS_DRAFT;
        $data['is_published'] = false;

        $course->update($data);

        return $this->successResponse([
            'message' => 'Formation mise à jour.',
            'course' => $course->fresh()->load('sections.lessons'),
        ]);
    }

    public function destroy($id)
    {
        $course = Course::where('instructor_id', auth()->id())->find($id);

        if (!$course) {
            return $this->errorResponse('Formation non trouvée.', 404);
        }

        $hasEnrollments = CourseEnrollment::where('course_id', $id)->exists();

        if ($hasEnrollments) {
            $course->update([
                'status' => Course::STATUS_REJECTED,
                'rejection_reason' => 'Désactivé par le formateur',
                'is_published' => false,
            ]);
            return $this->successResponse(['message' => 'Formation désactivée (des étudiants y sont inscrits).']);
        }

        $course->delete();
        return $this->successResponse(['message' => 'Formation supprimée.']);
    }

    public function addSection(Request $request, $courseId)
    {
        $course = Course::where('instructor_id', auth()->id())->find($courseId);

        if (!$course) {
            return $this->errorResponse('Formation non trouvée.', 404);
        }

        $validator = Validator::make($request->all(), [
            'title' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $maxOrder = CourseSection::where('course_id', $courseId)->max('order_position') ?? 0;

        $section = CourseSection::create([
            'course_id' => $courseId,
            'title' => $request->title,
            'description' => $request->description,
            'order_position' => $maxOrder + 1,
        ]);

        return $this->successResponse([
            'message' => 'Section ajoutée.',
            'section' => $section,
        ], 201);
    }

    public function updateSection(Request $request, $courseId, $sectionId)
    {
        $course = Course::where('instructor_id', auth()->id())->find($courseId);

        if (!$course) {
            return $this->errorResponse('Formation non trouvée.', 404);
        }

        $section = CourseSection::where('course_id', $courseId)->find($sectionId);

        if (!$section) {
            return $this->errorResponse('Section non trouvée.', 404);
        }

        $validator = Validator::make($request->all(), [
            'title' => 'sometimes|string|max:255',
            'description' => 'nullable|string|max:1000',
            'order_position' => 'sometimes|integer|min:1',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $section->update($request->only(['title', 'description', 'order_position']));

        return $this->successResponse([
            'message' => 'Section mise à jour.',
            'section' => $section->fresh(),
        ]);
    }

    public function deleteSection(Request $request, $courseId, $sectionId)
    {
        $course = Course::where('instructor_id', auth()->id())->find($courseId);

        if (!$course) {
            return $this->errorResponse('Formation non trouvée.', 404);
        }

        $section = CourseSection::where('course_id', $courseId)->find($sectionId);

        if (!$section) {
            return $this->errorResponse('Section non trouvée.', 404);
        }

        $section->lessons()->delete();
        $section->delete();

        return $this->successResponse(['message' => 'Section supprimée.']);
    }

    public function addLesson(Request $request, $courseId, $sectionId)
    {
        try {
        $course = Course::where('instructor_id', auth()->id())->find($courseId);

        if (!$course) {
            return $this->errorResponse('Formation non trouvée.', 404);
        }

        $section = CourseSection::where('course_id', $courseId)->find($sectionId);

        if (!$section) {
            return $this->errorResponse('Section non trouvée.', 404);
        }

        $validator = Validator::make($request->all(), [
            'title' => 'required|string|max:255',
            'description' => 'nullable|string|max:2000',
            'content' => 'nullable|string',
            'type' => 'required|in:video,text,document,quiz',
            'video' => 'nullable|file|mimes:mp4,mov,avi|max:512000',
            'video_url' => 'nullable|string|max:500',
            'documents' => 'nullable|array',
            'documents.*' => 'file|mimes:pdf,doc,docx,xls,xlsx|max:10240',
            'duration' => 'nullable|integer|min:0',
            'is_free_preview' => 'boolean',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $maxOrder = CourseLesson::where('course_id', $courseId)->where('section_id', $sectionId)->max('order_position') ?? 0;

        $videoUrl = $request->video_url;
        if ($request->hasFile('video')) {
            $videoPath = $request->file('video')->store('courses/videos', 'public');
            $videoUrl = Storage::url($videoPath);
        }

        $documents = null;
        if ($request->hasFile('documents')) {
            $docPaths = [];
            foreach ($request->file('documents') as $doc) {
                $docPaths[] = $doc->store('courses/documents', 'public');
            }
            $documents = $docPaths;
        }

        $lesson = CourseLesson::create([
            'course_id' => $courseId,
            'section_id' => $sectionId,
            'title' => $request->title,
            'description' => $request->description,
            'content' => $request->content,
            'type' => $request->type,
            'video_url' => $videoUrl,
            'video_duration' => $request->duration,
            'documents' => $documents,
            'order_position' => $maxOrder + 1,
            'is_free_preview' => $request->boolean('is_free_preview', false),
            'is_published' => true,
        ]);

        try {
            $this->recalculateCourseDuration($courseId);
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::error('recalculateCourseDuration failed: ' . $e->getMessage());
        }

        return $this->successResponse([
            'message' => 'Leçon ajoutée.',
            'lesson' => $lesson,
        ], 201);
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::error('addLesson error: ' . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return $this->errorResponse('Erreur serveur: ' . $e->getMessage(), 500);
        }
    }

    public function updateLesson(Request $request, $courseId, $lessonId)
    {
        $course = Course::where('instructor_id', auth()->id())->find($courseId);

        if (!$course) {
            return $this->errorResponse('Formation non trouvée.', 404);
        }

        $lesson = CourseLesson::where('course_id', $courseId)->find($lessonId);

        if (!$lesson) {
            return $this->errorResponse('Leçon non trouvée.', 404);
        }

        $validator = Validator::make($request->all(), [
            'title' => 'sometimes|string|max:255',
            'description' => 'nullable|string|max:2000',
            'content' => 'nullable|string',
            'type' => 'sometimes|in:video,text,document,quiz',
            'video' => 'nullable|file|mimes:mp4,mov,avi|max:512000',
            'video_url' => 'nullable|string|max:500',
            'documents' => 'nullable|array',
            'duration' => 'nullable|integer|min:0',
            'is_free_preview' => 'boolean',
            'is_published' => 'boolean',
            'order_position' => 'sometimes|integer|min:1',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $data = $request->only(['title', 'description', 'content', 'type', 'video_url', 'is_free_preview', 'is_published', 'order_position', 'duration']);

        if ($request->hasFile('video')) {
            if ($lesson->video_url) {
                $oldPath = str_replace('/storage/', 'public/', $lesson->video_url);
                Storage::disk('public')->delete($oldPath);
            }
            $videoPath = $request->file('video')->store('courses/videos', 'public');
            $data['video_url'] = Storage::url($videoPath);
        }

        if ($request->hasFile('documents')) {
            $docPaths = [];
            foreach ($request->file('documents') as $doc) {
                $docPaths[] = $doc->store('courses/documents', 'public');
            }
            $data['documents'] = $docPaths;
        }

        $lesson->update($data);

        $this->recalculateCourseDuration($courseId);

        return $this->successResponse([
            'message' => 'Leçon mise à jour.',
            'lesson' => $lesson->fresh(),
        ]);
    }

    public function deleteLesson(Request $request, $courseId, $lessonId)
    {
        $course = Course::where('instructor_id', auth()->id())->find($courseId);

        if (!$course) {
            return $this->errorResponse('Formation non trouvée.', 404);
        }

        $lesson = CourseLesson::where('course_id', $courseId)->find($lessonId);

        if (!$lesson) {
            return $this->errorResponse('Leçon non trouvée.', 404);
        }

        $lesson->delete();

        $this->recalculateCourseDuration($courseId);
        $this->recalculateLessonsCount($courseId);

        return $this->successResponse(['message' => 'Leçon supprimée.']);
    }

    public function students(Request $request, $courseId)
    {
        $course = Course::where('instructor_id', auth()->id())->find($courseId);

        if (!$course) {
            return $this->errorResponse('Formation non trouvée.', 404);
        }

        $limit = $request->input('limit', 20);
        $page = $request->input('page', 1);
        $offset = ($page - 1) * $limit;

        $query = CourseEnrollment::where('course_id', $courseId)->with('user');
        $total = (clone $query)->count();
        $enrollments = $query->orderBy('created_at', 'desc')->skip($offset)->take($limit)->get();

        return $this->successResponse([
            'students' => $enrollments,
            'has_more' => ($offset + $enrollments->count()) < $total,
            'total' => $total,
            'page' => $page,
        ]);
    }

    public function submit(Request $request, $id)
    {
        $course = Course::where('instructor_id', auth()->id())->find($id);

        if (!$course) {
            return $this->errorResponse('Formation non trouvée.', 404);
        }

        if ($course->status === Course::STATUS_APPROVED) {
            return $this->errorResponse('Cette formation est déjà approuvée.', 400);
        }

        if ($course->status === Course::STATUS_SUBMITTED) {
            return $this->errorResponse('Cette formation est déjà en attente de validation.', 400);
        }

        $lessonsCount = CourseLesson::where('course_id', $id)->count();
        if ($lessonsCount === 0) {
            return $this->errorResponse('La formation doit contenir au moins une leçon.', 400);
        }

        $sectionsCount = CourseSection::where('course_id', $id)->count();
        if ($sectionsCount === 0) {
            return $this->errorResponse('La formation doit contenir au moins une section.', 400);
        }

        $course->update([
            'status' => Course::STATUS_SUBMITTED,
            'rejection_reason' => null,
        ]);

        Notification::create([
            'user_id' => auth()->id(),
            'type' => 'course_submitted',
            'message' => 'Votre formation "' . $course->title . '" a été soumise pour validation.',
            'has_sound' => true,
        ]);

        return $this->successResponse([
            'message' => 'Formation soumise pour validation.',
            'course' => $course->fresh(),
        ]);
    }

    private function recalculateCourseDuration($courseId)
    {
        $totalDuration = CourseLesson::where('course_id', $courseId)
            ->where('is_published', true)
            ->sum('video_duration');

        Course::where('id', $courseId)->update(['duration_minutes' => (int) ($totalDuration / 60)]);
    }

    private function recalculateLessonsCount($courseId)
    {
        $count = CourseLesson::where('course_id', $courseId)->count();
        Course::where('id', $courseId)->update(['lessons_count' => $count]);
    }
}
