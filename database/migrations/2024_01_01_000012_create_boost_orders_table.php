<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('boost_orders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('platform');
            $table->string('service_id');
            $table->string('service_name')->nullable();
            $table->string('service_category')->nullable();
            $table->string('link');
            $table->unsignedInteger('quantity');
            $table->decimal('price', 15, 2);
            $table->decimal('price_per_unit', 15, 4)->nullable();
            $table->string('fullsmm_order_id')->nullable();
            $table->string('status')->default('pending');
            $table->string('status_message')->nullable();
            $table->timestamp('started_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->unsignedInteger('remaining')->nullable();
            $table->string('refill_status')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index('status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('boost_orders');
    }
};
