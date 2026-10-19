<?php

namespace App\Services;

use App\Models\Device;
use App\Models\DeviceLocation;
use App\Models\Geofence;
use App\Models\ParoleeDeviceAssignment;
use App\Models\TrackingAlertCooldown;
use App\Models\TrackingAuditLog;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use InvalidArgumentException;

class DeviceService
{
    public function registerDevice(array $data): array
    {
        $plainToken = Str::random(64);

        $device = Device::create([
            'device_id' => $data['device_id'],
            'device_name' => $data['device_name'] ?? $data['device_id'],
            'device_type' => $data['device_type'] ?? 'gps_tracker',
            'serial_number' => $data['serial_number'] ?? null,
            'api_token_hash' => Hash::make($plainToken),
            'status' => 'unassigned',
        ]);

        return ['device' => $device, 'api_token' => $plainToken];
    }

    public function rotateCredentials(Device $device): string
    {
        $plainToken = Str::random(64);
        $device->update(['api_token_hash' => Hash::make($plainToken)]);

        return $plainToken;
    }

    public function updateStatus(Device $device, string $status): Device
    {
        $allowed = ['active', 'inactive', 'offline', 'maintenance', 'unassigned'];
        if (! in_array($status, $allowed, true)) {
            throw new InvalidArgumentException('Invalid device status.');
        }

        $device->update(['status' => $status]);

        return $device->fresh();
    }

    public function authenticate(string $deviceId, string $apiToken): ?Device
    {
        $device = Device::where('device_id', $deviceId)->first();
        if ($device === null) {
            return null;
        }

        if (! Hash::check($apiToken, $device->api_token_hash)) {
            return null;
        }

        return $device;
    }
}

class DeviceAssignmentService
{
    public function assign(Device $device, string $paroleeId, ?string $assignedBy = null): ParoleeDeviceAssignment
    {
        return DB::transaction(function () use ($device, $paroleeId, $assignedBy) {
            ParoleeDeviceAssignment::where('parolee_id', $paroleeId)
                ->where('status', 'active')
                ->update(['status' => 'ended', 'unassigned_at' => now()]);

            ParoleeDeviceAssignment::where('device_id', $device->id)
                ->where('status', 'active')
                ->update(['status' => 'ended', 'unassigned_at' => now()]);

            $assignment = ParoleeDeviceAssignment::create([
                'parolee_id' => $paroleeId,
                'device_id' => $device->id,
                'assigned_by' => $assignedBy,
                'assigned_at' => now(),
                'status' => 'active',
            ]);

            $device->update(['status' => 'active']);

            return $assignment;
        });
    }

    public function unassign(Device $device): void
    {
        DB::transaction(function () use ($device) {
            ParoleeDeviceAssignment::where('device_id', $device->id)
                ->where('status', 'active')
                ->update(['status' => 'ended', 'unassigned_at' => now()]);

            $device->update(['status' => 'unassigned']);
        });
    }

    public function getActiveParoleeId(Device $device): ?string
    {
        return ParoleeDeviceAssignment::where('device_id', $device->id)
            ->where('status', 'active')
            ->value('parolee_id');
    }
}

class DeviceLocationService
{
    public function __construct(
        private readonly DeviceAssignmentService $assignments,
        private readonly TrackingAlertService $alerts,
    ) {}

    public function storeFromDevice(Device $device, array $payload): DeviceLocation
    {
        if (! in_array($device->status, ['active', 'offline'], true)) {
            throw new InvalidArgumentException('Device is not active.');
        }

        $lat = (float) $payload['latitude'];
        $lng = (float) $payload['longitude'];

        if ($lat < -90 || $lat > 90 || $lng < -180 || $lng > 180) {
            throw new InvalidArgumentException('Invalid GPS coordinates.');
        }

        if (abs($lat) < 0.0001 && abs($lng) < 0.0001) {
            throw new InvalidArgumentException('Null island coordinates rejected.');
        }

        $paroleeId = $this->assignments->getActiveParoleeId($device);
        if ($paroleeId === null) {
            throw new InvalidArgumentException('Device is not assigned to a parolee.');
        }

        $recordedAt = isset($payload['timestamp'])
            ? \Carbon\Carbon::parse($payload['timestamp'])
            : now();

        $window = config('tracking.duplicate_location_window_seconds', 30);
        $duplicate = DeviceLocation::where('device_id', $device->id)
            ->where('recorded_at', '>=', $recordedAt->copy()->subSeconds($window))
            ->where('latitude', $lat)
            ->where('longitude', $lng)
            ->exists();

        if ($duplicate) {
            throw new InvalidArgumentException('Duplicate location record.');
        }

        $location = DeviceLocation::create([
            'device_id' => $device->id,
            'parolee_id' => $paroleeId,
            'latitude' => $lat,
            'longitude' => $lng,
            'accuracy' => $payload['accuracy'] ?? null,
            'speed' => $payload['speed'] ?? null,
            'battery_level' => $payload['battery_level'] ?? null,
            'recorded_at' => $recordedAt,
            'received_at' => now(),
        ]);

        $device->update([
            'battery_level' => $payload['battery_level'] ?? $device->battery_level,
            'last_seen_at' => now(),
            'status' => 'active',
        ]);

        $battery = $payload['battery_level'] ?? null;
        if ($battery !== null && $battery <= config('tracking.low_battery_threshold', 20)) {
            $this->alerts->maybeSendLowBattery($device, $paroleeId, (int) $battery);
        }

        return $location;
    }
}

class TrackingAlertService
{
    public function maybeSendLowBattery(Device $device, string $paroleeId, int $batteryLevel): void
    {
        $cooldown = config('tracking.alert_cooldown_minutes', 60);
        $key = TrackingAlertCooldown::firstOrCreate(
            ['alert_type' => 'low_battery', 'device_id' => $device->device_id, 'parolee_id' => $paroleeId],
            ['last_sent_at' => now()->subMinutes($cooldown + 1)],
        );

        if ($key->last_sent_at->diffInMinutes(now()) < $cooldown) {
            return;
        }

        $key->update(['last_sent_at' => now()]);
        // Hook: dispatch notification job / Firebase message
    }
}

class TrackingAuditService
{
    public function log(
        string $action,
        string $resourceType,
        ?string $resourceId = null,
        ?string $actorId = null,
        ?string $actorRole = null,
        ?array $metadata = null,
        ?string $ip = null,
    ): void {
        TrackingAuditLog::create([
            'actor_id' => $actorId,
            'actor_role' => $actorRole,
            'action' => $action,
            'resource_type' => $resourceType,
            'resource_id' => $resourceId,
            'metadata' => $metadata,
            'ip_address' => $ip,
        ]);
    }
}

class GeofenceService
{
  public function evaluate(float $lat, float $lng, string $paroleeId): array
  {
      $violations = [];
      $geofences = Geofence::where('parolee_id', $paroleeId)->where('status', 'active')->get();

      foreach ($geofences as $geofence) {
          $distance = $this->haversineMeters($lat, $lng, (float) $geofence->latitude, (float) $geofence->longitude);
          if ($distance > $geofence->radius_meters) {
              $violations[] = $geofence;
          }
      }

      return $violations;
  }

  private function haversineMeters(float $lat1, float $lng1, float $lat2, float $lng2): float
  {
      $earthRadius = 6371000;
      $dLat = deg2rad($lat2 - $lat1);
      $dLng = deg2rad($lng2 - $lng1);
      $a = sin($dLat / 2) ** 2 + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLng / 2) ** 2;

      return 2 * $earthRadius * asin(min(1, sqrt($a)));
  }
}
