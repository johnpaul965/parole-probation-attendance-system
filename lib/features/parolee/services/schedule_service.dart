import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:last/core/constants/firestore_collections.dart';
import 'package:last/core/utils/error_handler.dart';
import 'package:last/core/utils/firebase_config.dart';
import 'package:last/features/shared/models/schedule_model.dart';

class ScheduleService {
  ScheduleService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<ScheduleModel>> watchForParolee(String paroleeId) {
    if (!FirebaseConfig.canUseFirestore) {
      return Stream.value([]);
    }
    return _db
        .collection(FirestoreCollections.schedules)
        .where('paroleeId', isEqualTo: paroleeId)
        .snapshots()
        .map(_mapSchedules);
  }

  Stream<List<ScheduleModel>> watchForOfficer(String officerId) {
    return _db
        .collection(FirestoreCollections.schedules)
        .where('officerId', isEqualTo: officerId)
        .snapshots()
        .map(_mapSchedules);
  }

  Future<ScheduleModel?> getNextForParolee(String paroleeId) async {
    try {
      final list = await watchForParolee(paroleeId).first;
      final now = DateTime.now();
      final upcoming = list.where((s) => s.scheduledAt.isAfter(now)).toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return upcoming.isEmpty ? null : upcoming.first;
    } catch (e) {
      throw ErrorHandler.wrap(e, 'Failed to load schedule');
    }
  }

  List<ScheduleModel> _mapSchedules(QuerySnapshot<Map<String, dynamic>> snap) {
    final list = snap.docs
        .map((d) => ScheduleModel.fromMap({...d.data(), 'id': d.id}))
        .toList();
    list.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return list;
  }
}
