import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:last/core/constants/firestore_collections.dart';
import 'package:last/core/constants/tracking_config.dart';
import 'package:last/core/utils/firebase_config.dart';

/// Audit log for device assignments and officer tracking access.
class TrackingAuditService {
  TrackingAuditService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<void> logDeviceAssignment({
    required String action,
    required String trackerId,
    String? paroleeId,
    String? actorId,
    String? actorRole,
    Map<String, dynamic>? metadata,
  }) async {
    await _db.collection(FirestoreCollections.trackingAuditLogs).add({
      'action': action,
      'resourceType': 'device',
      'resourceId': trackerId,
      'paroleeId': paroleeId,
      'actorId': actorId,
      'actorRole': actorRole,
      'metadata': metadata,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> logSupervisionPeriodUpdated({
    required String paroleeId,
    required String actorId,
    required String actorRole,
    Map<String, dynamic>? metadata,
  }) async {
    await _db.collection(FirestoreCollections.trackingAuditLogs).add({
      'action': 'supervision_period_updated',
      'resourceType': 'parolee',
      'resourceId': paroleeId,
      'paroleeId': paroleeId,
      'actorId': actorId,
      'actorRole': actorRole,
      'metadata': metadata,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> logTrackingAccess({
    required String paroleeId,
    required String actorId,
    required String actorRole,
    required String endpoint,
  }) async {
    await _db.collection(FirestoreCollections.trackingAuditLogs).add({
      'action': 'tracking_access',
      'resourceType': 'parolee',
      'resourceId': paroleeId,
      'actorId': actorId,
      'actorRole': actorRole,
      'metadata': {'endpoint': endpoint},
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}

/// Prevents duplicate alert spam with configurable cooldown.
///
/// When Firestore is unavailable (tests / mock data), alerts are allowed
/// through. Check-in proximity still uses [CheckInProximityNotifier] so
/// entry events are not blocked by this cooldown.
class TrackingAlertCooldownService {
  TrackingAlertCooldownService({FirebaseFirestore? firestore}) : _db = firestore;

  final FirebaseFirestore? _db;

  Future<bool> shouldSendAlert({
    required String alertType,
    required String trackerId,
    String? paroleeId,
    Duration? cooldown,
  }) async {
    final db = _db;
    if (db == null) return true;

    final window = cooldown ?? Duration(minutes: TrackingConfig.alertCooldownMinutes);
    final docId = '${alertType}_${trackerId}_${paroleeId ?? 'none'}';
    final ref = db.collection(FirestoreCollections.trackingAlertCooldowns).doc(docId);
    final snap = await ref.get();
    final now = DateTime.now();

    if (snap.exists) {
      final lastSent = DateTime.tryParse(snap.data()?['lastSentAt'] as String? ?? '');
      if (lastSent != null && now.difference(lastSent) < window) {
        return false;
      }
    }

    await ref.set({'lastSentAt': now.toIso8601String(), 'alertType': alertType});
    return true;
  }
}

TrackingAuditService createTrackingAuditService() => TrackingAuditService();

TrackingAlertCooldownService createTrackingAlertCooldownService() {
  if (FirebaseConfig.canUseFirestore) {
    return TrackingAlertCooldownService(firestore: FirebaseFirestore.instance);
  }
  return TrackingAlertCooldownService();
}
