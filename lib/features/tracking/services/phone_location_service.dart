import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:last/core/constants/firestore_collections.dart';
import 'package:last/core/constants/tracking_config.dart';
import 'package:last/core/utils/app_logger.dart';
import 'package:last/core/utils/firebase_config.dart';
import 'package:last/features/tracking/models/location_record.dart';

class PhoneLocationException implements Exception {
  PhoneLocationException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Foreground GPS sharing from the signed-in parolee's phone into location_records.
class PhoneLocationService {
  PhoneLocationService._();
  static final PhoneLocationService instance = PhoneLocationService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Timer? _timer;
  String? _paroleeId;
  DateTime? lastSentAt;
  String? lastError;
  void Function()? onUpdate;
  Position? _lastPosition;

  bool get isSharing => _timer != null && _paroleeId != null;

  Future<void> start(String paroleeId) async {
    final uid = fb.FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw PhoneLocationException('Sign in as a parolee to share location.');
    }
    if (paroleeId != uid) {
      throw PhoneLocationException('You can only share location for your own account.');
    }
    if (!FirebaseConfig.canUseFirestore) {
      throw PhoneLocationException('Firestore is not configured.');
    }

    await _ensurePermission();
    _paroleeId = uid;
    lastError = null;
    _timer?.cancel();
    await _publish();
    _timer = Timer.periodic(const Duration(seconds: 45), (_) async {
      try {
        lastError = null;
        await _publish();
      } catch (e, st) {
        lastError = e.toString();
        AppLogger.e('PhoneLocationService', 'Periodic publish failed', e, st);
      }
      onUpdate?.call();
    });
    onUpdate?.call();
    AppLogger.d('PhoneLocationService', 'Sharing started', uid);
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _paroleeId = null;
    AppLogger.d('PhoneLocationService', 'Sharing stopped');
    onUpdate?.call();
  }

  Future<void> _ensurePermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw PhoneLocationException('Turn on location services, then try again.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw PhoneLocationException('Location permission was denied.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw PhoneLocationException(
        'Location permission is blocked. Enable it in system settings.',
      );
    }
  }

  Future<void> _publish() async {
    final uid = _paroleeId ?? fb.FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      stop();
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      if (pos.latitude.abs() < 0.0001 && pos.longitude.abs() < 0.0001) {
        throw PhoneLocationException('GPS does not have a valid fix yet.');
      }

      final now = DateTime.now();
      if (_lastPosition != null &&
          lastSentAt != null &&
          now.difference(lastSentAt!) < TrackingConfig.duplicateLocationWindow) {
        final d = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          pos.latitude,
          pos.longitude,
        );
        if (d < 8) return;
      }

      final id = const Uuid().v4();
      final record = LocationRecord(
        id: id,
        trackerId: 'phone_$uid',
        paroleeId: uid,
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
        altitude: pos.altitude,
        speed: pos.speed.isNaN ? null : pos.speed,
        heading: pos.heading.isNaN ? null : pos.heading,
        recordedAt: now,
        receivedAt: now,
        createdAt: now,
        source: GpsSource.mobile,
      );

      await _db.collection(FirestoreCollections.locationRecords).doc(id).set(record.toMap());
      _lastPosition = pos;
      lastSentAt = now;
      AppLogger.d('PhoneLocationService', 'Location saved', '$uid ${pos.latitude}');
    } on PhoneLocationException {
      rethrow;
    } on TimeoutException {
      throw PhoneLocationException('Timed out waiting for GPS. Try outdoors.');
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw PhoneLocationException(
          'Could not save location (permission denied). Deploy firestore.rules for mobile GPS.',
        );
      }
      throw PhoneLocationException(e.message ?? e.code);
    } catch (e) {
      throw PhoneLocationException(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}
