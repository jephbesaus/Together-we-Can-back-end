<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('course_lessons', function (Blueprint $table) {
            $table->id();
            $table->foreignId('course_id')->constrained()->cascadeOnDelete();
            $table->unsignedBigInteger('section_id')->nullable();
            $table->string('title');
            $table->text('description')->nullable();
            $table->longText('content')->nullable();
            $table->string('video_url')->nullable();
            $table->unsignedInteger('video_duration')->nullable();
            $table->json('documents')->nullable();
            $table->unsignedInteger('order_position')->default(0);
            $table->boolean('is_free_preview')->default(false);
            $table->boolean('is_published')->default(true);
            $table->string('type')->default('video');
            $table->timestamps();
            $table->softDeletes();

            $table->index('section_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('course_lessons');
    }
};
