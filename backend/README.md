# IoT GPS Tracking API (Laravel)

REST API for Arduino/ESP32 GPS devices and officer tracking endpoints.

## Setup

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan serve
```

## Device Authentication

Devices authenticate with:
- `device_id` in JSON body or `X-Device-Id` header
- API token via `Authorization: Bearer <token>` or `X-Device-Token` header

Tokens are hashed (`api_token_hash`) in the database. Plain tokens are shown only once at device registration or credential rotation.

## Device Location Endpoint

```http
POST /api/device/location
Authorization: Bearer <device_api_token>
Content-Type: application/json

{
  "device_id": "DEV-000001",
  "latitude": 11.2445,
  "longitude": 125.0031,
  "accuracy": 5.2,
  "speed": 2.4,
  "battery_level": 78,
  "timestamp": "2026-08-31T01:30:00+08:00"
}
```

The backend determines the assigned parolee from the authenticated `device_id`. Never trust `parolee_id` from the device payload.

## Officer Endpoints

Requires authenticated officer (Laravel Sanctum).

| Method | Endpoint |
|--------|----------|
| GET | `/api/officer/parolees/{paroleeId}/device` |
| GET | `/api/officer/parolees/{paroleeId}/location/latest` |
| GET | `/api/officer/parolees/{paroleeId}/location/history` |
| GET | `/api/officer/devices` |
| POST | `/api/officer/devices` |
| GET | `/api/officer/devices/{deviceId}` |
| POST | `/api/officer/devices/{deviceId}/assign` |
| PATCH | `/api/officer/devices/{deviceId}/status` |
| POST | `/api/officer/devices/{deviceId}/rotate-token` |
| GET | `/api/officer/devices/{deviceId}/locations` |

Officers receive `403 Forbidden` when accessing parolees not assigned to them.

## Configuration (`config/tracking.php`)

| Key | Default | Description |
|-----|---------|-------------|
| `offline_threshold_minutes` | 2 | Online if `last_seen_at` within threshold |
| `low_battery_threshold` | 20 | Low battery alert threshold (%) |
| `alert_cooldown_minutes` | 60 | Alert deduplication window |
| `location_retention_days` | 90 | Historical GPS retention |
| `duplicate_location_window_seconds` | 30 | Reject duplicate coordinates |

## Flutter Integration

The Flutter app uses Firebase Firestore as its primary backend. This Laravel API is the standardized REST layer for IoT hardware. Configure `TRACKING_API_BASE_URL` in Flutter when deploying the Laravel backend alongside Firebase.
