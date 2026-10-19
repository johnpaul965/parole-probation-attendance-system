import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:last/core/constants/firestore_collections.dart';
import 'package:last/core/utils/firebase_config.dart';
import 'package:last/features/activities/models/activity_model.dart';
import 'package:last/features/shared/models/notification_model.dart';
import 'package:uuid/uuid.dart';

class ActivityService {
  ActivityService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<ActivityModel>> watchForOfficer(String officerId) {
    if (!FirebaseConfig.canUseFirestore) return Stream.value([]);
    return _db
        .collection(FirestoreCollections.activities)
        .where('assignedOfficerId', isEqualTo: officerId)
        .snapshots()
        .asyncMap((snap) => _processActivities(snap.docs));
  }

  Stream<List<ActivityModel>> watchForParolee(String paroleeId) {
    if (!FirebaseConfig.canUseFirestore) return Stream.value([]);
    return _db
        .collection(FirestoreCollections.activities)
        .where('assignedParolees', arrayContains: paroleeId)
        .snapshots()
        .asyncMap((snap) async {
      final all = await _processActivities(snap.docs);
      all.sort((a, b) => a.scheduleDate.compareTo(b.scheduleDate));
      return all;
    });
  }

  Stream<List<ActivityModel>> watchAll({String? officerId, ActivityStatus? status, ActivityType? type}) {
    if (!FirebaseConfig.canUseFirestore) return Stream.value([]);
    return _db.collection(FirestoreCollections.activities).snapshots().asyncMap((snap) async {
      var list = await _processActivities(snap.docs);
      if (officerId != null && officerId.isNotEmpty) {
        list = list.where((a) => a.assignedOfficerId == officerId).toList();
      }
      if (status != null) {
        list = list.where((a) => a.status == status).toList();
      }
      if (type != null) {
        list = list.where((a) => a.type == type).toList();
      }
      return list;
    });
  }

  Stream<ActivityStats> watchStats({String? officerId}) {
    return watchAll(officerId: officerId).map((list) {
      return ActivityStats(
        total: list.length,
        ongoing: list.where((a) => a.status == ActivityStatus.ongoing).length,
        completed: list.where((a) => a.status == ActivityStatus.completed).length,
        missed: list.where((a) => a.status == ActivityStatus.missed).length,
        pending: list.where((a) => a.status == ActivityStatus.pending).length,
      );
    });
  }

  Future<ActivityModel> createActivity({
    required String title,
    required ActivityType type,
    required String description,
    required String location,
    required DateTime scheduleDate,
    required String officerId,
    required String officerName,
    required List<String> paroleeIds,
  }) async {
    final id = const Uuid().v4();
    final activity = ActivityModel(
      id: id,
      title: title,
      type: type,
      description: description,
      location: location,
      scheduleDate: scheduleDate,
      assignedParoleeIds: paroleeIds,
      assignedOfficerId: officerId,
      status: ActivityStatus.pending,
      createdAt: DateTime.now(),
      completedParoleeIds: const [],
      officerName: officerName,
    );
    await _db.collection(FirestoreCollections.activities).doc(id).set(activity.toMap());

    for (final pid in paroleeIds) {
      await _notify(
        userId: pid,
        title: 'New Activity Assigned',
        body: '$title on ${scheduleDate.toLocal()}',
        type: NotificationType.reminder,
      );
    }
    return activity;
  }

  Future<void> updateStatus(String activityId, ActivityStatus status) async {
    await _db.collection(FirestoreCollections.activities).doc(activityId).update({
      'status': status.name,
    });
  }

  Future<void> assignParolees(String activityId, List<String> paroleeIds) async {
    await _db.collection(FirestoreCollections.activities).doc(activityId).update({
      'assignedParolees': paroleeIds,
    });
  }

  Future<List<ActivityModel>> _processActivities(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final now = DateTime.now();
    final list = <ActivityModel>[];

    for (final doc in docs) {
      var activity = ActivityModel.fromMap({...doc.data(), 'id': doc.id});
      activity = _autoStatus(activity, now);
      if (activity.status != ActivityStatus.fromString(doc.data()['status'] as String? ?? '')) {
        await doc.reference.update({'status': activity.status.name});
      }
      list.add(activity);
    }
    list.sort((a, b) => b.scheduleDate.compareTo(a.scheduleDate));
    return list;
  }

  ActivityModel _autoStatus(ActivityModel activity, DateTime now) {
    if (activity.status == ActivityStatus.completed) return activity;
    if (activity.scheduleDate.isBefore(now.subtract(const Duration(hours: 2))) &&
        activity.completedParoleeIds.length < activity.assignedParoleeIds.length) {
      return activity.copyWith(status: ActivityStatus.missed);
    }
    if (_isSameDay(activity.scheduleDate, now) &&
        activity.status == ActivityStatus.pending) {
      return activity.copyWith(status: ActivityStatus.ongoing);
    }
    if (activity.completedParoleeIds.length >= activity.assignedParoleeIds.length &&
        activity.assignedParoleeIds.isNotEmpty) {
      return activity.copyWith(status: ActivityStatus.completed);
    }
    return activity;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

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

ActivityService createActivityService() => ActivityService();
