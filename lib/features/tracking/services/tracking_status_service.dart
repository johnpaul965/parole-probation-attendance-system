import 'package:last/core/constants/tracking_config.dart';
import 'package:last/features/tracking/models/gps_tracker.dart';
import 'package:last/features/tracking/models/location_record.dart';
import 'package:last/features/tracking/models/tracking_status.dart';

class TrackingStatusService {
  TrackingStatus resolve({
    GpsTracker? tracker,
    LocationRecord? latestLocation,
    DateTime? now,
  }) {
    final location = latestLocation;
    final hasHardware = tracker != null && tracker.isAssigned;

    if (!hasHardware) {
      if (location == null) {
        return TrackingStatus.noTracker;
      }
      return _fromLocation(location, batteryFallback: null, now: now);
    }

    if (location == null) {
      if (_isOffline(tracker.lastSeenAt, now: now)) {
        return TrackingStatus.offline;
      }
      return TrackingStatus.unknown;
    }

    return _fromLocation(location, batteryFallback: tracker.batteryLevel, now: now);
  }

  TrackingStatus _fromLocation(
    LocationRecord location, {
    required int? batteryFallback,
    DateTime? now,
  }) {
    if (!location.hasValidCoordinates ||
        (location.latitude == 0 && location.longitude == 0)) {
      return TrackingStatus.gpsUnavailable;
    }

    final battery = location.batteryLevel ?? batteryFallback;
    if (battery != null && battery < TrackingConfig.lowBatteryThreshold) {
      return TrackingStatus.lowBattery;
    }

    final recordedAt = location.recordedAt ?? location.receivedAt;
    if (_isOffline(recordedAt, now: now)) {
      return TrackingStatus.offline;
    }

    return TrackingStatus.active;
  }

  bool _isOffline(DateTime? lastSeen, {DateTime? now}) {
    if (lastSeen == null) return true;
    final reference = now ?? DateTime.now();
    return reference.difference(lastSeen) > TrackingConfig.offlineTimeout;
  }
}
