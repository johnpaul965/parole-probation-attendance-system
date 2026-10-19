import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:last/core/constants/firestore_collections.dart';
import 'package:last/core/utils/error_handler.dart';
import 'package:last/core/utils/firebase_config.dart';
import 'package:last/features/auth/models/app_user.dart';
import 'package:last/features/shared/models/attendance_record.dart';

abstract class AdminService {
  Stream<List<AppUser>> watchAllUsers();
  Future<List<AppUser>> getAllUsers();
  Future<void> assignOfficer(String paroleeId, String officerId);
  Future<void> removeOfficer(String paroleeId);
  Future<void> toggleUserActive(String userId, bool active);
  Future<void> createUser(AppUser user);
  Future<void> deleteUser(String userId);
  Future<double> computeComplianceRate();
  Stream<double> watchComplianceRate();
}

class FirebaseAdminService implements AdminService {
  FirebaseAdminService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Stream<List<AppUser>> watchAllUsers() {
    if (!FirebaseConfig.canUseFirestore) {
      return Stream.value([]);
    }
    return _db.collection(FirestoreCollections.users).snapshots().map((snap) {
      return snap.docs.map((d) => AppUser.fromMap({...d.data(), 'id': d.id})).toList();
    });
  }

  @override
  Future<List<AppUser>> getAllUsers() async {
    try {
      final snap = await _db.collection(FirestoreCollections.users).get();
      return snap.docs.map((d) => AppUser.fromMap({...d.data(), 'id': d.id})).toList();
    } catch (e) {
      throw ErrorHandler.wrap(e, 'Failed to load users');
    }
  }

  @override
  Future<void> assignOfficer(String paroleeId, String officerId) async {
    try {
      await _db.collection(FirestoreCollections.users).doc(paroleeId).update({
        'officerId': officerId,
        'assignedOfficerId': officerId,
      });
    } catch (e) {
      throw ErrorHandler.wrap(e, 'Failed to assign officer');
    }
  }

  @override
  Future<void> removeOfficer(String paroleeId) async {
    try {
      await _db.collection(FirestoreCollections.users).doc(paroleeId).update({
        'officerId': null,
        'assignedOfficerId': null,
      });
    } catch (e) {
      throw ErrorHandler.wrap(e, 'Failed to remove officer assignment');
    }
  }

  @override
  Future<void> toggleUserActive(String userId, bool active) async {
    try {
      await _db.collection(FirestoreCollections.users).doc(userId).update({'isActive': active});
    } catch (e) {
      throw ErrorHandler.wrap(e, 'Failed to update user status');
    }
  }

  @override
  Future<void> createUser(AppUser user) async {
    try {
      await _db.collection(FirestoreCollections.users).doc(user.id).set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw ErrorHandler.wrap(e, 'Failed to create user');
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    try {
      final batch = _db.batch();
      final trackers = await _db
          .collection(FirestoreCollections.gpsTrackers)
          .where('paroleeId', isEqualTo: userId)
          .get();
      for (final doc in trackers.docs) {
        batch.update(doc.reference, {
          'paroleeId': null,
          'paroleeName': null,
          'status': 'unassigned',
        });
      }
      batch.delete(_db.collection(FirestoreCollections.users).doc(userId));
      await batch.commit();
    } catch (e) {
      throw ErrorHandler.wrap(e, 'Failed to remove user');
    }
  }

  @override
  Future<double> computeComplianceRate() async {
    final attSnap = await _db.collection(FirestoreCollections.attendance).get();
    if (attSnap.docs.isEmpty) return 0;

    final records = attSnap.docs
        .map((d) => AttendanceRecord.fromMap({...d.data(), 'id': d.id}))
        .toList();

    final last30 = records.where((r) {
      final t = r.checkInTime ?? r.scheduledTime;
      if (t == null) return false;
      return t.isAfter(DateTime.now().subtract(const Duration(days: 30)));
    }).toList();

    if (last30.isEmpty) return 0;
    final compliant = last30.where((r) => r.status != AttendanceStatus.missed).length;
    return (compliant / last30.length) * 100;
  }

  @override
  Stream<double> watchComplianceRate() {
    if (!FirebaseConfig.canUseFirestore) {
      return Stream.value(0);
    }
    return _db.collection(FirestoreCollections.attendance).snapshots().asyncMap((_) => computeComplianceRate());
  }
}

AdminService createAdminService() => FirebaseAdminService();
