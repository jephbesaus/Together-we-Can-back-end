<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Course;
use App\Models\CourseEnrollment;
use App\Models\CourseReview;
use App\Models\LessonProgress;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class CourseController extends Controller
{
    use \App\Traits\ApiResponseTrait;

    public function index(Request $request)
    {
        $query = Course::published();

        if ($request->filled('category')) {
            $query->where('category', $request->category);
        }

        if ($request->filled('level')) {
            $query->where('level', $request->level);
        }

        if ($request->filled('q')) {
            $query->search($request->q);
        }

        if ($request->boolean('free_only')) {
            $query->free();
        }

        $limit = $request->input('limit', 20);
        $page = $request->input('page', 1);
        $offset = ($page - 1) * $limit;

        $total = (clone $query)->count();
        $courses = $query->with('instructor')
            ->orderBy('created_at', 'desc')
            ->skip($offset)
            ->take($limit)
            ->get();

        return $this->successResponse([
            'courses' => $courses,
            'has_more' => ($offset + $courses->count()) < $total,
            'total' => $total,
            'page' => $page,
        ]);
    }

    public function categories()
    {
        $categories = Course::published()
            ->whereNotNull('category')
            ->distinct()
            ->pluck('category');

        return $this->successResponse(['categories' => $categories]);
    }

    public function show($id)
    {
        $course = Course::with(['instructor', 'sections.lessons', 'reviews.user'])
            ->published()
            ->find($id);

        if (!$course) {
            return $this->errorResponse('Course not found.', 404);
        }

        return $this->successResponse(['course' => $course]);
    }

    public function enroll($id)
    {
        $course = Course::published()->find($id);

        if (!$course) {
            return $this->errorResponse('Course not found.', 404);
        }

        $userId = auth()->id();

        $existing = CourseEnrollment::where('course_id', $id)->where('user_id', $userId)->first();
        if ($existing) {
            return $this->errorResponse('You are already enrolled in this course.', 400);
        }

        if (!$course->is_free) {
            $user = auth()->user();
            if ($user->boost_balance < $course->price) {
                return $this->errorResponse('Insufficient balance.', 400);
            }
            $user->decrement('boost_balance', $course->price);

            Transaction::create([
                'user_id' => $userId,
                'type' => 'course_payment',
                'amount' => $course->price,
                'reference' => 'CRS-' . strtoupper(uniqid()),
                'payment_method' => 'wallet',
                'status' => 'completed',
                'description' => 'Achat formation : ' . $course->title,
                'completed_at' => now(),
            ]);
        }

        $enrollment = CourseEnrollment::create([
            'course_id' => $id,
            'user_id' => $userId,
            'progress' => 0,
            'is_completed' => false,
            'last_accessed_at' => now(),
        ]);

        $course->incrementStudents();

        return $this->successResponse([
            'message' => 'Enrolled successfully.',
            'enrollment' => $enrollment,
        ], 201);
    }

    public function myCourses()
    {
        $enrollments = CourseEnrollment::where('user_id', auth()->id())
            ->with('course.instructor')
            ->orderBy('last_accessed_at', 'desc')
            ->get();

        return $this->successResponse(['enrollments' => $enrollments]);
    }

    public function updateProgress(Request $request, $courseId, $lessonId)
    {
        $validator = Validator::make($request->all(), [
            'position' => 'required|integer|min:0',
            'duration' => 'required|integer|min:0',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $enrollment = CourseEnrollment::where('course_id', $courseId)
            ->where('user_id', auth()->id())
            ->first();

        if (!$enrollment) {
            return $this->errorResponse('You are not enrolled in this course.', 403);
        }

        $progress = LessonProgress::updateProgress(auth()->id(), $lessonId, $request->position, $request->duration);

        $enrollment->update([
            'last_lesson_id' => $lessonId,
            'last_accessed_at' => now(),
        ]);

        return $this->successResponse([
            'message' => 'Progress updated.',
            'progress' => $progress,
            'course_progress' => $enrollment->fresh()->progress,
        ]);
    }

    public function addReview(Request $request, $id)
    {
        $course = Course::find($id);

        if (!$course) {
            return $this->errorResponse('Course not found.', 404);
        }

        $validator = Validator::make($request->all(), [
            'rating' => 'required|integer|min:1|max:5',
            'comment' => 'nullable|string|max:1000',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $review = CourseReview::updateOrCreate(
            ['course_id' => $id, 'user_id' => auth()->id()],
            ['rating' => $request->rating, 'comment' => $request->comment]
        );

        $course->updateRating();

        return $this->successResponse([
            'message' => 'Review added successfully.',
            'review' => $review->load('user'),
        ], 201);
    }
}
