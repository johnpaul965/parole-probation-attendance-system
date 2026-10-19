import 'package:flutter_test/flutter_test.dart';
import 'package:last/features/tracking/models/check_in_proximity.dart';
import 'package:last/features/tracking/services/check_in_proximity_notifier.dart';

void main() {
  CheckInProximityResult inside({
    String? eventKey,
    String sessionId = '2026-10-12',
    double distance = 20,
  }) {
    return CheckInProximityResult(
      status: CheckInProximityStatus.inside,
      distanceMeters: distance,
      locationName: 'Office',
      locationId: 'loc-1',
      sessionId: sessionId,
      evaluatedAt: DateTime(2026, 10, 12, 10),
    );
  }

  const outside = CheckInProximityResult(
    status: CheckInProximityStatus.outside,
    distanceMeters: 80,
    locationName: 'Office',
    locationId: 'loc-1',
    sessionId: '2026-10-12',
  );

  const unverified = CheckInProximityResult(
    status: CheckInProximityStatus.locationUnverified,
    locationId: 'loc-1',
    sessionId: '2026-10-12',
  );

  const unavailable = CheckInProximityResult(
    status: CheckInProximityStatus.gpsUnavailable,
    locationId: 'loc-1',
    sessionId: '2026-10-12',
  );

  group('CheckInProximityNotifier', () {
    test('notifies once at 20 m entry', () {
      final n = CheckInProximityNotifier();
      expect(
        n.shouldNotify(paroleeId: 'p1', result: inside(), eventKey: 'e1'),
        isTrue,
      );
      expect(
        n.shouldNotify(paroleeId: 'p1', result: inside(distance: 20), eventKey: 'e2'),
        isFalse,
      );
    });

    test('notifies once at exactly 50 m entry', () {
      final n = CheckInProximityNotifier();
      expect(
        n.shouldNotify(
          paroleeId: 'p1',
          result: inside(distance: 50),
          eventKey: 'e1',
        ),
        isTrue,
      );
      expect(
        n.shouldNotify(
          paroleeId: 'p1',
          result: inside(distance: 50),
          eventKey: 'e2',
        ),
        isFalse,
      );
    });

    test('51 m outside does not notify', () {
      final n = CheckInProximityNotifier();
      expect(
        n.shouldNotify(paroleeId: 'p1', result: outside, eventKey: 'e1'),
        isFalse,
      );
    });

    test('remaining inside does not repeat notifications', () {
      final n = CheckInProximityNotifier();
      expect(n.shouldNotify(paroleeId: 'p1', result: inside(), eventKey: 'a'), isTrue);
      for (var i = 0; i < 10; i++) {
        expect(
          n.shouldNotify(
            paroleeId: 'p1',
            result: inside(distance: 20),
            eventKey: 'stay-$i',
          ),
          isFalse,
        );
      }
    });

    test('leave then re-enter notifies again', () {
      final n = CheckInProximityNotifier();
      expect(n.shouldNotify(paroleeId: 'p1', result: inside(), eventKey: 'in1'), isTrue);
      expect(n.shouldNotify(paroleeId: 'p1', result: outside, eventKey: 'out'), isFalse);
      expect(n.shouldNotify(paroleeId: 'p1', result: inside(), eventKey: 'in2'), isTrue);
    });

    test('invalid or stale GPS does not notify', () {
      final n = CheckInProximityNotifier();
      expect(n.shouldNotify(paroleeId: 'p1', result: unverified), isFalse);
      expect(n.shouldNotify(paroleeId: 'p1', result: unavailable), isFalse);
    });

    test('duplicate ESP32 / device message does not duplicate notify', () {
      final n = CheckInProximityNotifier();
      expect(
        n.shouldNotify(paroleeId: 'p1', result: inside(), eventKey: 'msg-1'),
        isTrue,
      );
      expect(
        n.shouldNotify(paroleeId: 'p1', result: inside(), eventKey: 'msg-1'),
        isFalse,
      );
    });

    test('two parolees notify independently', () {
      final n = CheckInProximityNotifier();
      expect(n.shouldNotify(paroleeId: 'p1', result: inside(), eventKey: 'a'), isTrue);
      expect(n.shouldNotify(paroleeId: 'p2', result: inside(), eventKey: 'b'), isTrue);
      expect(n.shouldNotify(paroleeId: 'p1', result: inside(), eventKey: 'c'), isFalse);
      expect(n.shouldNotify(paroleeId: 'p2', result: inside(), eventKey: 'd'), isFalse);
    });

    test('new check-in session resets latch and notifies again', () {
      final n = CheckInProximityNotifier();
      expect(
        n.shouldNotify(
          paroleeId: 'p1',
          result: inside(sessionId: '2026-10-12'),
          eventKey: 'd1',
        ),
        isTrue,
      );
      n.resetSession(paroleeId: 'p1', clearAllForParolee: true);
      expect(
        n.shouldNotify(
          paroleeId: 'p1',
          result: inside(sessionId: '2026-10-12'),
          eventKey: 'd2',
        ),
        isTrue,
      );
    });

    test('dump and restore latches suppress duplicate enter after restart', () {
      final n = CheckInProximityNotifier();
      expect(n.shouldNotify(paroleeId: 'p1', result: inside(), eventKey: 'e1'), isTrue);
      final dumped = n.dumpLatched();
      final restored = CheckInProximityNotifier();
      restored.restoreLatched(dumped);
      expect(
        restored.shouldNotify(paroleeId: 'p1', result: inside(), eventKey: 'e2'),
        isFalse,
      );
    });

    test('flaky unverified while inside does not reset latch', () {
      final n = CheckInProximityNotifier();
      expect(n.shouldNotify(paroleeId: 'p1', result: inside(), eventKey: 'a'), isTrue);
      expect(n.shouldNotify(paroleeId: 'p1', result: unverified), isFalse);
      expect(n.shouldNotify(paroleeId: 'p1', result: inside(), eventKey: 'b'), isFalse);
    });

    test('hydrate after restart suppresses duplicate enter alert', () {
      final n = CheckInProximityNotifier();
      n.hydrateNotifiedInside(
        paroleeId: 'p1',
        locationId: 'loc-1',
        sessionId: '2026-10-12',
        eventKey: 'prior',
      );
      expect(n.shouldNotify(paroleeId: 'p1', result: inside(), eventKey: 'new'), isFalse);
    });
  });
}
