<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\PostController;
use App\Http\Controllers\Api\CommentController;
use App\Http\Controllers\Api\FollowController;
use App\Http\Controllers\Api\MessageController;
use App\Http\Controllers\Api\MarketplaceController;
use App\Http\Controllers\Api\CourseController;
use App\Http\Controllers\Api\BoostController;
use App\Http\Controllers\Api\TransactionController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Api\ReferralController;
use App\Http\Controllers\Api\AppReleaseController;
use App\Http\Controllers\Api\AnnouncementController;
use App\Http\Controllers\Api\CampaignController;
use App\Http\Controllers\Api\WebhookController;
use App\Http\Controllers\Api\InstructorController;
use App\Http\Controllers\Api\NewsController;

use App\Http\Controllers\Api\InfoController;

Route::post('/webhooks/fusionpay', [WebhookController::class, 'fusionPay']);
Route::match(['get', 'post'], '/webhooks/chariow', [WebhookController::class, 'chariow']);

Route::post('/auth/register', [AuthController::class, 'register'])->middleware('throttle:10,1');
Route::post('/auth/login', [AuthController::class, 'login'])->middleware('throttle:10,1');
Route::post('/auth/verify-otp', [AuthController::class, 'verifyOtp'])->middleware('throttle:10,1');
Route::post('/auth/forgot-password', [AuthController::class, 'forgotPassword'])->middleware('throttle:5,1');
Route::post('/auth/reset-password', [AuthController::class, 'resetPassword'])->middleware('throttle:5,1');
Route::post('/auth/resend-otp', [AuthController::class, 'resendOtp'])->middleware('throttle:5,1');

Route::get('/news', [NewsController::class, 'index']);

Route::get('/app/version', [AppReleaseController::class, 'info']);
Route::get('/support', [InfoController::class, 'support']);
Route::get('/about', [InfoController::class, 'about']);

