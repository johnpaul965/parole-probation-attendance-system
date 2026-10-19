import 'package:flutter_test/flutter_test.dart';
import 'package:last/core/constants/login_credentials.dart';

void main() {
  test('Login credentials are configured for testing', () {
    expect(LoginCredentials.officerEmail, isNotEmpty);
    expect(LoginCredentials.paroleeEmail, isNotEmpty);
    expect(LoginCredentials.password.length, greaterThanOrEqualTo(6));
  });
}
