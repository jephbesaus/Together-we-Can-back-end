<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email')->unique();
            $table->string('phone')->unique();
            $table->string('password');
            $table->string('profile_photo')->nullable();
            $table->string('cover_photo')->nullable();
            $table->string('bio', 500)->nullable();
            $table->string('role')->default('user');
            $table->boolean('is_premium')->default(false);
            $table->boolean('premium_requested')->default(false);
            $table->boolean('is_verified')->default(false);
            $table->boolean('is_blocked')->default(false);
            $table->unsignedInteger('followers_count')->default(0);
            $table->unsignedInteger('following_count')->default(0);
            $table->decimal('boost_balance', 15, 2)->default(0);
            $table->decimal('savings_balance', 15, 2)->default(0);
            $table->string('referral_code')->unique()->nullable();
            $table->unsignedBigInteger('referred_by')->nullable();
            $table->unsignedInteger('referral_count')->default(0);
            $table->decimal('referral_earnings', 15, 2)->default(0);
            $table->timestamp('referral_expires_at')->nullable();
            $table->string('device_token')->nullable();
            $table->string('device_platform')->nullable();
            $table->string('device_id')->nullable();
            $table->string('otp', 6)->nullable();
            $table->timestamp('otp_expires_at')->nullable();
            $table->timestamp('last_active')->nullable();
            $table->rememberToken();
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('referred_by')->references('id')->on('users')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('users');
    }
};
