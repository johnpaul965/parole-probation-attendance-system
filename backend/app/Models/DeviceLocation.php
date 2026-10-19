<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DeviceLocation extends Model
{
    protected $fillable = [
        'device_id',
        'parolee_id',
        'latitude',
        'longitude',
        'accuracy',
        'speed',
        'battery_level',
        'recorded_at',
        'received_at',
    ];

    protected $casts = [
        'latitude' => 'float',
        'longitude' => 'float',
        'accuracy' => 'float',
        'speed' => 'float',
        'battery_level' => 'integer',
        'recorded_at' => 'datetime',
        'received_at' => 'datetime',
    ];

    public function device(): BelongsTo
    {
        return $this->belongsTo(Device::class);
    }
}
