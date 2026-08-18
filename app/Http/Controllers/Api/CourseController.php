<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Course;
use App\Models\CourseEnrollment;
use App\Models\CourseReview;
use App\Models\LessonProgress;
use App\Models\Transaction;
use App\Services\CertificateService;
use App\Services\PaymentService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class CourseController extends Controller
{
    use \App\Traits\ApiResponseTrait;

    protected $certificateService;

    public function __construct(CertificateService $certificateService)
    {
        $this->certificateService = $certificateService;
    }

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

        $sort = $request->input('sort', 'recent');
        switch ($sort) {
            case 'popular':
                $query->orderBy('students_count', 'desc');
                break;
            case 'rating':
                $query->orderBy('rating', 'desc');
                break;
            case 'price_asc':
                $query->orderBy('price', 'asc');
                break;
            case 'price_desc':
                $query->orderBy('price', 'desc');
                break;
            default:
                $query->orderBy('created_at', 'desc');
        }

        $limit = $request->input('limit', 20);
        $page = $request->input('page', 1);
        $offset = ($page - 1) * $limit;

        $total = (clone $query)->count();
        $courses = $query->with('instructor')
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
            return $this->errorResponse('Formation non trouvée.', 404);
        }

        return $this->successResponse(['course' => $course]);
    }

    public function enroll($id)
    {
        $course = Course::published()->find($id);

        if (!$course) {
            return $this->errorResponse('Formation non trouvée.', 404);
        }

        $userId = auth()->id();

        $existing = CourseEnrollment::where('course_id', $id)->where('user_id', $userId)->first();
        if ($existing) {
            return $this->errorResponse('Vous êtes déjà inscrit à cette formation.', 400);
        }

        if (!$course->is_free) {
            $user = auth()->user();

            if ($user->boost_balance >= $course->price) {
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
                    'metadata' => json_encode(['course_id' => $course->id]),
                ]);

                $enrollment = CourseEnrollment::create([
                    'course_id' => $id,
                    'user_id' => $userId,
                    'progress' => 0,
                    'is_completed' => false,
                    'last_accessed_at' => now(),
                ]);

                $course->incrementStudents();

                return $this->successResponse([
                    'message' => 'Inscription réussie.',
                    'enrollment' => $enrollment,
                ], 201);
            }

            $paymentService = app(PaymentService::class);
            $result = $paymentService->coursePayment(
                $userId,
                $course->id,
                $course->price,
                $user->email
            );

            return $this->successResponse([
                'message' => 'Redirection vers le paiement.',
                'payment_url' => $result['payment_url'],
                'transaction_id' => $result['transaction']['id'] ?? null,
                'requires_payment' => true,
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
            'message' => 'Inscription réussie.',
            'enrollment' => $enrollment,
        ], 201);
    }

    public function confirmEnrollment($id)
    {
        $course = Course::published()->find($id);
        if (!$course) {
            return $this->errorResponse('Formation non trouvée.', 404);
        }

        $userId = auth()->id();
        $existing = CourseEnrollment::where('course_id', $id)->where('user_id', $userId)->first();
        if ($existing) {
            return $this->successResponse(['enrollment' => $existing, 'message' => 'Déjà inscrit.']);
        }

        $pendingTx = Transaction::where('user_id', $userId)
            ->where('type', 'course_payment')
            ->where('status', 'completed')
            ->where("metadata->>'course_id'", (string) $id)
            ->latest()
            ->first();

        if (!$pendingTx) {
            return $this->errorResponse('Paiement non confirmé. Veuillez réessayer.', 400);
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
            'message' => 'Inscription réussie.',
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
            return $this->errorResponse('Vous n\'êtes pas inscrit à cette formation.', 403);
        }

        $progress = LessonProgress::updateProgress(auth()->id(), $lessonId, $request->position, $request->duration);

        $enrollment->update([
            'last_lesson_id' => $lessonId,
            'last_accessed_at' => now(),
        ]);

        $enrollment->refresh();

        $certificate = null;
        if ($enrollment->is_completed && $enrollment->progress >= 100) {
            $certificate = $this->certificateService->generateCertificate($enrollment);
        }

        return $this->successResponse([
            'message' => 'Progression mise à jour.',
            'progress' => $progress,
            'course_progress' => $enrollment->progress,
            'is_completed' => $enrollment->is_completed,
            'certificate' => $certificate,
        ]);
    }

    public function addReview(Request $request, $id)
    {
        $course = Course::find($id);

        if (!$course) {
            return $this->errorResponse('Formation non trouvée.', 404);
        }

        $enrollment = CourseEnrollment::where('course_id', $id)
            ->where('user_id', auth()->id())
            ->first();

        if (!$enrollment) {
            return $this->errorResponse('Vous devez être inscrit pour laisser un avis.', 403);
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
            'message' => 'Avis ajouté.',
            'review' => $review->load('user'),
        ], 201);
    }

    public function certificate($id)
    {
        $enrollment = CourseEnrollment::where('course_id', $id)
            ->where('user_id', auth()->id())
            ->first();

        if (!$enrollment) {
            return $this->errorResponse('Inscription non trouvée.', 404);
        }

        if ($enrollment->progress < 100) {
            return $this->errorResponse('Vous devez terminer la formation pour obtenir le certificat.', 400);
        }

        $certificate = $this->certificateService->getCertificate($enrollment);

        if (!$certificate) {
            return $this->errorResponse('Erreur lors de la génération du certificat.', 500);
        }

        return $this->successResponse([
            'certificate' => $certificate,
        ]);
    }
}
