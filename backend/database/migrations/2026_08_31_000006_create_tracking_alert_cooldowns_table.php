<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tracking_alert_cooldowns', function (Blueprint $table) {
            $table->id();
            $table->string('alert_type');
            $table->string('device_id')->nullable();
            $table->string('parolee_id')->nullable();
            $table->timestamp('last_sent_at');
            $table->timestamps();

            $table->unique(['alert_type', 'device_id', 'parolee_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tracking_alert_cooldowns');
    }
};
