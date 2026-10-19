import 'package:flutter_test/flutter_test.dart';
import 'package:last/features/auth/models/app_user.dart';
import 'package:last/features/auth/models/user_role.dart';

void main() {
  group('AppUser', () {
    const user = AppUser(
      id: 'u-1',
      email: 'test@example.com',
      fullName: 'Juan Dela Cruz',
      role: UserRole.parolee,
      department: 'Dept A',
      caseNumber: 'CASE-001',
      officerId: 'off-1',
      phone: '09171234567',
      isActive: true,
      supervisionStartDate: '2026-01-15',
      supervisionEndDate: '2028-01-15',
      supervisionIsSuspended: false,
    );

    test('toMap and fromMap round-trip preserves data', () {
      final map = user.toMap();
      final restored = AppUser.fromMap(map);
      expect(restored.id, user.id);
      expect(restored.email, user.email);
      expect(restored.fullName, user.fullName);
      expect(restored.role, user.role);
      expect(restored.department, user.department);
      expect(restored.caseNumber, user.caseNumber);
      expect(restored.officerId, user.officerId);
      expect(restored.phone, user.phone);
      expect(restored.isActive, user.isActive);
      expect(restored.supervisionStartDate, user.supervisionStartDate);
      expect(restored.supervisionEndDate, user.supervisionEndDate);
      expect(restored.supervisionIsSuspended, user.supervisionIsSuspended);
    });

    test('fromMap reads assignedOfficerId as fallback', () {
      final map = {'id': 'u-2', 'assignedOfficerId': 'off-x', 'role': 'parolee'};
      final restored = AppUser.fromMap(map);
      expect(restored.officerId, 'off-x');
    });

    test('initials from two-word name', () {
      const twoWord = AppUser(
        id: '1',
        email: '',
        fullName: 'John Doe',
        role: UserRole.parolee,
      );
      expect(twoWord.initials, 'JD');
    });

    test('initials from three-word name uses first and last', () {
      expect(user.initials, 'JC');
    });

    test('initials from single-word name', () {
      const single = AppUser(id: '1', email: '', fullName: 'Juan', role: UserRole.officer);
      expect(single.initials, 'J');
    });

    test('initials falls back to ? for empty name', () {
      const empty = AppUser(id: '1', email: '', fullName: '', role: UserRole.officer);
      expect(empty.initials, '?');
    });

    test('initials uses avatarInitials when set', () {
      const custom = AppUser(
        id: '1', email: '', fullName: 'Juan', role: UserRole.officer,
        avatarInitials: 'XY',
      );
      expect(custom.initials, 'XY');
    });

    test('copyWith overrides specified fields', () {
      final updated = user.copyWith(fullName: 'Maria Santos', isActive: false);
      expect(updated.fullName, 'Maria Santos');
      expect(updated.isActive, false);
      expect(updated.email, user.email);
    });

    test('fromMap handles missing fields with defaults', () {
      final minimal = AppUser.fromMap({'id': 'x'});
      expect(minimal.id, 'x');
      expect(minimal.email, '');
      expect(minimal.role, UserRole.parolee);
      expect(minimal.isActive, true);
    });
  });
}
