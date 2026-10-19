import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:last/core/constants/firestore_collections.dart';
import 'package:last/core/utils/error_handler.dart';
import 'package:last/core/utils/firebase_config.dart';
import 'package:last/core/utils/supabase_config.dart';
import 'package:last/core/utils/ticket_generator.dart';
import 'package:last/features/auth/models/app_user.dart';
import 'package:last/features/shared/models/attendance_record.dart';
import 'package:last/features/shared/models/notification_model.dart';
import 'package:last/core/services/live_stats_service.dart';
import 'package:last/features/shared/models/schedule_model.dart';
import 'package:uuid/uuid.dart';

abstract class AttendanceService {
  Stream<List<AttendanceRecord>> watchAttendance({String? officerId, String? paroleeId});
  Future<List<AttendanceRecord>> getAttendance({String? officerId, String? paroleeId});
  Future<AttendanceRecord> createCheckIn(AppUser parolee, {String? location});
  Future<AttendanceRecord> verifyQr(String qrPayload, AppUser officer);
  Future<void> updateStatus(String id, AttendanceStatus status);
}

class FirebaseAttendanceService implements AttendanceService {
  FirebaseAttendanceService({
    FirebaseFirestore? firestore,
    LiveStatsService? liveStatsService,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _liveStats = liveStatsService ?? LiveStatsService();

  final FirebaseFirestore _db;
  final LiveStatsService _liveStats;

  @override
  Stream<List<AttendanceRecord>> watchAttendance({String? officerId, String? paroleeId}) {
    if (!FirebaseConfig.canUseFirestore) {
      return Stream.value([]);
    }
    Query<Map<String, dynamic>> query = _db.collection(FirestoreCollections.attendance);
    if (officerId != null) {
      query = query.where('officerId', isEqualTo: officerId);
    }
    if (paroleeId != null) {
      query = query.where('paroleeId', isEqualTo: paroleeId);
    }
    return query.snapshots().map((snap) => _sortRecords(
          snap.docs.map((d) => AttendanceRecord.fromMap({...d.data(), 'id': d.id})).toList(),
        ));
  }

  @override
  Future<List<AttendanceRecord>> getAttendance({String? officerId, String? paroleeId}) async {
    if (!FirebaseConfig.canUseFirestore) return [];
    Query<Map<String, dynamic>> query = _db.collection(FirestoreCollections.attendance);
    if (officerId != null) query = query.where('officerId', isEqualTo: officerId);
    if (paroleeId != null) query = query.where('paroleeId', isEqualTo: paroleeId);
    final snap = await query.get();
    return _sortRecords(
      snap.docs.map((d) => AttendanceRecord.fromMap({...d.data(), 'id': d.id})).toList(),
    );
  }

  List<AttendanceRecord> _sortRecords(List<AttendanceRecord> list) {
    list.sort((a, b) => (b.checkInTime ?? DateTime(2000)).compareTo(a.checkInTime ?? DateTime(2000)));
    return list;
  }

  @override
  Future<AttendanceRecord> createCheckIn(AppUser parolee, {String? location}) async {
    if (!FirebaseConfig.canUseFirestore) {
      throw AppException('Configure Firebase to save check-ins');
    }
    final ticketId = TicketGenerator.generate();
    final id = const Uuid().v4();

    // Important: officerId must match the officer dashboard query.
    // If parolee.officerId is empty (e.g., profile doc not fully set), derive it from Firestore.
    String officerId = parolee.officerId ?? '';
    if (officerId.isEmpty) {
      final paroleeDoc = await _db.collection(FirestoreCollections.users).doc(parolee.id).get();
      final data = paroleeDoc.data();
      officerId = data?['officerId'] as String? ?? '';
    }
    if (officerId.isEmpty) {
      final schSnap = await _db
          .collection(FirestoreCollections.schedules)
          .where('paroleeId', isEqualTo: parolee.id)
          .get();
      final schedules = schSnap.docs
          .map((d) => ScheduleModel.fromMap({...d.data(), 'id': d.id}))
          .toList();
      schedules.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
      officerId = schedules.isEmpty ? '' : schedules.first.officerId;
    }

    if (officerId.isEmpty) {
      throw AppException(
        'No assigned officer found for this parolee. Ask an officer to assign you first.',
      );
    }
    final record = AttendanceRecord(
      id: id,
      ticketId: ticketId,
      paroleeId: parolee.id,
      paroleeName: parolee.fullName,
      officerId: officerId,
      status: AttendanceStatus.checkedIn,
      checkInTime: DateTime.now(),
      location: location ?? 'PPA District Office',
      qrPayload: 'PPA|$ticketId|${parolee.id}|${DateTime.now().millisecondsSinceEpoch}',
    );
    await _db.collection(FirestoreCollections.attendance).doc(id).set(record.toMap());
    await _liveStats.syncParoleeStatus(
      paroleeId: parolee.id,
      status: AttendanceStatus.checkedIn,
    );

    if (officerId.isNotEmpty) {
      await _sendNotification(
        userId: officerId,
        title: 'New Check-in',
        body: '${parolee.fullName} checked in with ticket $ticketId.',
        type: NotificationType.success,
      );
    }
    return record;
  }

  @override
  Future<AttendanceRecord> verifyQr(String qrPayload, AppUser officer) async {
    final parts = qrPayload.split('|');
    if (parts.length < 3 || parts[0] != 'PPA') {
      throw AppException('Invalid QR code');
    }
    final ticketId = parts[1];
    final snap = await _db
        .collection(FirestoreCollections.attendance)
        .where('ticketId', isEqualTo: ticketId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) throw AppException('Attendance record not found');
    final doc = snap.docs.first;
    final data = doc.data();
    await doc.reference.update({
      'verified': true,
      'status': AttendanceStatus.confirmed.name,
    });
    final paroleeId = data['paroleeId'] as String? ?? '';
    if (paroleeId.isNotEmpty) {
      await _liveStats.syncParoleeStatus(
        paroleeId: paroleeId,
        status: AttendanceStatus.confirmed,
      );
    }
    final record = AttendanceRecord.fromMap({
      ...data,
      'id': doc.id,
      'verified': true,
      'status': AttendanceStatus.confirmed.name,
    });
    await _sendNotification(
      userId: data['paroleeId'] as String? ?? '',
      title: 'Attendance Verified',
      body: 'Your check-in $ticketId was verified by ${officer.fullName}.',
      type: NotificationType.success,
    );
    final recordOfficerId = data['officerId'] as String? ?? officer.id;
    if (recordOfficerId.isNotEmpty) {
      await _sendNotification(
        userId: recordOfficerId,
        title: 'Check-in Confirmed',
        body: '${data['paroleeName'] ?? 'Parolee'} — $ticketId verified.',
        type: NotificationType.success,
      );
    }
    return record;
  }

  @override
  Future<void> updateStatus(String id, AttendanceStatus status) async {
    await _db.collection(FirestoreCollections.attendance).doc(id).update({'status': status.name});
  }

  Future<void> _sendNotification({
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

class SupabaseAttendanceService implements AttendanceService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final List<AttendanceRecord> _local = [];

  @override
  Stream<List<AttendanceRecord>> watchAttendance({String? officerId, String? paroleeId}) {
    if (SupabaseConfig.isConfigured) {
      try {
        return _supabase
            .from('attendance_records')
            .stream(primaryKey: ['id'])
            .map((rows) => rows.map((r) => AttendanceRecord(
                  id: r['id']?.toString() ?? '',
                  ticketId: r['ticket_id']?.toString() ?? '',
                  paroleeId: r['parolee_id']?.toString() ?? '',
                  paroleeName: r['parolee_name']?.toString() ?? 'Parolee',
                  officerId: r['officer_id']?.toString() ?? '',
                  status: AttendanceStatus.fromString(r['status']?.toString() ?? 'checkedIn'),
                  checkInTime: r['check_in_time'] != null ? DateTime.tryParse(r['check_in_time']) : null,
                  location: r['location']?.toString(),
                  verified: r['verified'] == true,
                )).toList());
      } catch (_) {}
    }
    return Stream.value(_local);
  }

  @override
  Future<List<AttendanceRecord>> getAttendance({String? officerId, String? paroleeId}) async {
    if (SupabaseConfig.isConfigured) {
      try {
        final rows = await _supabase.from('attendance_records').select();
        return (rows as List).map((r) => AttendanceRecord(
              id: r['id']?.toString() ?? '',
              ticketId: r['ticket_id']?.toString() ?? '',
              paroleeId: r['parolee_id']?.toString() ?? '',
              paroleeName: r['parolee_name']?.toString() ?? 'Parolee',
              officerId: r['officer_id']?.toString() ?? '',
              status: AttendanceStatus.fromString(r['status']?.toString() ?? 'checkedIn'),
              checkInTime: r['check_in_time'] != null ? DateTime.tryParse(r['check_in_time']) : null,
              location: r['location']?.toString(),
              verified: r['verified'] == true,
            )).toList();
      } catch (_) {}
    }
    return _local;
  }

  @override
  Future<AttendanceRecord> createCheckIn(AppUser parolee, {String? location}) async {
    final ticketId = TicketGenerator.generate();
    final rec = AttendanceRecord(
      id: const Uuid().v4(),
      ticketId: ticketId,
      paroleeId: parolee.id,
      paroleeName: parolee.fullName,
      officerId: parolee.officerId ?? '',
      status: AttendanceStatus.pending,
      scheduledTime: DateTime.now(),
      location: location ?? 'PPA Tacloban Office',
      verified: false,
    );
    _local.insert(0, rec);

    if (SupabaseConfig.isConfigured) {
      try {
        await _supabase.from('attendance_records').insert({
          'id': rec.id,
          'ticket_id': rec.ticketId,
          'parolee_id': rec.paroleeId,
          'parolee_name': rec.paroleeName,
          'officer_id': rec.officerId,
          'status': rec.status.name,
          'location': rec.location,
          'verified': false,
        });
      } catch (_) {}
    }
    return rec;
  }

  @override
  Future<AttendanceRecord> verifyQr(String qrPayload, AppUser officer) async {
    final ticketId = TicketGenerator.extractTicketId(qrPayload) ?? TicketGenerator.generate();
    final rec = AttendanceRecord(
      id: const Uuid().v4(),
      ticketId: ticketId,
      paroleeId: 'demo-parolee',
      paroleeName: 'Juan Dela Cruz',
      officerId: officer.id,
      status: AttendanceStatus.confirmed,
      checkInTime: DateTime.now(),
      location: 'PPA Tacloban Office',
      verified: true,
    );
    _local.insert(0, rec);

    if (SupabaseConfig.isConfigured) {
      try {
        await _supabase.from('attendance_records').insert({
          'id': rec.id,
          'ticket_id': rec.ticketId,
          'parolee_id': rec.paroleeId,
          'parolee_name': rec.paroleeName,
          'officer_id': rec.officerId,
          'status': rec.status.name,
          'check_in_time': rec.checkInTime?.toIso8601String(),
          'location': rec.location,
          'verified': true,
        });
      } catch (_) {}
    }
    return rec;
  }

  @override
  Future<void> updateStatus(String id, AttendanceStatus status) async {
    if (SupabaseConfig.isConfigured) {
      try {
        await _supabase.from('attendance_records').update({'status': status.name}).eq('id', id);
      } catch (_) {}
    }
  }
}

AttendanceService createAttendanceService() {
  if (SupabaseConfig.isConfigured) {
    return SupabaseAttendanceService();
  }
  return FirebaseAttendanceService();
}
