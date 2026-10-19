<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TrackingAuditLog extends Model
{
    protected $fillable = [
        'actor_id',
        'actor_role',
        'action',
        'resource_type',
        'resource_id',
        'metadata',
        'ip_address',
    ];

    protected $casts = [
        'metadata' => 'array',
    ];
}
