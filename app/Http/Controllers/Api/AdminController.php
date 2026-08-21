<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Post;
use App\Models\Product;
use App\Models\BoostOrder;
use App\Models\Course;
use App\Models\Report;
use App\Models\Notification;
use App\Models\Transaction;
use App\Services\FullSMMService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;

class AdminController extends Controller
{
    use \App\Traits\ApiResponseTrait;

    protected $fullSMM;

    public function __construct(FullSMMService $fullSMM)
    {
        $this->fullSMM = $fullSMM;
    }

    private function paginateQuery($query, Request $request, $perPage = 30)
    {
        $limit = $request->input('limit', $perPage);
        $page = $request->input('page', 1);
        $offset = ($page - 1) * $limit;

        $total = (clone $query)->count();
        $items = $query->skip($offset)->take($limit)->get();

        return [
            'items' => $items,
            'has_more' => ($offset + $items->count()) < $total,
            'total' => $total,
            'page' => $page,
        ];
    }

    public function activate(Request $request)
    {
        $user = auth()->user();

        if ($user->email !== config('admin.email')) {
            return $this->errorResponse('Ce compte n\'est pas autorisé à accéder à l\'administration.', 403);
        }

        \App\Models\User::where('id', $user->id)->update([
            'is_admin_activated' => true,
            'role' => 'admin',
        ]);

        $user->refresh();

        return $this->successResponse([
            'message' => 'Accès administrateur activé avec succès.',
            'is_admin_activated' => true,
        ]);
    }

    public function dashboard()
    {
        return $this->successResponse([
            'stats' => [
                'users' => [
                    'total' => User::count(),
                    'new_today' => User::whereDate('created_at', today())->count(),
                    'premium_requests' => User::where('premium_requested', true)->count(),
                ],
                'content' => [
                    'posts' => Post::count(),
                    'reported' => Post::where('is_reported', true)->count(),
                ],
                'marketplace' => [
                    'products' => Product::count(),
                    'pending_approval' => Product::where('is_approved', false)->count(),
                ],
                'boost' => [
                    'orders' => BoostOrder::count(),
                    'orders_pending' => BoostOrder::where('status', 'pending')->count(),
                ],
                'courses' => [
                    'total' => Course::count(),
                    'students' => Course::sum('students_count'),
                ],
                'financial' => [
                    'today_revenue' => Transaction::whereDate('created_at', today())
                        ->where('status', 'completed')
                        ->whereIn('type', ['deposit', 'boost_payment', 'marketplace_payment', 'course_payment'])
                        ->sum('amount'),
                ],
                'reports' => [
                    'pending' => Report::where('status', 'pending')->count(),
                    'resolved' => Report::where('status', 'resolved')->count(),
                ],
            ],
        ]);
    }

    public function users(Request $request)
    {
        try {
            $query = User::query();

            if ($request->filled('q')) {
                $query->where('name', 'LIKE', "%{$request->q}%")
                    ->orWhere('email', 'LIKE', "%{$request->q}%");
            }

            if ($request->filled('status')) {
                if ($request->status === 'blocked') $query->where('is_blocked', true);
                if ($request->status === 'premium') $query->where('is_premium', true);
                if ($request->status === 'verified') $query->where('is_verified', true);
            }

            $result = $this->paginateQuery($query->orderBy('created_at', 'desc'), $request);

            return $this->successResponse([
                'users' => $result['items'],
                'has_more' => $result['has_more'],
                'total' => $result['total'],
                'page' => $result['page'],
            ]);
        } catch (\Throwable $e) {
            Log::error('Admin users list failed', [
                'message' => $e->getMessage(),
                'file' => $e->getFile() . ':' . $e->getLine(),
            ]);

            return $this->errorResponse($e->getMessage(), 500);
        }
    }

    public function userDetails($id)
    {
        $user = User::find($id);

        if (!$user) {
            return $this->errorResponse('User not found.', 404);
        }

        return $this->successResponse([
            'user' => $user,
            'posts_count' => $user->posts()->count(),
            'orders_count' => $user->orders()->count(),
            'transactions_count' => $user->transactions()->count(),
        ]);
    }

