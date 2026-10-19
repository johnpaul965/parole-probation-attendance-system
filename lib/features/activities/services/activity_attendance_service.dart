import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:last/core/constants/firestore_collections.dart';
import 'package:last/core/utils/firebase_config.dart';
import 'package:last/features/activities/models/activity_attendance_record.dart';
import 'package:last/features/activities/models/activity_model.dart';
import 'package:last/features/activities/models/activity_qr_payload.dart';
import 'package:last/features/activities/services/activity_qr_service.dart';
import 'package:last/features/auth/models/app_user.dart';
import 'package:last/features/auth/models/user_role.dart';
import 'package:last/features/shared/models/notification_model.dart';
import 'package:uuid/uuid.dart';

class ActivityScanResult {
  const ActivityScanResult.success(this.record) : error = null;
  const ActivityScanResult.failure(this.error) : record = null;

  final ActivityAttendanceRecord? record;
  final String? error;

  bool get isSuccess => record != null;
}

class ActivityAttendanceService {
  ActivityAttendanceService({
    FirebaseFirestore? firestore,
    ActivityQrService? qrService,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _qrService = qrService ?? ActivityQrService();

  final FirebaseFirestore _db;
  final ActivityQrService _qrService;

  Stream<List<ActivityAttendanceRecord>> watchForActivity(String activityId) {
    if (!FirebaseConfig.canUseFirestore) return Stream.value([]);
    return _db
        .collection(FirestoreCollections.activityAttendance)
        .where('activityId', isEqualTo: activityId)
        .snapshots()
        .map((snap) => _mapDocs(snap.docs));
  }

  Stream<List<ActivityAttendanceRecord>> watchForParolee(String paroleeId) {
    if (!FirebaseConfig.canUseFirestore) return Stream.value([]);
    return _db
        .collection(FirestoreCollections.activityAttendance)
        .where('paroleeId', isEqualTo: paroleeId)
        .snapshots()
        .map((snap) => _mapDocs(snap.docs));
  }

  Stream<List<ActivityAttendanceRecord>> watchAll() {
    if (!FirebaseConfig.canUseFirestore) return Stream.value([]);
    return _db.collection(FirestoreCollections.activityAttendance).snapshots().map(
          (snap) => _mapDocs(snap.docs),
        );
  }

  Stream<ActivityAttendanceStats> watchStatsForActivity(String activityId) {
    return watchForActivity(activityId).map(_computeStats);
  }

  ActivityAttendanceStats _computeStats(List<ActivityAttendanceRecord> list) {
    return ActivityAttendanceStats(
      present: list.where((r) => r.status == ActivityParticipationStatus.present).length,
      absent: list.where((r) => r.status == ActivityParticipationStatus.absent).length,
      late: list.where((r) => r.status == ActivityParticipationStatus.late).length,
      pending: list.where((r) => r.status == ActivityParticipationStatus.pending).length,
      total: list.length,
    );
  }

  Future<ActivityAttendanceRecord?> getForParoleeActivity(
    String activityId,
    String paroleeId,
  ) async {
    final snap = await _db
        .collection(FirestoreCollections.activityAttendance)
        .where('activityId', isEqualTo: activityId)
        .where('paroleeId', isEqualTo: paroleeId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return ActivityAttendanceRecord.fromMap({...snap.docs.first.data(), 'id': snap.docs.first.id});
  }

  Future<ActivityScanResult> scanAndMark({
    required String rawQr,
    required AppUser officer,
    required String expectedActivityId,
    required ActivityParticipationStatus status,
    required ActivityModel activity,
  }) async {
    if (!FirebaseConfig.canUseFirestore) {
      return const ActivityScanResult.failure('Firebase is not configured');
    }
    if (officer.role != UserRole.officer) {
      return const ActivityScanResult.failure('Only officers can mark activity attendance');
    }

    final decoded = ActivityQrPayload.decode(rawQr);
    if (decoded == null || decoded.token.isEmpty) {
      return const ActivityScanResult.failure('Invalid QR code format');
    }
    var payload = await _qrService.resolveFromScan(
      token: decoded.token,
      activityId: expectedActivityId,
    );
    if (payload == null && decoded.paroleeId.isNotEmpty) {
      final ok = await _qrService.validateToken(decoded);
      if (ok) payload = decoded;
    }
    if (payload == null) {
      return const ActivityScanResult.failure('QR code is invalid or was not issued for this activity.');
    }
    if (payload.activityId != expectedActivityId) {
      return const ActivityScanResult.failure('QR code is for a different activity');
    }
    if (payload.officerId.isNotEmpty && payload.officerId != officer.id) {
      return const ActivityScanResult.failure('This QR is not assigned to you');
    }
    if (!activity.isAssignedTo(payload.paroleeId)) {
      return const ActivityScanResult.failure('Parolee is not assigned to this activity');
    }

    final existing = await getForParoleeActivity(expectedActivityId, payload.paroleeId);
    if (existing != null &&
        existing.status.countsAsPresent &&
        status.countsAsPresent) {
      return ActivityScanResult.failure(
        '${existing.paroleeName} is already marked ${existing.status.label}',
      );
    }

    try {
      final now = DateTime.now();
      final id = existing?.id ?? const Uuid().v4();
      final record = ActivityAttendanceRecord(
        id: id,
        activityId: expectedActivityId,
        paroleeId: payload.paroleeId,
        paroleeName: payload.paroleeName,
        officerId: officer.id,
        status: status,
        scannedAt: now,
        verifiedByOfficer: true,
        timestamp: payload.timestamp,
        activityTitle: activity.title,
      );

      await _db.collection(FirestoreCollections.activityAttendance).doc(id).set(record.toMap());

      await _syncActivityCompletion(activity, payload.paroleeId, status);

      await _notify(
        userId: payload.paroleeId,
        title: 'Activity Attendance Recorded',
        body: 'Your attendance for ${activity.title} was marked ${status.label} by your officer.',
        type: NotificationType.success,
      );

      return ActivityScanResult.success(record);
    } catch (e) {
      return ActivityScanResult.failure('Failed to save attendance: $e');
    }
  }

  Future<void> _syncActivityCompletion(
    ActivityModel activity,
    String paroleeId,
    ActivityParticipationStatus status,
  ) async {
    final completed = List<String>.from(activity.completedParoleeIds);
    if (status.countsAsPresent) {
      if (!completed.contains(paroleeId)) completed.add(paroleeId);
    } else if (status == ActivityParticipationStatus.absent) {
      completed.remove(paroleeId);
    }

    var activityStatus = activity.status;
    if (completed.length >= activity.assignedParoleeIds.length &&
        activity.assignedParoleeIds.isNotEmpty) {
      activityStatus = ActivityStatus.completed;
    } else if (activity.status == ActivityStatus.pending) {
      activityStatus = ActivityStatus.ongoing;
    }

    await _db.collection(FirestoreCollections.activities).doc(activity.id).update({
      'completedParolees': completed,
      'status': activityStatus.name,
    });
  }

  List<ActivityAttendanceRecord> _mapDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final list = docs
        .map((d) => ActivityAttendanceRecord.fromMap({...d.data(), 'id': d.id}))
        .toList();
    list.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    return list;
  }

  Future<void> _notify({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
  }) async {
    if (userId.isEmpty) return;
    final id = const Uuid().v4();
    await _db.collection(FirestoreCollections.notifications).doc(id).set({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'createdAt': DateTime.now().toIso8601String(),
      'read': false,
    });
  }
}
