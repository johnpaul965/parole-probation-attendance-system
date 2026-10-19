import 'package:flutter_test/flutter_test.dart';
import 'package:last/core/utils/phone_contact.dart';

void main() {
  group('PhoneContact.e164', () {
    test('converts local 09 numbers', () {
      expect(PhoneContact.e164('0917 123 4567'), '+639171234567');
    });

    test('keeps +63 numbers', () {
      expect(PhoneContact.e164('+639171234567'), '+639171234567');
    });

    test('rejects invalid numbers', () {
      expect(PhoneContact.e164('123'), isNull);
      expect(PhoneContact.e164(null), isNull);
    });
  });
}
