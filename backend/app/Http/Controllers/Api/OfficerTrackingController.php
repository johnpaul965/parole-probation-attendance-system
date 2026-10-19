<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Device;
use App\Models\DeviceLocation;
use App\Services\TrackingAuditService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class OfficerTrackingController extends Controller
{
    public function __construct(private readonly TrackingAuditService $audit) {}

    public function latestDevice(Request $request, string $paroleeId): JsonResponse
    {
        if (! $this->canAccessParolee($request, $paroleeId)) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $this->audit->log(
            action: 'tracking_access',
            resourceType: 'parolee',
            resourceId: $paroleeId,
            actorId: $request->user()?->id,
            actorRole: 'officer',
            metadata: ['endpoint' => 'device'],
            ip: $request->ip(),
        );

        $assignment = \App\Models\ParoleeDeviceAssignment::where('parolee_id', $paroleeId)
            ->where('status', 'active')
            ->with('device')
            ->first();

        if ($assignment === null) {
            return response()->json(['data' => null]);
        }

        $device = $assignment->device;

        return response()->json([
            'data' => [
                'device_id' => $device->device_id,
                'status' => $device->status,
                'online' => $device->isOnline(),
                'battery_level' => $device->battery_level,
                'last_seen_at' => $device->last_seen_at?->toIso8601String(),
                'assigned_at' => $assignment->assigned_at->toIso8601String(),
            ],
        ]);
    }

    public function latestLocation(Request $request, string $paroleeId): JsonResponse
    {
        if (! $this->canAccessParolee($request, $paroleeId)) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $this->audit->log(
            action: 'tracking_access',
            resourceType: 'parolee',
            resourceId: $paroleeId,
            actorId: $request->user()?->id,
            actorRole: 'officer',
            metadata: ['endpoint' => 'location_latest'],
            ip: $request->ip(),
        );

        $location = DeviceLocation::where('parolee_id', $paroleeId)
            ->orderByDesc('recorded_at')
            ->first();

        if ($location === null) {
            return response()->json(['data' => null]);
        }

        return response()->json(['data' => $location]);
    }

    public function locationHistory(Request $request, string $paroleeId): JsonResponse
    {
        if (! $this->canAccessParolee($request, $paroleeId)) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $this->audit->log(
            action: 'tracking_access',
            resourceType: 'parolee',
            resourceId: $paroleeId,
            actorId: $request->user()?->id,
            actorRole: 'officer',
            metadata: ['endpoint' => 'location_history'],
            ip: $request->ip(),
        );

        $query = DeviceLocation::where('parolee_id', $paroleeId)->orderByDesc('recorded_at');

        if ($request->filled('start')) {
            $query->where('recorded_at', '>=', $request->input('start'));
        }
        if ($request->filled('end')) {
            $query->where('recorded_at', '<=', $request->input('end'));
        }

        $perPage = min((int) $request->input('per_page', 50), 200);

        return response()->json($query->paginate($perPage));
    }

    private function canAccessParolee(Request $request, string $paroleeId): bool
    {
        $user = $request->user();
        if ($user === null) {
            return false;
        }

        if ($user->role !== 'officer') {
            return false;
        }

        // parolee.assigned_officer_id == authenticated_officer.id
        $parolee = \DB::table('users')->where('id', $paroleeId)->first();
        if ($parolee === null) {
            return false;
        }

        return ($parolee->officer_id ?? $parolee->assigned_officer_id) === $user->id;
    }
}
