import 'package:flutter_test/flutter_test.dart';
import 'package:last/features/auth/models/supervision_period.dart';

void main() {
  group('SupervisionPeriod', () {
    final today = DateTime(2026, 6, 15);

    test('not set when dates are missing', () {
      final snap = SupervisionPeriod.compute(now: today);
      expect(snap.status, SupervisionStatus.notSet);
      expect(snap.remainingDays, isNull);
    });

    test('invalid when end is before start', () {
      final snap = SupervisionPeriod.compute(
        startIso: '2026-06-20',
        endIso: '2026-06-10',
        now: today,
      );
      expect(snap.status, SupervisionStatus.invalid);
      expect(SupervisionPeriod.supervisionRangeError(snap.start, snap.end), isNotNull);
    });

    test('upcoming when start is in the future', () {
      final snap = SupervisionPeriod.compute(
        startIso: '2026-07-01',
        endIso: '2027-07-01',
        now: today,
      );
      expect(snap.status, SupervisionStatus.upcoming);
      expect(snap.remainingDays, isNull);
    });

    test('active when today is within the period', () {
      final snap = SupervisionPeriod.compute(
        startIso: '2026-01-15',
        endIso: '2028-01-15',
        now: today,
      );
      expect(snap.status, SupervisionStatus.active);
      expect(snap.remainingDays, DateTime(2028, 1, 15).difference(today).inDays);
    });

    test('active on the end date with 0 remaining days', () {
      final snap = SupervisionPeriod.compute(
        startIso: '2026-01-15',
        endIso: '2026-06-15',
        now: today,
      );
      expect(snap.status, SupervisionStatus.active);
      expect(snap.remainingDays, 0);
    });

    test('completed after the end date without discharging', () {
      final snap = SupervisionPeriod.compute(
        startIso: '2024-01-15',
        endIso: '2026-06-14',
        now: today,
      );
      expect(snap.status, SupervisionStatus.completed);
      expect(snap.label, contains('pending official confirmation'));
      expect(snap.remainingDays, isNull);
    });

    test('suspended is preserved over date-based status', () {
      final snap = SupervisionPeriod.compute(
        startIso: '2026-01-15',
        endIso: '2028-01-15',
        isSuspended: true,
        now: today,
      );
      expect(snap.status, SupervisionStatus.suspended);
    });

    test('formatIso writes calendar dates', () {
      expect(SupervisionPeriod.formatIso(DateTime(2026, 1, 5)), '2026-01-05');
    });
  });
}
