<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('course_sections', function (Blueprint $table) {
            $table->id();
            $table->foreignId('course_id')->constrained()->cascadeOnDelete();
            $table->string('title');
            $table->text('description')->nullable();
            $table->unsignedInteger('order_position')->default(0);
            $table->timestamps();
        });

        Schema::table('course_lessons', function (Blueprint $table) {
            $table->foreign('section_id')->references('id')->on('course_sections')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('course_lessons', function (Blueprint $table) {
            $table->dropForeign(['section_id']);
        });
        Schema::dropIfExists('course_sections');
    }
};
