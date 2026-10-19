import 'package:flutter_test/flutter_test.dart';
import 'package:last/core/utils/date_utils.dart';

void main() {
  group('AppDateUtils', () {
    test('startOfDay zeroes time components', () {
      final dt = DateTime(2026, 8, 19, 14, 30, 45, 123);
      final sod = AppDateUtils.startOfDay(dt);
      expect(sod, DateTime(2026, 8, 19));
    });

    test('endOfDay sets time to 23:59:59.999', () {
      final dt = DateTime(2026, 8, 19, 5);
      final eod = AppDateUtils.endOfDay(dt);
      expect(eod, DateTime(2026, 8, 19, 23, 59, 59, 999));
    });

    test('isSameDay returns true for same calendar day', () {
      final a = DateTime(2026, 8, 19, 1, 0);
      final b = DateTime(2026, 8, 19, 23, 59);
      expect(AppDateUtils.isSameDay(a, b), isTrue);
    });

    test('isSameDay returns false for different days', () {
      final a = DateTime(2026, 8, 19);
      final b = DateTime(2026, 8, 20);
      expect(AppDateUtils.isSameDay(a, b), isFalse);
    });

    test('isSameDay returns false when either is null', () {
      expect(AppDateUtils.isSameDay(null, DateTime.now()), isFalse);
      expect(AppDateUtils.isSameDay(DateTime.now(), null), isFalse);
      expect(AppDateUtils.isSameDay(null, null), isFalse);
    });

    test('isToday returns true for today', () {
      expect(AppDateUtils.isToday(DateTime.now()), isTrue);
    });

    test('isToday returns false for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(AppDateUtils.isToday(yesterday), isFalse);
    });

    test('todayStart has no time component', () {
      final start = AppDateUtils.todayStart;
      expect(start.hour, 0);
      expect(start.minute, 0);
      expect(start.second, 0);
    });
  });
}
