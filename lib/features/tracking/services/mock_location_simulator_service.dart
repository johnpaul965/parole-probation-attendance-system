import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:last/core/constants/firestore_collections.dart';
import 'package:last/core/constants/tracking_config.dart';
import 'package:last/core/utils/app_config.dart';
import 'package:last/features/tracking/models/location_record.dart';
import 'package:last/features/tracking/services/firebase_tracking_repository.dart';

/// Development-only service that simulates GPS hardware submitting locations
/// into Firestore. Isolated from production — only runs in debug builds.
class MockLocationSimulatorService {
  MockLocationSimulatorService({
    FirebaseFirestore? firestore,
    FirebaseTrackingRepository? repository,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _repository = repository ?? FirebaseTrackingRepository();

  final FirebaseFirestore _db;
  final FirebaseTrackingRepository _repository;
  final _random = math.Random(42);
  Timer? _timer;
  int _tick = 0;

  static MockLocationSimulatorService? _instance;

  static void startIfEnabled() {
    if (!AppConfig.enableMockLocationSimulator) return;
    _instance ??= MockLocationSimulatorService();
    _instance!._start();
  }

  static void stop() {
    _instance?._timer?.cancel();
    _instance = null;
  }

  void _start() {
    if (_timer != null) return;
    debugPrint('[MockLocationSimulator] Started — simulating GPS device submissions');
    _timer = Timer.periodic(TrackingConfig.mockUpdateInterval, (_) => _submitAll());
    _submitAll();
  }

  Future<void> _submitAll() async {
    _tick++;
    if (FirebaseAuth.instance.currentUser == null) {
      return;
    }
    try {
      final snap = await _db.collection(FirestoreCollections.gpsTrackers).get();

      for (final doc in snap.docs) {
        final data = doc.data();
        final paroleeId = data['paroleeId'] as String?;
        final deviceToken = data['deviceToken'] as String? ?? '';
        if (paroleeId == null || deviceToken.isEmpty) continue;

        // Simulate one offline tracker (TRK-002 pattern) for demo scenarios.
        if (doc.id.endsWith('-002')) continue;

        final angle = _tick * 0.3 + doc.id.hashCode * 0.01;
        final orbit = TrackingConfig.mockProximityOrbitDegrees;
        final offsetLat = math.sin(angle) * orbit;
        final offsetLng = math.cos(angle) * orbit;
        final battery = 75 + (_tick % 10);

        final location = LocationRecord(
          id: '',
          trackerId: doc.id,
          paroleeId: paroleeId,
          latitude: TrackingConfig.mockBaseLatitude + offsetLat,
          longitude: TrackingConfig.mockBaseLongitude + offsetLng,
          accuracy: 4.0 + _random.nextDouble() * 3,
          speed: 2.0 + _random.nextDouble() * 4,
          batteryLevel: battery,
          recordedAt: DateTime.now(),
          source: GpsSource.simulated,
        );

        await _repository.submitLocation(
          trackerId: doc.id,
          deviceToken: deviceToken,
          location: location,
        );
      }
    } catch (e) {
      debugPrint('[MockLocationSimulator] Submission error: $e');
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
