<?php

namespace App\Http\Middleware;

use App\Services\DeviceService;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class AuthenticateDevice
{
    public function __construct(private readonly DeviceService $devices) {}

    public function handle(Request $request, Closure $next): Response
    {
        $deviceId = $request->input('device_id') ?? $request->header('X-Device-Id');
        $token = $request->bearerToken()
            ?? $request->header('X-Device-Token')
            ?? $request->input('api_token');

        if (! $deviceId || ! $token) {
            return response()->json(['message' => 'Device authentication required.'], 401);
        }

        $device = $this->devices->authenticate($deviceId, $token);
        if ($device === null) {
            return response()->json(['message' => 'Invalid device credentials.'], 401);
        }

        $request->attributes->set('authenticated_device', $device);

        return $next($request);
    }
}
