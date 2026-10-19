<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\CreateDeviceRequest;
use App\Models\Device;
use App\Models\DeviceLocation;
use App\Services\DeviceAssignmentService;
use App\Services\DeviceService;
use App\Services\TrackingAuditService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminDeviceController extends Controller
{
    public function __construct(
        private readonly DeviceService $devices,
        private readonly DeviceAssignmentService $assignments,
        private readonly TrackingAuditService $audit,
    ) {}

    public function index(): JsonResponse
    {
        $devices = Device::with('activeAssignment')->orderBy('device_id')->get();

        return response()->json([
            'data' => $devices->map(fn (Device $d) => $this->formatDevice($d)),
        ]);
    }

    public function store(CreateDeviceRequest $request): JsonResponse
    {
        $result = $this->devices->registerDevice($request->validated());

        $this->audit->log(
            action: 'device_registered',
            resourceType: 'device',
            resourceId: $result['device']->device_id,
            actorId: $request->user()?->id,
            actorRole: 'officer',
            ip: $request->ip(),
        );

        return response()->json([
            'device' => $this->formatDevice($result['device']),
            'api_token' => $result['api_token'],
            'message' => 'Save the API token now. It will not be shown again.',
        ], 201);
    }

    public function show(string $deviceId): JsonResponse
    {
        $device = Device::with('activeAssignment')->where('device_id', $deviceId)->firstOrFail();

        return response()->json(['data' => $this->formatDevice($device)]);
    }

    public function assign(Request $request, string $deviceId): JsonResponse
    {
        $request->validate(['parolee_id' => ['required', 'string']]);

        $device = Device::where('device_id', $deviceId)->firstOrFail();
        $assignment = $this->assignments->assign(
            $device,
            $request->input('parolee_id'),
            $request->user()?->id,
        );

        $this->audit->log(
            action: 'device_assigned',
            resourceType: 'device',
            resourceId: $deviceId,
            actorId: $request->user()?->id,
            actorRole: 'officer',
            metadata: ['parolee_id' => $request->input('parolee_id')],
            ip: $request->ip(),
        );

        return response()->json(['assignment' => $assignment, 'device' => $this->formatDevice($device->fresh())]);
    }

    public function updateStatus(Request $request, string $deviceId): JsonResponse
    {
        $request->validate(['status' => ['required', 'in:active,inactive,offline,maintenance,unassigned']]);

        $device = Device::where('device_id', $deviceId)->firstOrFail();
        $device = $this->devices->updateStatus($device, $request->input('status'));

        return response()->json(['data' => $this->formatDevice($device)]);
    }

    public function rotateToken(Request $request, string $deviceId): JsonResponse
    {
        $device = Device::where('device_id', $deviceId)->firstOrFail();
        $token = $this->devices->rotateCredentials($device);

        $this->audit->log(
            action: 'device_token_rotated',
            resourceType: 'device',
            resourceId: $deviceId,
            actorId: $request->user()?->id,
            actorRole: 'officer',
            ip: $request->ip(),
        );

        return response()->json([
            'api_token' => $token,
            'message' => 'New API token generated. Update device firmware.',
        ]);
    }

    public function locationLogs(Request $request, string $deviceId): JsonResponse
    {
        $device = Device::where('device_id', $deviceId)->firstOrFail();
        $perPage = min((int) $request->input('per_page', 50), 200);

        $logs = DeviceLocation::where('device_id', $device->id)
            ->orderByDesc('recorded_at')
            ->paginate($perPage);

        return response()->json($logs);
    }

    private function formatDevice(Device $device): array
    {
        return [
            'device_id' => $device->device_id,
            'device_name' => $device->device_name,
            'device_type' => $device->device_type,
            'serial_number' => $device->serial_number,
            'status' => $device->status,
            'battery_level' => $device->battery_level,
            'last_seen_at' => $device->last_seen_at?->toIso8601String(),
            'online' => $device->isOnline(),
            'parolee_id' => $device->activeAssignment?->parolee_id,
            'assigned_at' => $device->activeAssignment?->assigned_at?->toIso8601String(),
        ];
    }
}
