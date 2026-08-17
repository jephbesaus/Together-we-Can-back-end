<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $tables = [
            'users' => [
                ['columns' => ['is_blocked'], 'name' => 'users_is_blocked_index'],
                ['columns' => ['role'], 'name' => 'users_role_index'],
                ['columns' => ['last_active'], 'name' => 'users_last_active_index'],
            ],
            'posts' => [
                ['columns' => ['user_id'], 'name' => 'posts_user_id_index'],
                ['columns' => ['user_id', 'created_at'], 'name' => 'posts_user_id_created_at_index'],
                ['columns' => ['is_story', 'story_expires_at'], 'name' => 'posts_is_story_story_expires_at_index'],
                ['columns' => ['is_announcement'], 'name' => 'posts_is_announcement_index'],
            ],
            'comments' => [
                ['columns' => ['user_id'], 'name' => 'comments_user_id_index'],
                ['columns' => ['post_id'], 'name' => 'comments_post_id_index'],
                ['columns' => ['parent_id'], 'name' => 'comments_parent_id_index'],
            ],
            'likes' => [
                ['columns' => ['user_id'], 'name' => 'likes_user_id_index'],
                ['columns' => ['post_id'], 'name' => 'likes_post_id_index'],
                ['columns' => ['comment_id'], 'name' => 'likes_comment_id_index'],
            ],
            'follows' => [
                ['columns' => ['follower_id'], 'name' => 'follows_follower_id_index'],
                ['columns' => ['following_id'], 'name' => 'follows_following_id_index'],
            ],
            'messages' => [
                ['columns' => ['sender_id'], 'name' => 'messages_sender_id_index'],
                ['columns' => ['receiver_id'], 'name' => 'messages_receiver_id_index'],
                ['columns' => ['receiver_id', 'is_read'], 'name' => 'messages_receiver_id_is_read_index'],
            ],
            'conversations' => [
                ['columns' => ['user1_id'], 'name' => 'conversations_user1_id_index'],
                ['columns' => ['user2_id'], 'name' => 'conversations_user2_id_index'],
                ['columns' => ['last_message_at'], 'name' => 'conversations_last_message_at_index'],
            ],
            'notifications' => [
                ['columns' => ['user_id', 'is_read', 'created_at'], 'name' => 'notifications_user_id_is_read_created_at_index'],
                ['columns' => ['type'], 'name' => 'notifications_type_index'],
            ],
            'products' => [
                ['columns' => ['seller_id'], 'name' => 'products_seller_id_index'],
                ['columns' => ['category'], 'name' => 'products_category_index'],
                ['columns' => ['created_at'], 'name' => 'products_created_at_index'],
            ],
            'orders' => [
                ['columns' => ['buyer_id'], 'name' => 'orders_buyer_id_index'],
                ['columns' => ['seller_id'], 'name' => 'orders_seller_id_index'],
                ['columns' => ['buyer_id', 'status'], 'name' => 'orders_buyer_id_status_index'],
                ['columns' => ['seller_id', 'status'], 'name' => 'orders_seller_id_status_index'],
            ],
            'boost_orders' => [
                ['columns' => ['user_id', 'created_at'], 'name' => 'boost_orders_user_id_created_at_index'],
            ],
            'transactions' => [
                ['columns' => ['user_id', 'created_at'], 'name' => 'transactions_user_id_created_at_index'],
                ['columns' => ['payment_method'], 'name' => 'transactions_payment_method_index'],
                ['columns' => ['completed_at'], 'name' => 'transactions_completed_at_index'],
            ],
            'courses' => [
                ['columns' => ['instructor_id'], 'name' => 'courses_instructor_id_index'],
                ['columns' => ['category', 'is_published'], 'name' => 'courses_category_is_published_index'],
                ['columns' => ['level'], 'name' => 'courses_level_index'],
                ['columns' => ['is_free'], 'name' => 'courses_is_free_index'],
                ['columns' => ['rating'], 'name' => 'courses_rating_index'],
            ],
            'course_sections' => [
                ['columns' => ['course_id'], 'name' => 'course_sections_course_id_index'],
            ],
            'course_lessons' => [
                ['columns' => ['course_id'], 'name' => 'course_lessons_course_id_index'],
                ['columns' => ['section_id', 'order_position'], 'name' => 'course_lessons_section_id_order_position_index'],
            ],
            'course_enrollments' => [
                ['columns' => ['user_id'], 'name' => 'course_enrollments_user_id_index'],
                ['columns' => ['user_id', 'last_accessed_at'], 'name' => 'course_enrollments_user_id_last_accessed_at_index'],
                ['columns' => ['progress'], 'name' => 'course_enrollments_progress_index'],
            ],
            'lesson_progresses' => [
                ['columns' => ['user_id', 'is_completed'], 'name' => 'lesson_progresses_user_id_is_completed_index'],
            ],
            'course_reviews' => [
                ['columns' => ['course_id'], 'name' => 'course_reviews_course_id_index'],
                ['columns' => ['user_id'], 'name' => 'course_reviews_user_id_index'],
            ],
            'referrals' => [
                ['columns' => ['referrer_id'], 'name' => 'referrals_referrer_id_index'],
                ['columns' => ['referred_id'], 'name' => 'referrals_referred_id_index'],
                ['columns' => ['status'], 'name' => 'referrals_status_index'],
            ],
            'reports' => [
                ['columns' => ['status', 'created_at'], 'name' => 'reports_status_created_at_index'],
                ['columns' => ['reporter_id'], 'name' => 'reports_reporter_id_index'],
                ['columns' => ['reported_user_id'], 'name' => 'reports_reported_user_id_index'],
            ],
            'announcements' => [
                ['columns' => ['is_active', 'is_pinned'], 'name' => 'announcements_is_active_is_pinned_index'],
            ],
            'campaigns' => [
                ['columns' => ['user_id'], 'name' => 'campaigns_user_id_index'],
            ],
            'savings' => [
                ['columns' => ['user_id'], 'name' => 'savings_user_id_index'],
            ],
            'savings_transactions' => [
                ['columns' => ['savings_id'], 'name' => 'savings_transactions_savings_id_index'],
                ['columns' => ['user_id'], 'name' => 'savings_transactions_user_id_index'],
            ],
        ];

        foreach ($tables as $tableName => $indexes) {
            foreach ($indexes as $index) {
                if (!$this->indexExists($tableName, $index['name'])) {
                    Schema::table($tableName, function (Blueprint $table) use ($index) {
                        $table->index($index['columns']);
                    });
                }
            }
        }
    }

    public function down(): void
    {
        // This migration is idempotent - no need to reverse
    }

    private function indexExists(string $tableName, string $indexName): bool
    {
        $result = DB::select("SELECT indexname FROM pg_indexes WHERE tablename = ? AND indexname = ?", [$tableName, $indexName]);
        return count($result) > 0;
    }
};
