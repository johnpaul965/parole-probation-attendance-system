<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tracking_audit_logs', function (Blueprint $table) {
            $table->id();
            $table->string('actor_id')->nullable();
            $table->string('actor_role')->nullable();
            $table->string('action');
            $table->string('resource_type');
            $table->string('resource_id')->nullable();
            $table->json('metadata')->nullable();
            $table->string('ip_address')->nullable();
            $table->timestamps();

            $table->index(['resource_type', 'resource_id']);
            $table->index('created_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tracking_audit_logs');
    }
};
