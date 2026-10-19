import 'package:flutter_test/flutter_test.dart';
import 'package:last/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('returns error for null', () {
      expect(Validators.email(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('   '), isNotNull);
    });

    test('returns error for invalid email', () {
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('missing@domain'), isNotNull);
      expect(Validators.email('@no-local.com'), isNotNull);
    });

    test('returns null for valid email', () {
      expect(Validators.email('user@example.com'), isNull);
      expect(Validators.email('test.user@domain.org'), isNull);
    });
  });

  group('Validators.password', () {
    test('returns error for null', () {
      expect(Validators.password(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(Validators.password(''), isNotNull);
    });

    test('returns error for short password', () {
      expect(Validators.password('12345'), isNotNull);
    });

    test('returns null for valid password', () {
      expect(Validators.password('123456'), isNull);
      expect(Validators.password('a-long-secure-password'), isNull);
    });
  });

  group('Validators.phone', () {
    test('returns error for empty', () {
      expect(Validators.phone(null), isNotNull);
      expect(Validators.phone(''), isNotNull);
    });

    test('returns error for invalid PH mobile', () {
      expect(Validators.phone('12345'), isNotNull);
      expect(Validators.phone('08123456789'), isNotNull);
    });

    test('returns null for valid PH mobile', () {
      expect(Validators.phone('09171234567'), isNull);
      expect(Validators.phone('+639171234567'), isNull);
    });
  });
}
