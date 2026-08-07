<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('conversations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user1_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('user2_id')->constrained('users')->cascadeOnDelete();
            $table->unsignedBigInteger('last_message_id')->nullable();
            $table->timestamp('last_message_at')->nullable();
            $table->boolean('is_archived_for_user1')->default(false);
            $table->boolean('is_archived_for_user2')->default(false);
            $table->boolean('blocked_by_user1')->default(false);
            $table->boolean('blocked_by_user2')->default(false);
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['user1_id', 'user2_id']);
        });

        Schema::table('messages', function (Blueprint $table) {
            $table->foreign('conversation_id')->references('id')->on('conversations')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('messages', function (Blueprint $table) {
            $table->dropForeign(['conversation_id']);
        });
        Schema::dropIfExists('conversations');
    }
};
