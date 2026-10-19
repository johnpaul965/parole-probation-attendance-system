import 'package:last/features/tracking/models/check_in_proximity.dart';
import 'package:last/features/tracking/models/geofence.dart';
import 'package:last/features/tracking/models/gps_tracker.dart';
import 'package:last/features/tracking/models/location_record.dart';
import 'package:last/features/tracking/models/tracking_status.dart';

class ParoleeTrackingSummary {
  const ParoleeTrackingSummary({
    required this.paroleeId,
    required this.fullName,
    required this.caseNumber,
    required this.officerId,
    required this.trackingStatus,
    this.tracker,
    this.latestLocation,
    this.geofenceStatus = GeofenceStatus.noGeofence,
    this.geofences = const [],
    this.assignedOfficerName,
    this.checkInProximity = CheckInProximityResult.gpsUnavailable,
  });

  final String paroleeId;
  final String fullName;
  final String caseNumber;
  final String officerId;
  final TrackingStatus trackingStatus;
  final GpsTracker? tracker;
  final LocationRecord? latestLocation;
  final GeofenceStatus geofenceStatus;
  final List<Geofence> geofences;
  final String? assignedOfficerName;
  final CheckInProximityResult checkInProximity;

  String? get trackerId => tracker?.id;
  int? get batteryLevel => latestLocation?.batteryLevel ?? tracker?.batteryLevel;
  double? get accuracy => latestLocation?.accuracy;
  DateTime? get lastUpdated => latestLocation?.recordedAt ?? tracker?.lastSeenAt;
}

class TrackingDashboardStats {
  const TrackingDashboardStats({
    required this.totalAssigned,
    required this.activeTrackers,
    required this.offlineTrackers,
    required this.recentAlerts,
  });

  final int totalAssigned;
  final int activeTrackers;
  final int offlineTrackers;
  final int recentAlerts;
}
