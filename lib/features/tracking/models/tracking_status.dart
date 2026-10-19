enum TrackingStatus {
  active,
  offline,
  gpsUnavailable,
  lowBattery,
  noTracker,
  unknown;

  String get label => switch (this) {
        TrackingStatus.active => 'Online',
        TrackingStatus.offline => 'OFFLINE',
        TrackingStatus.gpsUnavailable => 'GPS UNAVAILABLE',
        TrackingStatus.lowBattery => 'LOW BATTERY',
        TrackingStatus.noTracker => 'NO TRACKER',
        TrackingStatus.unknown => 'UNKNOWN',
      };

  bool get isLive => this == TrackingStatus.active;
}

enum TrackingAlertType {
  trackerOffline,
  geofenceViolation,
  lowBattery,
  gpsFailure,
  checkInProximity;

  String get title => switch (this) {
        TrackingAlertType.trackerOffline => 'Tracker Offline',
        TrackingAlertType.geofenceViolation => 'Geofence Alert',
        TrackingAlertType.lowBattery => 'Low Battery',
        TrackingAlertType.gpsFailure => 'GPS Signal Lost',
        TrackingAlertType.checkInProximity => 'Check-in Proximity',
      };
}
