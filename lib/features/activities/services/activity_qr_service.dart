import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:last/core/constants/firestore_collections.dart';
import 'package:last/core/utils/app_logger.dart';
import 'package:last/core/utils/firebase_config.dart';
import 'package:last/features/activities/models/activity_model.dart';
import 'package:last/features/activities/models/activity_qr_payload.dart';
import 'package:uuid/uuid.dart';

class ActivityQrException implements Exception {
  ActivityQrException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ActivityQrService {
  ActivityQrService({
    FirebaseFirestore? firestore,
    fb.FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? fb.FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final fb.FirebaseAuth _auth;

  String _tokenDocId(String activityId, String paroleeId) => '${activityId}_$paroleeId';

  Future<ActivityQrPayload> generateForActivity({
    required ActivityModel activity,
    required String paroleeId,
    required String paroleeName,
    String? officerIdOverride,
    bool rotate = false,
  }) async {
    AppLogger.d('ActivityQrService', 'generateForActivity', '${activity.id} / $paroleeId');

    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw ActivityQrException('You are not signed in. Sign in again to view your QR code.');
    }
    if (paroleeId.isEmpty) {
      throw ActivityQrException('Parolee account ID is missing. Sign out and sign in again.');
    }
    if (paroleeId != uid) {
      throw ActivityQrException('This QR can only be generated for the signed-in parolee account.');
    }

    if (!activity.isAssignedTo(uid)) {
      throw ActivityQrException('You are not assigned to this activity.');
    }
    if (activity.status == ActivityStatus.missed) {
      throw ActivityQrException('This activity was marked missed. QR is no longer available.');
    }
    if (activity.status == ActivityStatus.completed) {
      throw ActivityQrException('This activity is completed. QR is no longer available.');
    }

    final officerId = _resolveOfficerId(activity, officerIdOverride);
    if (officerId.isEmpty) {
      throw ActivityQrException(
        'No supervising officer is linked to this activity. Contact your PPA office.',
      );
    }

    if (!FirebaseConfig.canUseFirestore) {
      return _localPayload(
        activity: activity,
        paroleeId: uid,
        paroleeName: paroleeName,
        officerId: officerId,
      );
    }

    await _requireParoleeProfile(uid);
    await _verifyActivityDoc(activity.id, uid);

    final docId = _tokenDocId(activity.id, uid);
    final ref = _db.collection(FirestoreCollections.activityQrTokens).doc(docId);
    final now = DateTime.now();

    try {
      if (!rotate) {
        final existing = await _readOwnToken(ref);
        if (existing != null && existing.exists) {
          final reused = _payloadFromDoc(
            existing,
            activity: activity,
            paroleeId: uid,
            paroleeName: paroleeName,
            officerId: officerId,
            fallbackTime: now,
          );
          if (reused != null) {
            AppLogger.d('ActivityQrService', 'Reusing saved token', docId);
            return reused;
          }
        }
      }

      final token = const Uuid().v4();
      final issuedAt = now;
      final data = <String, dynamic>{
        'activityId': activity.id,
        'paroleeId': uid,
        'paroleeName': paroleeName,
        'officerId': officerId,
        'assignedOfficerId': officerId,
        'activityTitle': activity.title,
        'token': token,
        'issuedAt': issuedAt.toIso8601String(),
      };

      try {
        await ref.set(data);
      } on FirebaseException catch (e) {
        if (e.code == 'already-exists') {
          final raced = await _readOwnToken(ref);
          final reused = raced != null && raced.exists
              ? _payloadFromDoc(
                  raced,
                  activity: activity,
                  paroleeId: uid,
                  paroleeName: paroleeName,
                  officerId: officerId,
                  fallbackTime: now,
                )
              : null;
          if (reused != null) return reused;
        }
        rethrow;
      }

      AppLogger.d('ActivityQrService', 'Token saved', docId);
      final payload = ActivityQrPayload(
        paroleeId: uid,
        paroleeName: paroleeName,
        activityId: activity.id,
        assignedOfficerId: officerId,
        activityTitle: activity.title,
        token: token,
        timestamp: issuedAt,
      );
      payload.encode();
      return payload;
    } on ActivityQrException {
      rethrow;
    } on FirebaseException catch (e) {
      AppLogger.e('ActivityQrService', 'Firestore error ${e.code}', e.message);
      throw ActivityQrException(_mapFirebaseError(e));
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _readOwnToken(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    try {
      return await ref.get();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw ActivityQrException(
          'Cannot read QR token (permission denied). Confirm you are signed in as a parolee and that Firestore rules for activity_qr_tokens are deployed.',
        );
      }
      throw ActivityQrException(_mapFirebaseError(e));
    }
  }

  ActivityQrPayload? _payloadFromDoc(
    DocumentSnapshot<Map<String, dynamic>> existing, {
    required ActivityModel activity,
    required String paroleeId,
    required String paroleeName,
    required String officerId,
    required DateTime fallbackTime,
  }) {
    final data = existing.data();
    if (data == null) return null;
    final token = data['token'] as String? ?? '';
    final storedParolee = data['paroleeId'] as String? ?? '';
    final storedActivity = data['activityId'] as String? ?? '';
    if (token.isEmpty || storedParolee != paroleeId || storedActivity != activity.id) {
      return null;
    }
    return ActivityQrPayload(
      paroleeId: paroleeId,
      paroleeName: paroleeName,
      activityId: activity.id,
      assignedOfficerId: officerId,
      activityTitle: activity.title,
      token: token,
      timestamp: DateTime.tryParse(data['issuedAt'] as String? ?? '') ?? fallbackTime,
    );
  }

  Future<void> _requireParoleeProfile(String uid) async {
    DocumentSnapshot<Map<String, dynamic>> doc;
    try {
      doc = await _db.collection(FirestoreCollections.users).doc(uid).get();
    } on FirebaseException catch (e) {
      throw ActivityQrException(_mapFirebaseError(e));
    }
    if (!doc.exists) {
      throw ActivityQrException(
        'Your user profile was not found in Firestore (users/$uid). Contact your PPA office.',
      );
    }
    final role = doc.data()?['role'] as String? ?? '';
    if (role != 'parolee') {
      throw ActivityQrException(
        'QR codes are only available to parolee accounts. This profile role is "$role".',
      );
    }
  }

  Future<void> _verifyActivityDoc(String activityId, String paroleeId) async {
    DocumentSnapshot<Map<String, dynamic>> doc;
    try {
      doc = await _db.collection(FirestoreCollections.activities).doc(activityId).get();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw ActivityQrException('You are not assigned to this activity.');
      }
      throw ActivityQrException(_mapFirebaseError(e));
    }
    if (!doc.exists) {
      throw ActivityQrException('Activity not found in Firestore.');
    }
    final assigned = List<String>.from(doc.data()?['assignedParolees'] as List? ?? []);
    if (!assigned.contains(paroleeId)) {
      throw ActivityQrException('You are not assigned to this activity.');
    }
  }

  String _mapFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Cannot save QR token (permission denied). Deploy firestore.rules and confirm your account role is parolee.';
      case 'unavailable':
      case 'deadline-exceeded':
      case 'network-request-failed':
        return 'Could not reach Firebase. Check your internet connection and try again.';
      case 'unauthenticated':
        return 'You are not signed in. Sign in again to view your QR code.';
      case 'not-found':
        return 'QR token or related record was not found.';
      default:
        return 'Failed to generate QR: ${e.message ?? e.code}';
    }
  }

