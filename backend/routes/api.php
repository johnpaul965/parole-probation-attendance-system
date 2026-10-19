<?php

use App\Http\Controllers\Api\AdminDeviceController;
use App\Http\Controllers\Api\DeviceLocationController;
use App\Http\Controllers\Api\OfficerTrackingController;
use App\Http\Middleware\AuthenticateDevice;
use Illuminate\Support\Facades\Route;

// IoT device endpoint — Bearer token or X-Device-Token header
Route::middleware(['throttle:device', AuthenticateDevice::class])
    ->post('/device/location', [DeviceLocationController::class, 'store']);

// Officer tracking (requires Sanctum / session auth)
Route::middleware(['auth:sanctum'])->prefix('officer')->group(function () {
    Route::get('/parolees/{paroleeId}/device', [OfficerTrackingController::class, 'latestDevice']);
    Route::get('/parolees/{paroleeId}/location/latest', [OfficerTrackingController::class, 'latestLocation']);
    Route::get('/parolees/{paroleeId}/location/history', [OfficerTrackingController::class, 'locationHistory']);

    // Device management (officers only)
    Route::get('/devices', [AdminDeviceController::class, 'index']);
    Route::post('/devices', [AdminDeviceController::class, 'store']);
    Route::get('/devices/{deviceId}', [AdminDeviceController::class, 'show']);
    Route::post('/devices/{deviceId}/assign', [AdminDeviceController::class, 'assign']);
    Route::patch('/devices/{deviceId}/status', [AdminDeviceController::class, 'updateStatus']);
    Route::post('/devices/{deviceId}/rotate-token', [AdminDeviceController::class, 'rotateToken']);
    Route::get('/devices/{deviceId}/locations', [AdminDeviceController::class, 'locationLogs']);
});
