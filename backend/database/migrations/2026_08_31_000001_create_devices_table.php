<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('devices', function (Blueprint $table) {
            $table->id();
            $table->string('device_id')->unique();
            $table->string('device_name')->nullable();
            $table->string('device_type')->default('gps_tracker');
            $table->string('serial_number')->nullable();
            $table->string('api_token_hash');
            $table->enum('status', ['active', 'inactive', 'offline', 'maintenance', 'unassigned'])->default('unassigned');
            $table->unsignedTinyInteger('battery_level')->nullable();
            $table->timestamp('last_seen_at')->nullable();
            $table->timestamps();

            $table->index('status');
            $table->index('last_seen_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('devices');
    }
};
