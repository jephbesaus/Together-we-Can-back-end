<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->foreignId('seller_id')->constrained('users')->cascadeOnDelete();
            $table->string('name');
            $table->text('description')->nullable();
            $table->decimal('price', 15, 2);
            $table->string('category')->nullable();
            $table->json('images')->nullable();
            $table->string('video_url')->nullable();
            $table->string('location')->nullable();
            $table->string('contact_info')->nullable();
            $table->integer('stock_quantity')->nullable();
            $table->boolean('is_active')->default(true);
            $table->boolean('is_approved')->default(false);
            $table->unsignedInteger('views_count')->default(0);
            $table->boolean('featured')->default(false);
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['is_active', 'is_approved']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('products');
    }
};
