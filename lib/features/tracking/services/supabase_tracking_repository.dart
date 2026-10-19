import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:last/core/utils/supabase_config.dart';
import 'package:last/features/auth/models/app_user.dart';
import 'package:last/features/tracking/models/geofence.dart';
import 'package:last/features/tracking/models/gps_tracker.dart';
import 'package:last/features/tracking/models/location_record.dart';
import 'package:last/features/tracking/models/parolee_tracking_summary.dart';
import 'package:last/features/tracking/models/tracking_status.dart';
import 'package:last/features/tracking/services/mock_tracking_repository.dart';
import 'package:last/features/tracking/services/tracking_repository.dart';

class SupabaseTrackingRepository implements TrackingRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final MockTrackingRepository _fallback = MockTrackingRepository();

  @override
  Stream<List<ParoleeTrackingSummary>> watchAssignedParolees({
    required AppUser requester,
    required String officerId,
  }) {
    return _fallback.watchAssignedParolees(requester: requester, officerId: officerId);
  }

  @override
  Stream<ParoleeTrackingSummary> watchParoleeTracking({
    required AppUser requester,
    required String paroleeId,
  }) {
    final controller = StreamController<ParoleeTrackingSummary>.broadcast();

    // Subscribe to real-time location_logs sent by the ESP32 hardware
    final channel = _supabase
        .channel('public:location_logs:$paroleeId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'location_logs',
          callback: (payload) {
            final row = payload.newRecord;
            final loc = LocationRecord(
              id: row['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
              trackerId: row['tracker_id']?.toString() ?? 'TRK-001',
              paroleeId: paroleeId,
              latitude: (row['latitude'] as num).toDouble(),
              longitude: (row['longitude'] as num).toDouble(),
              accuracy: (row['accuracy'] as num?)?.toDouble() ?? 4.5,
              speed: (row['speed'] as num?)?.toDouble() ?? 0.0,
              batteryLevel: row['battery_level'] != null ? (row['battery_level'] as num).toInt() : null,
              recordedAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now(),
              source: GpsSource.esp32,
            );

            getTrackerForParolee(paroleeId).then((trk) {
              getGeofencesForParolee(paroleeId).then((gfs) {
                controller.add(ParoleeTrackingSummary(
                  paroleeId: paroleeId,
                  fullName: 'Juan Dela Cruz',
                  caseNumber: 'PP-2024-1847',
                  officerId: requester.id,
                  trackingStatus: TrackingStatus.active,
                  tracker: trk,
                  latestLocation: loc,
                  geofenceStatus: GeofenceStatus.inside,
                  geofences: gfs,
                ));
              });
            });
          },
        )
        .subscribe();

    _fallback.watchParoleeTracking(requester: requester, paroleeId: paroleeId).listen((summary) {
      controller.add(summary);
    });

    controller.onCancel = () {
      _supabase.removeChannel(channel);
    };

    return controller.stream;
  }

  @override
  Future<LocationRecord?> getLatestLocation({
    required AppUser requester,
    required String paroleeId,
  }) async {
    try {
      final res = await _supabase
          .from('location_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(1);
      if (res.isNotEmpty) {
        final row = res.first;
        return LocationRecord(
          id: row['id']?.toString() ?? '',
          trackerId: row['tracker_id']?.toString() ?? 'TRK-001',
          paroleeId: paroleeId,
          latitude: (row['latitude'] as num).toDouble(),
          longitude: (row['longitude'] as num).toDouble(),
          accuracy: (row['accuracy'] as num?)?.toDouble() ?? 4.5,
          speed: (row['speed'] as num?)?.toDouble() ?? 0.0,
          batteryLevel: row['battery_level'] != null ? (row['battery_level'] as num).toInt() : null,
          recordedAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now(),
          source: GpsSource.esp32,
        );
      }
    } catch (e) {
      debugPrint('[Supabase] getLatestLocation note: $e');
    }
    return _fallback.getLatestLocation(requester: requester, paroleeId: paroleeId);
  }

  @override
  Future<List<LocationRecord>> getLocationHistory({
    required AppUser requester,
    required String paroleeId,
    DateTime? start,
    DateTime? end,
    int limit = 50,
    String? startAfterId,
  }) async {
    try {
      final res = await _supabase
          .from('location_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      if (res.isNotEmpty) {
        return res.map((row) => LocationRecord(
          id: row['id']?.toString() ?? '',
          trackerId: row['tracker_id']?.toString() ?? 'TRK-001',
          paroleeId: paroleeId,
          latitude: (row['latitude'] as num).toDouble(),
          longitude: (row['longitude'] as num).toDouble(),
          accuracy: (row['accuracy'] as num?)?.toDouble() ?? 4.5,
          speed: (row['speed'] as num?)?.toDouble() ?? 0.0,
          batteryLevel: row['battery_level'] != null ? (row['battery_level'] as num).toInt() : null,
          recordedAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now(),
          source: GpsSource.esp32,
        )).toList();
      }
    } catch (e) {
      debugPrint('[Supabase] getLocationHistory note: $e');
    }
    return _fallback.getLocationHistory(requester: requester, paroleeId: paroleeId);
  }

  @override
  Future<GpsTracker?> getTrackerForParolee(String paroleeId) => _fallback.getTrackerForParolee(paroleeId);

  @override
  Future<List<Geofence>> getGeofencesForParolee(String paroleeId) => _fallback.getGeofencesForParolee(paroleeId);

  @override
  Future<void> submitLocation({
    required String trackerId,
    required String deviceToken,
    required LocationRecord location,
  }) async {
    await _supabase.from('location_logs').insert({
      'tracker_id': trackerId,
      'parolee_id': location.paroleeId,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'speed': location.speed,
      'accuracy': location.accuracy,
      'battery_level': location.batteryLevel,
    });
  }

  @override
  void dispose() {
    _fallback.dispose();
  }
}
