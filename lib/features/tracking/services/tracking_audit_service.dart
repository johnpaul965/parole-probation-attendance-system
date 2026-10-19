import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:last/core/constants/firestore_collections.dart';
import 'package:last/core/utils/firebase_config.dart';
import 'package:uuid/uuid.dart';

class TrackingAuditService {
  TrackingAuditService({FirebaseFirestore? firestore})
      : _db = firestore ?? _safeInit();

  static FirebaseFirestore? _safeInit() {
    if (!FirebaseConfig.canUseFirestore) return null;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  final FirebaseFirestore? _db;

  Future<void> logSupervisionPeriodUpdated({
    required String paroleeId,
    required String actorId,
    required String actorRole,
    required Map<String, dynamic> metadata,
  }) async {
    final db = _db;
    if (db == null || !FirebaseConfig.canUseFirestore) return;
    try {
      final id = const Uuid().v4();
      await db.collection(FirestoreCollections.trackingAuditLogs).doc(id).set({
        'id': id,
        'action': 'supervision_period_updated',
        'paroleeId': paroleeId,
        'actorId': actorId,
        'actorRole': actorRole,
        'metadata': metadata,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> logAction({
    required String action,
    required String paroleeId,
    required String actorId,
    required String actorRole,
    Map<String, dynamic>? metadata,
  }) async {
    final db = _db;
    if (db == null || !FirebaseConfig.canUseFirestore) return;
    try {
      final id = const Uuid().v4();
      await db.collection(FirestoreCollections.trackingAuditLogs).doc(id).set({
        'id': id,
        'action': action,
        'paroleeId': paroleeId,
        'actorId': actorId,
        'actorRole': actorRole,
        'metadata': metadata ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }
}
