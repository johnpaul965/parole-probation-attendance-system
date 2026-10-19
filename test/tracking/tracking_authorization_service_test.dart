import 'package:flutter_test/flutter_test.dart';
import 'package:last/features/auth/models/app_user.dart';
import 'package:last/features/auth/models/user_role.dart';
import 'package:last/features/tracking/services/tracking_authorization_service.dart';

void main() {
  final auth = TrackingAuthorizationService();

  final officerA = AppUser(
    id: 'officer-a',
    email: 'a@test.com',
    fullName: 'Officer A',
    role: UserRole.officer,
  );

  final officerB = AppUser(
    id: 'officer-b',
    email: 'b@test.com',
    fullName: 'Officer B',
    role: UserRole.officer,
  );

  final paroleeA = AppUser(
    id: 'parolee-a',
    email: 'pa@test.com',
    fullName: 'Parolee A',
    role: UserRole.parolee,
    officerId: 'officer-a',
  );

  final paroleeB = AppUser(
    id: 'parolee-b',
    email: 'pb@test.com',
    fullName: 'Parolee B',
    role: UserRole.parolee,
    officerId: 'officer-b',
  );

  group('TrackingAuthorizationService', () {
    test('Officer A can track assigned Parolee A', () {
      expect(auth.canTrack(officerA, paroleeA), isTrue);
    });

    test('Officer A cannot track Parolee B', () {
      expect(auth.canTrack(officerA, paroleeB), isFalse);
    });

    test('Officer B cannot track Parolee A', () {
      expect(auth.canTrack(officerB, paroleeA), isFalse);
    });

    test('Parolee cannot track another parolee', () {
      expect(auth.canTrack(paroleeA, paroleeB), isFalse);
    });

    test('assertCanTrack throws for unauthorized officer', () {
      expect(
        () => auth.assertCanTrack(officerA, paroleeB),
        throwsA(isA<TrackingAuthorizationException>()),
      );
    });

    test('Unassigned parolee cannot be tracked by officer', () {
      const unassigned = AppUser(
        id: 'parolee-x',
        email: 'x@test.com',
        fullName: 'Unassigned',
        role: UserRole.parolee,
      );
      expect(auth.canTrack(officerA, unassigned), isFalse);
    });
  });
}
