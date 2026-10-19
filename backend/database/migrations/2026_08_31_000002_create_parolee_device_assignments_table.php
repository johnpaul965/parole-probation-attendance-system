<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('parolee_device_assignments', function (Blueprint $table) {
            $table->id();
            $table->string('parolee_id');
            $table->foreignId('device_id')->constrained('devices')->cascadeOnDelete();
            $table->string('assigned_by')->nullable();
            $table->timestamp('assigned_at');
            $table->timestamp('unassigned_at')->nullable();
            $table->enum('status', ['active', 'ended'])->default('active');
            $table->timestamps();

            $table->index(['parolee_id', 'status']);
            $table->index(['device_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('parolee_device_assignments');
    }
};
