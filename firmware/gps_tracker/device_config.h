/**
 * GPS Tracker Firmware — PPA-TAC (Supabase REST API)
 * Configured for direct HTTPS PostgREST calls to Supabase.
 */

#ifndef DEVICE_CONFIG_H
#define DEVICE_CONFIG_H

#define TRACKER_ID "TRK-001"
#define DEVICE_ID TRACKER_ID

// Supabase Configuration
#define SUPABASE_URL "https://iqltrfkyzbeepfpmsxci.supabase.co"
#define SUPABASE_ANON_KEY "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlxbHRyZmt5emJlZXBmcG1zeGNpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIyMTg1OTUsImV4cCI6MjEwNzc5NDU5NX0.aYfh--wAJP1Fua_VrqgXn5kKIaVE-jnK9ZqqVrBTgIU"

// Skip TLS certificate validation on ESP32 development hardware
#define USE_INSECURE_TLS 1

// Adaptive transmission intervals (milliseconds)
#define INTERVAL_MOVING_MS 30000
#define INTERVAL_NORMAL_MS 60000
#define INTERVAL_STATIONARY_MS 120000

#define MOVING_SPEED_KMH 3.0

// Hardware Pin Configuration
#define GPS_RX_PIN 16
#define GPS_TX_PIN 17
#define GSM_RX_PIN 18
#define GSM_TX_PIN 19
#define BATTERY_ADC_PIN 34

#define MAX_QUEUE_SIZE 20

#endif
