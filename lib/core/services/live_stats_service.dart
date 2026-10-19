import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:last/core/constants/firestore_collections.dart';
import 'package:last/core/utils/app_logger.dart';
import 'package:last/core/utils/firebase_config.dart';
import 'package:last/features/officer/models/live_stats.dart';
import 'package:last/features/officer/models/parolee_summary.dart';
import 'package:last/features/shared/models/attendance_record.dart';

class LiveStatsService {
  LiveStatsService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<void> publish(String officerId, List<ParoleeSummary> parolees) async {
    if (!FirebaseConfig.canUseFirestore || officerId.isEmpty) return;
    try {
      final live = LiveStats.fromDashboard(parolees);
      await _db.collection(FirestoreCollections.liveStats).doc(officerId).set(
            live.toMap(),
            SetOptions(merge: true),
          );
      AppLogger.d('LiveStatsService', 'Published live_stats for $officerId');
    } on FirebaseException catch (e, st) {
      AppLogger.e('LiveStatsService', 'publish FirebaseException ${e.code}', e.message, st);
      rethrow;
    } catch (e, st) {
      AppLogger.e('LiveStatsService', 'publish failed', e, st);
      rethrow;
    }
  }

  Future<void> syncParoleeStatus({
    required String paroleeId,
    required AttendanceStatus status,
  }) async {
    if (!FirebaseConfig.canUseFirestore) return;
    try {
      await _db.collection(FirestoreCollections.users).doc(paroleeId).set({
        'todayStatus': status.name,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, st) {
      AppLogger.e('LiveStatsService', 'syncParoleeStatus failed', e, st);
    }
  }

  Stream<LiveStats?> watchOfficer(String officerId) {
    if (!FirebaseConfig.canUseFirestore || officerId.isEmpty) {
      return Stream.value(null);
    }
    return _db.collection(FirestoreCollections.liveStats).doc(officerId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      try {
        return LiveStats.fromMap(snap.data()!);
      } catch (e, st) {
        AppLogger.e('LiveStatsService', 'Parse live_stats failed', e, st);
        return null;
      }
    });
  }

  Stream<List<LiveStats>> watchAll() {
    if (!FirebaseConfig.canUseFirestore) {
      return Stream.value([]);
    }
    return _db.collection(FirestoreCollections.liveStats).snapshots().map((snap) {
      final list = <LiveStats>[];
      for (final doc in snap.docs) {
        try {
          list.add(LiveStats.fromMap(doc.data()));
        } catch (e) {
          AppLogger.e('LiveStatsService', 'Skip invalid live_stats ${doc.id}', e);
        }
      }
      return list;
    });
  }
}
