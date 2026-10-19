import 'dart:async';

import 'package:last/features/auth/models/app_user.dart';
import 'package:last/features/tracking/models/geofence.dart';
import 'package:last/features/tracking/models/gps_tracker.dart';
import 'package:last/features/tracking/models/location_record.dart';
import 'package:last/features/tracking/models/parolee_tracking_summary.dart';

abstract class TrackingRepository {
  Stream<List<ParoleeTrackingSummary>> watchAssignedParolees({
    required AppUser requester,
    required String officerId,
  });

  Stream<ParoleeTrackingSummary> watchParoleeTracking({
    required AppUser requester,
    required String paroleeId,
  });

  Future<LocationRecord?> getLatestLocation({
    required AppUser requester,
    required String paroleeId,
  });

  Future<List<LocationRecord>> getLocationHistory({
    required AppUser requester,
    required String paroleeId,
    DateTime? start,
    DateTime? end,
    int limit = 50,
    String? startAfterId,
  });

  Future<GpsTracker?> getTrackerForParolee(String paroleeId);

  Future<List<Geofence>> getGeofencesForParolee(String paroleeId);

  /// Device endpoint — validates device token before storing location.
  Future<void> submitLocation({
    required String trackerId,
    required String deviceToken,
    required LocationRecord location,
  });

  void dispose();
}
