<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TrackingAlertCooldown extends Model
{
    protected $fillable = [
        'alert_type',
        'device_id',
        'parolee_id',
        'last_sent_at',
    ];

    protected $casts = [
        'last_sent_at' => 'datetime',
    ];
}
