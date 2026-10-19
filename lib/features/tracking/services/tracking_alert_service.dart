import 'package:last/core/constants/tracking_config.dart';
import 'package:last/core/services/notification_service.dart';
import 'package:last/features/shared/models/notification_model.dart';
import 'package:last/features/tracking/models/tracking_status.dart';
import 'package:last/features/tracking/services/tracking_audit_service.dart';

class TrackingAlertService {
  TrackingAlertService({
    NotificationService? notificationService,
    TrackingAlertCooldownService? cooldownService,
  })  : _notifications = notificationService ?? createNotificationService(),
        _cooldown = cooldownService ?? createTrackingAlertCooldownService();

  final NotificationService _notifications;
  final TrackingAlertCooldownService _cooldown;

  Future<void> sendTrackerOffline({
    required String officerId,
    required String paroleeName,
    required String trackerId,
    required DateTime? lastSeen,
  }) async {
    if (!await _cooldown.shouldSendAlert(alertType: 'tracker_offline', trackerId: trackerId)) {
      return;
    }
    final lastSeenText = lastSeen != null
        ? '${lastSeen.hour.toString().padLeft(2, '0')}:${lastSeen.minute.toString().padLeft(2, '0')}'
        : 'unknown';
    await _notifications.send(
      userId: officerId,
      title: TrackingAlertType.trackerOffline.title,
      body: "$paroleeName's tracker has stopped sending location data.\nLast seen: $lastSeenText",
      type: NotificationType.alert,
    );
  }

  Future<void> sendGeofenceViolation({
    required String officerId,
    required String paroleeName,
    required String trackerId,
  }) async {
    if (!await _cooldown.shouldSendAlert(alertType: 'geofence_violation', trackerId: trackerId)) {
      return;
    }
    await _notifications.send(
      userId: officerId,
      title: TrackingAlertType.geofenceViolation.title,
      body: '$paroleeName has exited the assigned monitoring area.',
      type: NotificationType.alert,
    );
  }

  Future<void> sendLowBattery({
    required String officerId,
    required String paroleeName,
    required String trackerId,
    required int batteryLevel,
  }) async {
    if (!await _cooldown.shouldSendAlert(alertType: 'low_battery', trackerId: trackerId)) {
      return;
    }
    await _notifications.send(
      userId: officerId,
      title: TrackingAlertType.lowBattery.title,
      body: "$paroleeName's tracker battery is at $batteryLevel%.",
      type: NotificationType.alert,
    );
  }

  Future<void> sendGpsFailure({
    required String officerId,
    required String paroleeName,
    required String trackerId,
  }) async {
    if (!await _cooldown.shouldSendAlert(alertType: 'gps_failure', trackerId: trackerId)) {
      return;
    }
    await _notifications.send(
      userId: officerId,
      title: TrackingAlertType.gpsFailure.title,
      body: 'The tracker for $paroleeName is connected but cannot obtain a valid GPS position.',
      type: NotificationType.alert,
    );
  }

  /// Officer alert when a parolee enters the check-in proximity radius.
  /// Duplicate suppression is owned by [CheckInProximityNotifier] so a genuine
  /// leave-and-re-enter is not blocked by a cooldown window.
  Future<void> sendCheckInProximity({
    required String officerId,
    required String paroleeName,
    required String paroleeId,
    required String trackerId,
    required double distanceMeters,
    required String locationName,
    DateTime? timestamp,
    bool isSimulated = false,
  }) async {
    final dist = distanceMeters.round();
    final radius = TrackingConfig.checkInProximityRadiusMeters.round();
    final timeText = timestamp != null
        ? '${timestamp.hour.toString().padLeft(2, '0')}:'
            '${timestamp.minute.toString().padLeft(2, '0')}'
        : null;
    final simNote = isSimulated ? ' [Simulated GPS]' : '';
    final body = StringBuffer(
      'Parolee $paroleeName is within $radius meters of the assigned check-in location.',
    )
      ..writeln()
      ..writeln('Parolee ID: $paroleeId')
      ..writeln('Distance: ${dist}m')
      ..writeln('Location: $locationName');
    if (timeText != null) {
      body.writeln('Time: $timeText');
    }
    if (simNote.isNotEmpty) {
      body.writeln(simNote.trim());
    }

    await _notifications.send(
      userId: officerId,
      title: TrackingAlertType.checkInProximity.title,
      body: body.toString().trim(),
      type: NotificationType.alert,
    );
  }
}

TrackingAlertService createTrackingAlertService() => TrackingAlertService();