Route::middleware(['auth:sanctum', 'blocked'])->group(function () {

    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::post('/auth/change-password', [AuthController::class, 'changePassword']);
    Route::post('/auth/deactivate', [AuthController::class, 'deactivateAccount']);

    Route::get('/user/profile', [UserController::class, 'profile']);
    Route::put('/user/profile', [UserController::class, 'updateProfile']);
    Route::post('/user/profile-photo', [UserController::class, 'updateProfilePhoto']);
    Route::get('/user/stats', [UserController::class, 'stats']);
    Route::get('/user/{id}', [UserController::class, 'show']);
    Route::get('/users/search', [UserController::class, 'search']);
    Route::post('/user/premium/request', [UserController::class, 'requestPremium']);
    Route::get('/user/premium/status', [UserController::class, 'premiumStatus']);

    Route::get('/posts/feed', [PostController::class, 'feed']);
    Route::get('/posts/stories', [PostController::class, 'stories']);
    Route::post('/posts/stories/{id}/view', [PostController::class, 'viewStory']);
    Route::get('/posts/stories/{id}/likers', [PostController::class, 'storyLikers']);
    Route::post('/posts/stories/{id}/like', [PostController::class, 'toggleStoryLike']);
    Route::delete('/posts/stories/{id}', [PostController::class, 'destroyStory']);
    Route::get('/posts/search', [PostController::class, 'search']);
    Route::post('/posts', [PostController::class, 'store']);
    Route::get('/posts/{id}', [PostController::class, 'show']);
    Route::put('/posts/{id}', [PostController::class, 'update']);
    Route::delete('/posts/{id}', [PostController::class, 'destroy']);
    Route::post('/posts/{id}/like', [PostController::class, 'toggleLike']);
    Route::post('/posts/{id}/share', [PostController::class, 'share']);
    Route::post('/posts/{id}/report', [PostController::class, 'report']);

    Route::get('/posts/{postId}/comments', [CommentController::class, 'index']);
    Route::post('/posts/{postId}/comments', [CommentController::class, 'store']);
    Route::put('/comments/{id}', [CommentController::class, 'update']);
    Route::delete('/comments/{id}', [CommentController::class, 'destroy']);
    Route::post('/comments/{id}/like', [CommentController::class, 'toggleLike']);

    Route::post('/users/{id}/follow', [FollowController::class, 'toggleFollow']);
    Route::get('/users/{id}/followers', [FollowController::class, 'followers']);
    Route::get('/users/{id}/following', [FollowController::class, 'following']);
    Route::get('/users/{id}/is-following', [FollowController::class, 'isFollowing']);
    Route::get('/users/{id}/mutual', [FollowController::class, 'mutual']);
    Route::get('/follow/suggestions', [FollowController::class, 'suggestions']);
    Route::get('/follow/my-stats', [FollowController::class, 'myStats']);
    Route::get('/follow/my-followers', [FollowController::class, 'myFollowers']);
    Route::get('/follow/my-following', [FollowController::class, 'myFollowing']);

    Route::get('/messages/conversations', [MessageController::class, 'conversations']);
    Route::get('/messages/unread-count', [MessageController::class, 'unreadCount']);
    Route::get('/messages/{userId}', [MessageController::class, 'conversation']);
    Route::post('/messages', [MessageController::class, 'store']);
    Route::put('/messages/{id}/read', [MessageController::class, 'markAsRead']);
    Route::put('/messages/conversations/{conversationId}/read', [MessageController::class, 'markConversationAsRead']);
    Route::delete('/messages/{id}', [MessageController::class, 'destroy']);
    Route::post('/messages/block', [MessageController::class, 'blockUser']);
    Route::post('/messages/unblock', [MessageController::class, 'unblockUser']);

    Route::get('/marketplace/products', [MarketplaceController::class, 'index']);
    Route::get('/marketplace/products/categories', [MarketplaceController::class, 'categories']);
    Route::get('/marketplace/products/{id}', [MarketplaceController::class, 'show']);
    Route::post('/marketplace/products', [MarketplaceController::class, 'store']);
    Route::put('/marketplace/products/{id}', [MarketplaceController::class, 'update']);
    Route::delete('/marketplace/products/{id}', [MarketplaceController::class, 'destroy']);
    Route::post('/marketplace/products/{productId}/order', [MarketplaceController::class, 'placeOrder']);
    Route::get('/marketplace/orders', [MarketplaceController::class, 'orders']);
    Route::get('/marketplace/orders/{id}', [MarketplaceController::class, 'orderDetails']);
    Route::put('/marketplace/orders/{id}/status', [MarketplaceController::class, 'updateOrderStatus']);
    Route::post('/marketplace/products/{productId}/review', [MarketplaceController::class, 'addReview']);
    Route::post('/marketplace/products/{productId}/favorite', [MarketplaceController::class, 'toggleFavorite']);
    Route::get('/marketplace/favorites', [MarketplaceController::class, 'favorites']);

    Route::get('/courses', [CourseController::class, 'index']);
    Route::get('/courses/categories', [CourseController::class, 'categories']);
    Route::get('/courses/my-courses', [CourseController::class, 'myCourses']);
    Route::get('/courses/{id}', [CourseController::class, 'show']);
    Route::post('/courses/{id}/enroll', [CourseController::class, 'enroll']);
    Route::post('/courses/{id}/confirm-enrollment', [CourseController::class, 'confirmEnrollment']);
    Route::post('/courses/{courseId}/lessons/{lessonId}/progress', [CourseController::class, 'updateProgress']);
    Route::post('/courses/{id}/review', [CourseController::class, 'addReview']);
    Route::get('/courses/{id}/certificate', [CourseController::class, 'certificate']);

    Route::prefix('instructor')->group(function () {
        Route::get('/dashboard', [InstructorController::class, 'dashboard']);
        Route::post('/courses', [InstructorController::class, 'store']);
        Route::put('/courses/{id}', [InstructorController::class, 'update']);
        Route::delete('/courses/{id}', [InstructorController::class, 'destroy']);
        Route::post('/courses/{id}/sections', [InstructorController::class, 'addSection']);
        Route::put('/courses/{id}/sections/{sectionId}', [InstructorController::class, 'updateSection']);
        Route::delete('/courses/{id}/sections/{sectionId}', [InstructorController::class, 'deleteSection']);
        Route::post('/courses/{id}/sections/{sectionId}/lessons', [InstructorController::class, 'addLesson']);
        Route::put('/courses/{id}/lessons/{lessonId}', [InstructorController::class, 'updateLesson']);
        Route::delete('/courses/{id}/lessons/{lessonId}', [InstructorController::class, 'deleteLesson']);
        Route::get('/courses/{id}/students', [InstructorController::class, 'students']);
        Route::post('/courses/{id}/submit', [InstructorController::class, 'submit']);
    });

    Route::get('/boost/platforms', [BoostController::class, 'platforms']);
    Route::get('/boost/services/{platform}', [BoostController::class, 'services']);
    Route::get('/boost/balance', [BoostController::class, 'balance']);
    Route::post('/boost/order', [BoostController::class, 'placeOrder']);
    Route::get('/boost/orders', [BoostController::class, 'orders']);
    Route::get('/boost/orders/{id}/status', [BoostController::class, 'orderStatus']);
    Route::post('/boost/deposit', [BoostController::class, 'deposit']);
    Route::get('/boost/history', [BoostController::class, 'history']);

    Route::get('/transactions/balance', [TransactionController::class, 'balance']);
    Route::get('/transactions/history', [TransactionController::class, 'history']);
    Route::get('/transactions/summary', [TransactionController::class, 'summary']);
    Route::get('/transactions/{id}', [TransactionController::class, 'show']);
    Route::post('/transactions/deposit', [TransactionController::class, 'deposit']);
    Route::get('/transactions/{id}/check-status', [TransactionController::class, 'checkDepositStatus']);
    Route::post('/transactions/withdraw', [TransactionController::class, 'withdraw']);
    Route::post('/transactions/transfer', [TransactionController::class, 'transfer']);

    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::get('/notifications/unread-count', [NotificationController::class, 'unreadCount']);
    Route::put('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);
    Route::put('/notifications/read-all', [NotificationController::class, 'markAllAsRead']);
    Route::delete('/notifications/{id}', [NotificationController::class, 'destroy']);
    Route::post('/notifications/fcm-token', [NotificationController::class, 'updateFcmToken']);
    Route::delete('/notifications/fcm-token', [NotificationController::class, 'removeFcmToken']);

    Route::get('/referrals/my-info', [ReferralController::class, 'myInfo']);
    Route::post('/referrals/process', [ReferralController::class, 'processReferral']);
    Route::post('/referrals/{id}/complete', [ReferralController::class, 'completeReferral']);
    Route::get('/referrals/share', [ReferralController::class, 'shareLink']);
    Route::get('/referrals/leaderboard', [ReferralController::class, 'leaderboard']);

    Route::get('/announcements', [AnnouncementController::class, 'index']);
    Route::get('/announcements/{id}', [AnnouncementController::class, 'show']);

    Route::get('/campaigns/my-campaigns', [CampaignController::class, 'myCampaigns']);
    Route::post('/campaigns', [CampaignController::class, 'store']);
    Route::get('/campaigns/{id}', [CampaignController::class, 'show']);
    Route::get('/campaigns/{id}/stats', [CampaignController::class, 'stats']);
    Route::post('/campaigns/{id}/stop', [CampaignController::class, 'stop']);

    Route::post('/admin/activate', [AdminController::class, 'activate']);

    Route::middleware(['admin'])->prefix('admin')->group(function () {
        Route::get('/dashboard', [AdminController::class, 'dashboard']);
        Route::get('/users', [AdminController::class, 'users']);
        Route::get('/users/{id}', [AdminController::class, 'userDetails']);
        Route::post('/users/{id}/block', [AdminController::class, 'blockUser']);
        Route::post('/users/{id}/unblock', [AdminController::class, 'unblockUser']);
        Route::delete('/users/{id}', [AdminController::class, 'deleteUser']);
        Route::get('/premium-requests', [AdminController::class, 'premiumRequests']);
        Route::post('/premium-requests/{id}/approve', [AdminController::class, 'approvePremium']);
        Route::post('/premium-requests/{id}/reject', [AdminController::class, 'rejectPremium']);
        Route::get('/posts', [AdminController::class, 'posts']);
        Route::delete('/posts/{id}', [AdminController::class, 'deletePost']);
        Route::post('/posts/{id}/hide', [AdminController::class, 'hidePost']);
        Route::get('/marketplace/products', [AdminController::class, 'marketplaceProducts']);
        Route::post('/marketplace/products/{id}/approve', [AdminController::class, 'approveProduct']);
        Route::post('/marketplace/products/{id}/reject', [AdminController::class, 'rejectProduct']);
        Route::get('/boost/orders', [AdminController::class, 'boostOrders']);
        Route::get('/boost/fullsmm-balance', [AdminController::class, 'fullsmmBalance']);
        Route::post('/boost/services/sync', [AdminController::class, 'syncBoostServices']);
        Route::get('/courses', [AdminController::class, 'courses']);
        Route::post('/courses', [AdminController::class, 'createCourse']);
        Route::put('/courses/{id}', [AdminController::class, 'updateCourse']);
        Route::delete('/courses/{id}', [AdminController::class, 'deleteCourse']);
        Route::post('/courses/{id}/approve', [AdminController::class, 'approveCourse']);
        Route::post('/courses/{id}/reject', [AdminController::class, 'rejectCourse']);
        Route::get('/courses/by-status', [AdminController::class, 'coursesByStatus']);
        Route::get('/reports', [AdminController::class, 'reports']);
        Route::post('/reports/{id}/resolve', [AdminController::class, 'resolveReport']);
        Route::post('/announcements', [AnnouncementController::class, 'store']);
        Route::put('/announcements/{id}', [AnnouncementController::class, 'update']);
        Route::delete('/announcements/{id}', [AnnouncementController::class, 'destroy']);
        Route::resource('news', NewsController::class)->except(['index', 'show']);
    });
});
