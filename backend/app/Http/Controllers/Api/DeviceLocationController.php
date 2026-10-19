<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\DeviceLocationRequest;
use App\Models\Device;
use App\Services\DeviceLocationService;
use App\Services\TrackingAuditService;
use Illuminate\Http\JsonResponse;
use InvalidArgumentException;

class DeviceLocationController extends Controller
{
    public function __construct(
        private readonly DeviceLocationService $locations,
        private readonly TrackingAuditService $audit,
    ) {}

    public function store(DeviceLocationRequest $request): JsonResponse
    {
        /** @var Device $device */
        $device = $request->attributes->get('authenticated_device');

        try {
            $location = $this->locations->storeFromDevice($device, $request->validated());

            $this->audit->log(
                action: 'device_location_received',
                resourceType: 'device_location',
                resourceId: (string) $location->id,
                metadata: ['device_id' => $device->device_id],
                ip: $request->ip(),
            );

            return response()->json([
                'message' => 'Location recorded.',
                'id' => $location->id,
                'received_at' => $location->received_at->toIso8601String(),
            ], 201);
        } catch (InvalidArgumentException $e) {
            $status = str_contains($e->getMessage(), 'Duplicate') ? 409 : 422;

            return response()->json(['message' => $e->getMessage()], $status);
        }
    }
}
