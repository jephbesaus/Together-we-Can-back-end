<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('courses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('instructor_id')->constrained('users')->cascadeOnDelete();
            $table->string('title');
            $table->text('description')->nullable();
            $table->string('cover_image')->nullable();
            $table->string('category')->nullable();
            $table->enum('level', ['beginner', 'intermediate', 'advanced', 'expert'])->default('beginner');
            $table->decimal('price', 15, 2)->default(0);
            $table->boolean('is_free')->default(true);
            $table->boolean('is_published')->default(false);
            $table->boolean('featured')->default(false);
            $table->unsignedInteger('duration_minutes')->default(0);
            $table->unsignedInteger('lessons_count')->default(0);
            $table->unsignedInteger('students_count')->default(0);
            $table->decimal('rating', 3, 2)->default(0);
            $table->unsignedInteger('reviews_count')->default(0);
            $table->json('what_you_will_learn')->nullable();
            $table->json('requirements')->nullable();
            $table->json('target_audience')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['is_published', 'featured']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('courses');
    }
};
