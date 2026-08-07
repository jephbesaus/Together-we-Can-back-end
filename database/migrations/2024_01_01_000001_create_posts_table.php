<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('posts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->text('content')->nullable();
            $table->enum('media_type', ['text', 'image', 'video', 'story'])->default('text');
            $table->text('media_url')->nullable();
            $table->string('thumbnail_url')->nullable();
            $table->boolean('is_announcement')->default(false);
            $table->boolean('is_story')->default(false);
            $table->timestamp('story_expires_at')->nullable();
            $table->unsignedInteger('likes_count')->default(0);
            $table->unsignedInteger('comments_count')->default(0);
            $table->unsignedInteger('shares_count')->default(0);
            $table->unsignedInteger('views_count')->default(0);
            $table->boolean('is_published')->default(true);
            $table->boolean('is_reported')->default(false);
            $table->timestamps();
            $table->softDeletes();

            $table->index(['is_published', 'is_story', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('posts');
    }
};