    public function blockUser($id)
    {
        $user = User::find($id);

        if (!$user) {
            return $this->errorResponse('User not found.', 404);
        }

        $user->update(['is_blocked' => true]);

        Notification::create([
            'user_id' => $user->id,
            'type' => 'account_blocked',
            'message' => 'Votre compte a été bloqué par l\'administration.',
            'has_sound' => true,
        ]);

        return $this->successResponse(['message' => 'User blocked successfully.']);
    }

    public function unblockUser($id)
    {
        $user = User::find($id);

        if (!$user) {
            return $this->errorResponse('User not found.', 404);
        }

        $user->update(['is_blocked' => false]);

        Notification::create([
            'user_id' => $user->id,
            'type' => 'account_unblocked',
            'message' => 'Votre compte a été débloqué.',
            'has_sound' => true,
        ]);

        return $this->successResponse(['message' => 'User unblocked successfully.']);
    }

    public function updateBalance(Request $request, $id)
    {
        $user = User::find($id);

        if (!$user) {
            return $this->errorResponse('User not found.', 404);
        }

        $validator = Validator::make($request->all(), [
            'amount' => 'required|numeric|min:0|max:999999999',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $amount = round((float) $request->amount, 2);
        $oldBalance = (float) $user->boost_balance;
        $difference = round($amount - $oldBalance, 2);

        DB::beginTransaction();
        try {
            $user->boost_balance = $amount;
            $user->save();

            if ($difference != 0) {
                Transaction::create([
                    'user_id' => $user->id,
                    'type' => $difference > 0 ? Transaction::TYPE_DEPOSIT : Transaction::TYPE_WITHDRAWAL,
                    'amount' => abs($difference),
                    'reference' => 'ADM-ADJ-' . strtoupper(\Illuminate\Support\Str::random(12)),
                    'payment_method' => 'admin_adjustment',
                    'status' => Transaction::STATUS_COMPLETED,
                    'description' => 'Solde défini à ' . number_format($amount, 0, ',', '.') . ' CDF par l\'administration',
                    'metadata' => [
                        'admin_id' => auth()->id(),
                        'previous_balance' => $oldBalance,
                        'new_balance' => $amount,
                        'adjusted_at' => now()->toISOString(),
                    ],
                    'completed_at' => now(),
                ]);
            }

            DB::commit();
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Admin balance update failed: ' . $e->getMessage());
            return $this->errorResponse('Erreur lors de la mise à jour du solde.', 500);
        }

        Notification::create([
            'user_id' => $user->id,
            'type' => 'balance_updated',
            'message' => 'Votre solde a été mis à jour : ' . number_format($amount, 0, ',', '.') . ' CDF.',
            'has_sound' => true,
        ]);

        Log::info('Admin updated user balance', [
            'admin_id' => auth()->id(),
            'user_id' => $user->id,
            'old_balance' => $oldBalance,
            'new_balance' => $amount,
        ]);

        return $this->successResponse([
            'message' => 'Solde mis à jour : ' . number_format($amount, 0, ',', '.') . ' CDF.',
            'user' => $user->fresh(),
        ]);
    }

    public function deleteUser($id)
    {
        $user = User::find($id);

        if (!$user) {
            return $this->errorResponse('User not found.', 404);
        }

        $user->delete();

        return $this->successResponse(['message' => 'User deleted successfully.']);
    }

    public function premiumRequests()
    {
        $users = User::where('premium_requested', true)
            ->where('is_premium', false)
            ->orderBy('created_at', 'asc')
            ->get();

        return $this->successResponse(['requests' => $users]);
    }

    public function approvePremium($id)
    {
        $user = User::find($id);

        if (!$user) {
            return $this->errorResponse('User not found.', 404);
        }

        $user->update(['is_premium' => true, 'premium_requested' => false]);

        Notification::create([
            'user_id' => $user->id,
            'type' => 'premium_approved',
            'message' => 'Votre demande premium a été approuvée !',
            'has_sound' => true,
        ]);

        return $this->successResponse(['message' => 'Premium approved successfully.']);
    }

    public function rejectPremium($id)
    {
        $user = User::find($id);

        if (!$user) {
            return $this->errorResponse('User not found.', 404);
        }

        $user->update(['premium_requested' => false]);

        Notification::create([
            'user_id' => $user->id,
            'type' => 'premium_rejected',
            'message' => 'Votre demande premium a été refusée.',
            'has_sound' => true,
        ]);

        return $this->successResponse(['message' => 'Premium request rejected.']);
    }

    public function posts(Request $request)
    {
        $query = Post::with('user');

        if ($request->filled('reported')) {
            $query->where('is_reported', true);
        }

        $result = $this->paginateQuery($query->orderBy('created_at', 'desc'), $request);

        return $this->successResponse([
            'posts' => $result['items'],
            'has_more' => $result['has_more'],
            'total' => $result['total'],
            'page' => $result['page'],
        ]);
    }

    public function deletePost($id)
    {
        $post = Post::find($id);

        if (!$post) {
            return $this->errorResponse('Post not found.', 404);
        }

        $post->delete();

        return $this->successResponse(['message' => 'Post deleted successfully.']);
    }

    public function hidePost($id)
    {
        $post = Post::find($id);

        if (!$post) {
            return $this->errorResponse('Post not found.', 404);
        }

        $post->update(['is_published' => false]);

        return $this->successResponse(['message' => 'Post hidden successfully.']);
    }

    public function marketplaceProducts(Request $request)
    {
        $query = Product::with('seller');

        if ($request->filled('status')) {
            if ($request->status === 'pending') $query->where('is_approved', false);
            if ($request->status === 'approved') $query->where('is_approved', true);
        }

        $result = $this->paginateQuery($query->orderBy('created_at', 'desc'), $request);

        return $this->successResponse([
            'products' => $result['items'],
            'has_more' => $result['has_more'],
            'total' => $result['total'],
            'page' => $result['page'],
        ]);
    }

    public function approveProduct($id)
    {
        $product = Product::find($id);

        if (!$product) {
            return $this->errorResponse('Product not found.', 404);
        }

        $product->update(['is_approved' => true]);

        Notification::create([
            'user_id' => $product->seller_id,
            'type' => 'product_approved',
            'message' => 'Votre produit "' . $product->name . '" a été approuvé.',
            'data' => json_encode(['product_id' => $product->id]),
            'has_sound' => true,
        ]);

        return $this->successResponse(['message' => 'Product approved successfully.']);
    }

    public function rejectProduct($id)
    {
        $product = Product::find($id);

        if (!$product) {
            return $this->errorResponse('Product not found.', 404);
        }

        $product->update(['is_approved' => false, 'is_active' => false]);

        Notification::create([
            'user_id' => $product->seller_id,
            'type' => 'product_rejected',
            'message' => 'Votre produit "' . $product->name . '" a été refusé.',
            'data' => json_encode(['product_id' => $product->id]),
            'has_sound' => true,
        ]);

        return $this->successResponse(['message' => 'Product rejected successfully.']);
    }

    public function boostOrders(Request $request)
    {
        $query = BoostOrder::with('user');

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        $result = $this->paginateQuery($query->orderBy('created_at', 'desc'), $request);

        return $this->successResponse([
            'orders' => $result['items'],
            'has_more' => $result['has_more'],
            'total' => $result['total'],
            'page' => $result['page'],
        ]);
    }

    public function fullsmmBalance()
    {
        $balance = $this->fullSMM->getBalance();

        return $this->successResponse(['balance' => $balance]);
    }

    public function syncBoostServices()
    {
        $services = $this->fullSMM->getServices();

        if (!$services) {
            return $this->errorResponse('Failed to sync services from provider.', 502);
        }

        return $this->successResponse([
            'message' => 'Services synced successfully.',
            'count' => count($services),
        ]);
    }

    public function courses(Request $request)
    {
        $query = Course::with('instructor');

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        $result = $this->paginateQuery($query->orderBy('created_at', 'desc'), $request);

        return $this->successResponse([
            'courses' => $result['items'],
            'has_more' => $result['has_more'],
            'total' => $result['total'],
            'page' => $result['page'],
        ]);
    }

    public function approveCourse(Request $request, $id)
    {
        $course = Course::find($id);

        if (!$course) {
            return $this->errorResponse('Formation non trouvée.', 404);
        }

        $course->update([
            'status' => Course::STATUS_APPROVED,
            'is_published' => true,
            'rejection_reason' => null,
        ]);

        Notification::create([
            'user_id' => $course->instructor_id,
            'type' => 'course_approved',
            'message' => 'Votre formation "' . $course->title . '" a été approuvée et est maintenant visible dans le catalogue.',
            'has_sound' => true,
        ]);

        return $this->successResponse(['message' => 'Formation approuvée.']);
    }

    public function rejectCourse(Request $request, $id)
    {
        $course = Course::find($id);

        if (!$course) {
            return $this->errorResponse('Formation non trouvée.', 404);
        }

        $validator = Validator::make($request->all(), [
            'reason' => 'nullable|string|max:1000',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $course->update([
            'status' => Course::STATUS_REJECTED,
            'is_published' => false,
            'rejection_reason' => $request->reason,
        ]);

        Notification::create([
            'user_id' => $course->instructor_id,
            'type' => 'course_rejected',
            'message' => 'Votre formation "' . $course->title . '" a été refusée.',
            'data' => json_encode(['reason' => $request->reason]),
            'has_sound' => true,
        ]);

        return $this->successResponse(['message' => 'Formation refusée.']);
    }

    public function coursesByStatus(Request $request)
    {
        $status = $request->input('status', 'submitted');
        $query = Course::with('instructor')->where('status', $status);

        $result = $this->paginateQuery($query->orderBy('created_at', 'desc'), $request);

        return $this->successResponse([
            'courses' => $result['items'],
            'has_more' => $result['has_more'],
            'total' => $result['total'],
            'page' => $result['page'],
        ]);
    }

    public function createCourse(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'title' => 'required|string|max:255',
            'description' => 'nullable|string|max:5000',
            'category' => 'nullable|string|max:100',
            'level' => 'required|in:beginner,intermediate,advanced,expert',
            'price' => 'required|numeric|min:0',
            'is_free' => 'boolean',
            'instructor_id' => 'nullable|integer|exists:users,id',
            'cover_image' => 'nullable|image|max:5120',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $data = [
            'instructor_id' => $request->input('instructor_id', auth()->id()),
            'title' => $request->title,
            'description' => $request->description,
            'category' => $request->category,
            'level' => $request->level,
            'price' => $request->price,
            'is_free' => $request->boolean('is_free', $request->price == 0),
            'is_published' => false,
        ];

        if ($request->hasFile('cover_image')) {
            $data['cover_image'] = $request->file('cover_image')->store('courses/covers', 'public');
        }

        $course = Course::create($data);

        return $this->successResponse([
            'message' => 'Course created successfully.',
            'course' => $course,
        ], 201);
    }

    public function updateCourse(Request $request, $id)
    {
        $course = Course::find($id);

        if (!$course) {
            return $this->errorResponse('Course not found.', 404);
        }

        $validator = Validator::make($request->all(), [
            'title' => 'sometimes|string|max:255',
            'description' => 'nullable|string|max:5000',
            'category' => 'nullable|string|max:100',
            'level' => 'sometimes|in:beginner,intermediate,advanced,expert',
            'price' => 'sometimes|numeric|min:0',
            'is_free' => 'boolean',
            'is_published' => 'boolean',
            'featured' => 'boolean',
            'cover_image' => 'nullable|image|max:5120',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $data = $request->only(['title', 'description', 'category', 'level', 'price', 'is_free', 'is_published', 'featured']);

        if ($request->hasFile('cover_image')) {
            $data['cover_image'] = $request->file('cover_image')->store('courses/covers', 'public');
        }

        $course->update($data);

        return $this->successResponse([
            'message' => 'Course updated successfully.',
            'course' => $course->fresh(),
        ]);
    }

    public function deleteCourse($id)
    {
        $course = Course::find($id);

        if (!$course) {
            return $this->errorResponse('Course not found.', 404);
        }

        $course->delete();

        return $this->successResponse(['message' => 'Course deleted successfully.']);
    }

    public function reports(Request $request)
    {
        $query = Report::with(['reporter', 'reportedUser', 'post']);

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        $result = $this->paginateQuery($query->orderBy('created_at', 'desc'), $request);

        return $this->successResponse([
            'reports' => $result['items'],
            'has_more' => $result['has_more'],
            'total' => $result['total'],
            'page' => $result['page'],
        ]);
    }

    public function resolveReport(Request $request, $id)
    {
        $report = Report::find($id);

        if (!$report) {
            return $this->errorResponse('Report not found.', 404);
        }

        $validator = Validator::make($request->all(), [
            'admin_note' => 'nullable|string|max:500',
            'action' => 'nullable|in:none,hide_post,block_user,delete_post',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        if ($request->action === 'hide_post' && $report->post) {
            $report->post->update(['is_published' => false]);
        }

        if ($request->action === 'delete_post' && $report->post) {
            $report->post->delete();
        }

        if ($request->action === 'block_user' && $report->reported_user_id) {
            User::where('id', $report->reported_user_id)->update(['is_blocked' => true]);
        }

        $report->update([
            'status' => 'resolved',
            'admin_note' => $request->admin_note,
        ]);

        return $this->successResponse(['message' => 'Report resolved successfully.']);
    }

    public function pendingPayments(Request $request)
    {
        $query = Transaction::where('type', 'deposit')
            ->with('user');

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('type_filter')) {
            if ($request->type_filter === 'manual') {
                $query->whereRaw("metadata->>'manual' = 'true'");
            } elseif ($request->type_filter === 'chariow') {
                $query->whereRaw("metadata->>'manual' IS DISTINCT FROM 'true'");
            }
        }

        $result = $this->paginateQuery($query->orderBy('created_at', 'desc'), $request);

        return $this->successResponse([
            'payments' => $result['items'],
            'has_more' => $result['has_more'],
            'total' => $result['total'],
            'page' => $result['page'],
        ]);
    }

    public function approvePayment($id)
    {
        $transaction = Transaction::find($id);

        if (!$transaction || $transaction->type !== 'deposit') {
            return $this->errorResponse('Transaction non trouvée.', 404);
        }

        if ($transaction->status !== 'pending') {
            return $this->errorResponse('Ce paiement a déjà été traité.', 400);
        }

        $transaction->update([
            'status' => 'completed',
            'completed_at' => now(),
        ]);

        $user = User::find($transaction->user_id);
        $user->increment('boost_balance', $transaction->amount);

        Notification::create([
            'user_id' => $user->id,
            'type' => 'payment_approved',
            'message' => 'Votre dépôt de ' . number_format($transaction->amount, 0, ',', '.') . ' CDF a été approuvé et crédité sur votre compte.',
            'has_sound' => true,
        ]);

        Log::info('Admin approved manual payment', [
            'admin_id' => auth()->id(),
            'transaction_id' => $transaction->id,
            'user_id' => $user->id,
            'amount' => $transaction->amount,
        ]);

        return $this->successResponse(['message' => 'Paiement approuvé et crédité.']);
    }

    public function rejectPayment(Request $request, $id)
    {
        $transaction = Transaction::find($id);

        if (!$transaction || $transaction->type !== 'deposit') {
            return $this->errorResponse('Transaction non trouvée.', 404);
        }

        if ($transaction->status !== 'pending') {
            return $this->errorResponse('Ce paiement a déjà été traité.', 400);
        }

        $validator = Validator::make($request->all(), [
            'reason' => 'nullable|string|max:500',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $transaction->update([
            'status' => 'failed',
            'metadata' => array_merge($transaction->metadata ?? [], [
                'rejected_reason' => $request->reason,
                'rejected_at' => now()->toISOString(),
                'rejected_by' => auth()->id(),
            ]),
        ]);

        $user = User::find($transaction->user_id);

        Notification::create([
            'user_id' => $user->id,
            'type' => 'payment_rejected',
            'message' => 'Votre dépôt de ' . number_format($transaction->amount, 0, ',', '.') . ' CDF a été rejeté.' . ($request->reason ? ' Raison: ' . $request->reason : ''),
            'has_sound' => true,
        ]);

        Log::info('Admin rejected manual payment', [
            'admin_id' => auth()->id(),
            'transaction_id' => $transaction->id,
            'user_id' => $user->id,
            'amount' => $transaction->amount,
            'reason' => $request->reason,
        ]);

        return $this->successResponse(['message' => 'Paiement rejeté.']);
    }
}
