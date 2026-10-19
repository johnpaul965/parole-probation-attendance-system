<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ParoleeDeviceAssignment extends Model
{
    protected $fillable = [
        'parolee_id',
        'device_id',
        'assigned_by',
        'assigned_at',
        'unassigned_at',
        'status',
    ];

    protected $casts = [
        'assigned_at' => 'datetime',
        'unassigned_at' => 'datetime',
    ];

    public function device(): BelongsTo
    {
        return $this->belongsTo(Device::class);
    }
}