  String _resolveOfficerId(ActivityModel activity, String? override) {
    if (override != null && override.isNotEmpty) return override;
    if (activity.assignedOfficerId.isNotEmpty) return activity.assignedOfficerId;
    return '';
  }

  ActivityQrPayload _localPayload({
    required ActivityModel activity,
    required String paroleeId,
    required String paroleeName,
    required String officerId,
  }) {
    AppLogger.d('ActivityQrService', 'Offline/local QR payload');
    return ActivityQrPayload(
      paroleeId: paroleeId,
      paroleeName: paroleeName,
      activityId: activity.id,
      assignedOfficerId: officerId,
      activityTitle: activity.title,
      token: const Uuid().v4(),
      timestamp: DateTime.now(),
    );
  }

  Future<bool> validateToken(ActivityQrPayload payload) async {
    final resolved = await resolveFromScan(
      token: payload.token,
      activityId: payload.activityId,
    );
    return resolved != null &&
        (payload.paroleeId.isEmpty || resolved.paroleeId == payload.paroleeId);
  }

  /// Looks up a scanned token in Firestore. Names and IDs come from the saved
  /// token record, not from the QR payload.
  Future<ActivityQrPayload?> resolveFromScan({
    required String token,
    required String activityId,
  }) async {
    if (token.isEmpty) return null;
    if (!FirebaseConfig.canUseFirestore) return null;

    QuerySnapshot<Map<String, dynamic>> snap;
    if (activityId.isNotEmpty) {
      snap = await _db
          .collection(FirestoreCollections.activityQrTokens)
          .where('token', isEqualTo: token)
          .where('activityId', isEqualTo: activityId)
          .limit(1)
          .get();
    } else {
      snap = await _db
          .collection(FirestoreCollections.activityQrTokens)
          .where('token', isEqualTo: token)
          .limit(1)
          .get();
    }
    if (snap.docs.isEmpty) return null;
    final data = snap.docs.first.data();
    return ActivityQrPayload(
      paroleeId: data['paroleeId'] as String? ?? '',
      paroleeName: data['paroleeName'] as String? ?? '',
      activityId: data['activityId'] as String? ?? activityId,
      assignedOfficerId:
          data['assignedOfficerId'] as String? ?? data['officerId'] as String? ?? '',
      activityTitle: data['activityTitle'] as String? ?? '',
      token: data['token'] as String? ?? token,
      timestamp: DateTime.tryParse(data['issuedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
