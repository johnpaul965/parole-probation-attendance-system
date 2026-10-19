<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Device extends Model
{
    protected $fillable = [
        'device_id',
        'device_name',
        'device_type',
        'serial_number',
        'api_token_hash',
        'status',
        'battery_level',
        'last_seen_at',
    ];

    protected $casts = [
        'last_seen_at' => 'datetime',
        'battery_level' => 'integer',
    ];

    protected $hidden = ['api_token_hash'];

    public function assignments(): HasMany
    {
        return $this->hasMany(ParoleeDeviceAssignment::class);
    }

    public function activeAssignment(): HasOne
    {
        return $this->hasOne(ParoleeDeviceAssignment::class)->where('status', 'active');
    }

    public function locations(): HasMany
    {
        return $this->hasMany(DeviceLocation::class);
    }

    public function isOnline(): bool
    {
        if ($this->last_seen_at === null) {
            return false;
        }

        $threshold = now()->subMinutes(config('tracking.offline_threshold_minutes', 2));

        return $this->last_seen_at->greaterThanOrEqualTo($threshold);
    }
}
