import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:last/core/constants/firestore_collections.dart';
import 'package:last/core/constants/tracking_config.dart';
import 'package:last/core/utils/error_handler.dart';
import 'package:last/features/auth/models/app_user.dart';
import 'package:last/features/auth/models/user_role.dart';
import 'package:last/features/tracking/models/geofence.dart';
import 'package:last/features/tracking/models/gps_tracker.dart';
import 'package:last/features/tracking/models/location_record.dart';
import 'package:last/features/tracking/models/parolee_tracking_summary.dart';
import 'package:last/features/tracking/services/check_in_proximity_service.dart';
import 'package:last/features/tracking/services/geofence_evaluation_service.dart';
import 'package:last/features/tracking/services/location_validation_service.dart';
import 'package:last/features/tracking/services/tracking_audit_service.dart';
import 'package:last/features/tracking/services/tracking_authorization_service.dart';
import 'package:last/features/tracking/services/tracking_repository.dart';
import 'package:last/features/tracking/services/tracking_status_service.dart';
import 'package:uuid/uuid.dart';
class FirebaseTrackingRepository implements TrackingRepository {
  FirebaseTrackingRepository({
    FirebaseFirestore? firestore,
    TrackingAuthorizationService? authService,
    TrackingStatusService? statusService,
    GeofenceEvaluationService? geofenceService,
    LocationValidationService? validationService,
    TrackingAuditService? auditService,
    CheckInProximityService? proximityService,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = authService ?? TrackingAuthorizationService(),
        _status = statusService ?? TrackingStatusService(),
        _geofence = geofenceService ?? GeofenceEvaluationService(),
        _validation = validationService ?? LocationValidationService(),
        _audit = auditService ?? TrackingAuditService(),
        _proximity = proximityService ?? CheckInProximityService();

  final FirebaseFirestore _db;
  final TrackingAuthorizationService _auth;
  final TrackingStatusService _status;
  final GeofenceEvaluationService _geofence;
  final LocationValidationService _validation;
  final TrackingAuditService _audit;
  final CheckInProximityService _proximity;

  @override
  Stream<List<ParoleeTrackingSummary>> watchAssignedParolees({
    required AppUser requester,
    required String officerId,
  }) {
    if (requester.role != UserRole.officer || requester.id != officerId) {
      return Stream.error(
        TrackingAuthorizationException('You are not authorized to view these parolees.'),
      );
    }

    final controller = StreamController<List<ParoleeTrackingSummary>>();
    final subscriptions = <StreamSubscription<dynamic>>[];

    Future<void> emit() async {
      if (controller.isClosed) return;
      try {
        final summaries = await _loadAssignedSummaries(requester, officerId);
        if (!controller.isClosed) controller.add(summaries);
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    void attach(String field) {
      subscriptions.add(
        _db
            .collection(FirestoreCollections.users)
            .where(field, isEqualTo: officerId)
            .snapshots()
            .listen((_) => emit(), onError: controller.addError),
      );
    }

    attach('officerId');
    attach('assignedOfficerId');
    subscriptions.add(
      _db.collection(FirestoreCollections.gpsTrackers).snapshots().listen(
            (_) => emit(),
            onError: controller.addError,
          ),
    );
    subscriptions.add(
      _db
          .collection(FirestoreCollections.locationRecords)
          .orderBy('recordedAt', descending: true)
          .limit(200)
          .snapshots()
          .listen((_) => emit(), onError: controller.addError),
    );

    emit();

    controller.onCancel = () async {
      for (final sub in subscriptions) {
        await sub.cancel();
      }
    };

    return controller.stream;
  }

  @override
  Stream<ParoleeTrackingSummary> watchParoleeTracking({
    required AppUser requester,
    required String paroleeId,
  }) {
    final controller = StreamController<ParoleeTrackingSummary>();
    final subscriptions = <StreamSubscription<dynamic>>[];

    Future<void> emit() async {
      if (controller.isClosed) return;
      try {
        final summary = await _buildSummary(requester, paroleeId);
        if (!controller.isClosed) controller.add(summary);
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    subscriptions.add(
      _db.collection(FirestoreCollections.users).doc(paroleeId).snapshots().listen(
            (_) => emit(),
            onError: controller.addError,
          ),
    );
    subscriptions.add(
      _db
          .collection(FirestoreCollections.locationRecords)
          .where('paroleeId', isEqualTo: paroleeId)
          .orderBy('recordedAt', descending: true)
          .limit(1)
          .snapshots()
          .listen((_) => emit(), onError: controller.addError),
    );
    subscriptions.add(
      _db
          .collection(FirestoreCollections.gpsTrackers)
          .where('paroleeId', isEqualTo: paroleeId)
          .limit(1)
          .snapshots()
          .listen((_) => emit(), onError: controller.addError),
    );

    emit();

    controller.onCancel = () async {
      for (final sub in subscriptions) {
        await sub.cancel();
      }
    };

    return controller.stream;
  }

  @override
  Future<LocationRecord?> getLatestLocation({
    required AppUser requester,
    required String paroleeId,
  }) async {
    final parolee = await _getParoleeOrThrow(requester, paroleeId);
    _auth.assertCanTrack(requester, parolee);

    await _audit.logTrackingAccess(
      paroleeId: paroleeId,
      actorId: requester.id,
      actorRole: requester.role.name,
      endpoint: 'location_latest',
    );

    final snap = await _db
        .collection(FirestoreCollections.locationRecords)
        .where('paroleeId', isEqualTo: paroleeId)
        .orderBy('recordedAt', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return LocationRecord.fromMap({...snap.docs.first.data(), 'id': snap.docs.first.id});
  }

  @override
  Future<List<LocationRecord>> getLocationHistory({
    required AppUser requester,
    required String paroleeId,
    DateTime? start,
    DateTime? end,
    int limit = TrackingConfig.locationHistoryPageSize,
    String? startAfterId,
  }) async {
    final parolee = await _getParoleeOrThrow(requester, paroleeId);
    _auth.assertCanTrack(requester, parolee);

    await _audit.logTrackingAccess(
      paroleeId: paroleeId,
      actorId: requester.id,
      actorRole: requester.role.name,
      endpoint: 'location_history',
    );

    Query<Map<String, dynamic>> query = _db
        .collection(FirestoreCollections.locationRecords)
        .where('paroleeId', isEqualTo: paroleeId)
        .orderBy('recordedAt', descending: true);

    if (start != null) {
      query = query.where('recordedAt', isGreaterThanOrEqualTo: start.toIso8601String());
    }
    if (end != null) {
      query = query.where('recordedAt', isLessThanOrEqualTo: end.toIso8601String());
    }

    if (startAfterId != null) {
      final cursor = await _db
          .collection(FirestoreCollections.locationRecords)
          .doc(startAfterId)
          .get();
      if (cursor.exists) {
        query = query.startAfterDocument(cursor);
      }
    }

    final snap = await query.limit(limit).get();
    return snap.docs
        .map((d) => LocationRecord.fromMap({...d.data(), 'id': d.id}))
        .toList();
  }

  @override
  Future<GpsTracker?> getTrackerForParolee(String paroleeId) async {
    final snap = await _db
        .collection(FirestoreCollections.gpsTrackers)
        .where('paroleeId', isEqualTo: paroleeId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return GpsTracker.fromMap({...snap.docs.first.data(), 'id': snap.docs.first.id});
  }

  @override
  Future<List<Geofence>> getGeofencesForParolee(String paroleeId) async {
    final snap = await _db
        .collection(FirestoreCollections.geofences)
        .where('paroleeId', isEqualTo: paroleeId)
        .get();
    return snap.docs
        .map((d) => Geofence.fromMap({...d.data(), 'id': d.id}))
        .toList();
  }

  @override
  Future<void> submitLocation({
    required String trackerId,
    required String deviceToken,
    required LocationRecord location,
  }) async {
    final trackerDoc = await _db.collection(FirestoreCollections.gpsTrackers).doc(trackerId).get();
    if (!trackerDoc.exists) {
      throw ErrorHandler.wrap(Exception('Tracker not found'), 'Invalid tracker');
    }

    final trackerData = trackerDoc.data()!;
    final storedToken = trackerData['deviceToken'] as String? ?? '';
    if (storedToken.isEmpty || storedToken != deviceToken) {
      throw ErrorHandler.wrap(Exception('Invalid device token'), 'Device authentication failed');
    }

    final status = trackerData['status'] as String? ?? '';
    if (status == 'inactive' || status == 'maintenance') {
      throw ErrorHandler.wrap(Exception('Device inactive'), 'Device is not accepting locations');
    }

    final paroleeId = trackerData['paroleeId'] as String?;
    if (paroleeId == null || paroleeId.isEmpty) {
      throw ErrorHandler.wrap(Exception('Tracker unassigned'), 'Tracker is not assigned to a parolee');
    }

    if (!_validation.isValidCoordinates(location.latitude, location.longitude)) {
      throw ErrorHandler.wrap(Exception('Invalid coordinates'), 'Location payload invalid');
    }

    final recordedAt = location.recordedAt ?? DateTime.now();
    final latest = await _fetchLatestLocation(paroleeId);
    if (latest != null &&
        _validation.isDuplicate(
          existing: latest,
          latitude: location.latitude,
          longitude: location.longitude,
          recordedAt: recordedAt,
          window: TrackingConfig.duplicateLocationWindow,
        )) {
      return; // Silently skip duplicate
    }

    if (_validation.isImpossibleJump(
      previous: latest,
      latitude: location.latitude,
      longitude: location.longitude,
      recordedAt: recordedAt,
    )) {
      throw ErrorHandler.wrap(Exception('Impossible jump'), 'Location rejected as implausible');
    }

    final now = DateTime.now();
    final id = const Uuid().v4();
    final record = {
      ...location.copyWith(
        id: id,
        trackerId: trackerId,
        paroleeId: paroleeId,
        receivedAt: now,
        createdAt: now,
      ).toMap(),
      'recordedAt': (location.recordedAt ?? now).toIso8601String(),
    };

    await _db.collection(FirestoreCollections.locationRecords).doc(id).set(record);
    await trackerDoc.reference.update({
      'batteryLevel': location.batteryLevel,
      'lastSeenAt': now.toIso8601String(),
      'status': TrackerDeviceStatus.active.name,
      'updatedAt': now.toIso8601String(),
    });
  }

  @override
  void dispose() {}

  Future<List<ParoleeTrackingSummary>> _loadAssignedSummaries(
    AppUser requester,
    String officerId,
  ) async {
    final results = await Future.wait([
      _db.collection(FirestoreCollections.users).where('officerId', isEqualTo: officerId).get(),
      _db
          .collection(FirestoreCollections.users)
          .where('assignedOfficerId', isEqualTo: officerId)
          .get(),
    ]);

    final merged = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final snap in results) {
      for (final doc in snap.docs) {
        if ((doc.data()['role'] as String? ?? '') == 'parolee') {
          merged[doc.id] = doc;
        }
      }
    }

    final summaries = <ParoleeTrackingSummary>[];
    for (final doc in merged.values) {
      summaries.add(await _buildSummary(requester, doc.id));
    }
    summaries.sort((a, b) => a.fullName.compareTo(b.fullName));
    return summaries;
  }

  Future<ParoleeTrackingSummary> _buildSummary(
    AppUser requester,
    String paroleeId,
  ) async {
    final parolee = await _getParoleeOrThrow(requester, paroleeId);
    if (requester.role == UserRole.officer) {
      _auth.assertCanTrack(requester, parolee);
    }

    final tracker = await getTrackerForParolee(paroleeId);
    final latest = await _fetchLatestLocation(paroleeId);
    final geofences = await getGeofencesForParolee(paroleeId);
    final geofenceStatus = _geofence.evaluate(location: latest, geofences: geofences);
    final trackingStatus = _status.resolve(tracker: tracker, latestLocation: latest);
    final checkInProximity = _proximity.evaluate(
      isAuthorized: tracker != null && tracker.isAssigned,
      tracker: tracker,
      location: latest,
      geofences: geofences,
      isSimulated: latest?.isSimulated == true,
    );

    return ParoleeTrackingSummary(
      paroleeId: paroleeId,
      fullName: parolee.fullName,
      caseNumber: parolee.caseNumber ?? 'N/A',
      officerId: parolee.officerId ?? '',
      trackingStatus: trackingStatus,
      tracker: tracker,
      latestLocation: latest,
      geofenceStatus: geofenceStatus,
      geofences: geofences,
      checkInProximity: checkInProximity,
    );
  }

  Future<AppUser> _getParoleeOrThrow(AppUser requester, String paroleeId) async {
    final doc = await _db.collection(FirestoreCollections.users).doc(paroleeId).get();
    if (!doc.exists) {
      throw TrackingAuthorizationException('Parolee not found.');
    }
    return AppUser.fromMap({...doc.data()!, 'id': doc.id});
  }

  Future<LocationRecord?> _fetchLatestLocation(String paroleeId) async {
    final snap = await _db
        .collection(FirestoreCollections.locationRecords)
        .where('paroleeId', isEqualTo: paroleeId)
        .orderBy('recordedAt', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return LocationRecord.fromMap({...snap.docs.first.data(), 'id': snap.docs.first.id});
  }
}

extension on LocationRecord {
  LocationRecord copyWith({
    String? id,
    String? trackerId,
    String? paroleeId,
    DateTime? receivedAt,
    DateTime? createdAt,
  }) {
    return LocationRecord(
      id: id ?? this.id,
      trackerId: trackerId ?? this.trackerId,
      paroleeId: paroleeId ?? this.paroleeId,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      altitude: altitude,
      speed: speed,
      heading: heading,
      batteryLevel: batteryLevel,
      recordedAt: recordedAt,
      receivedAt: receivedAt ?? this.receivedAt,
      createdAt: createdAt ?? this.createdAt,
      source: source,
    );
  }
}
