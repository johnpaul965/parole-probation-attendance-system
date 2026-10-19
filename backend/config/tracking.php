<?php

return [
  'offline_threshold_minutes' => (int) env('TRACKING_OFFLINE_THRESHOLD_MINUTES', 2),
  'low_battery_threshold' => (int) env('TRACKING_LOW_BATTERY_THRESHOLD', 20),
  'alert_cooldown_minutes' => (int) env('TRACKING_ALERT_COOLDOWN_MINUTES', 60),
  'location_retention_days' => (int) env('TRACKING_LOCATION_RETENTION_DAYS', 90),
  'duplicate_location_window_seconds' => (int) env('TRACKING_DUPLICATE_WINDOW_SECONDS', 30),
  'device_rate_limit_per_minute' => (int) env('TRACKING_DEVICE_RATE_LIMIT', 30),
];
