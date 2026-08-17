<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('courses', function (Blueprint $table) {
            $table->string('status')->default('draft')->after('instructor_id');
            $table->text('rejection_reason')->nullable()->after('status');
        });

        DB::table('courses')->where('is_published', true)->update(['status' => 'approved']);
        DB::table('courses')->where('is_published', false)->update(['status' => 'draft']);
    }

    public function down(): void
    {
        Schema::table('courses', function (Blueprint $table) {
            $table->dropColumn(['status', 'rejection_reason']);
        });
    }
};
