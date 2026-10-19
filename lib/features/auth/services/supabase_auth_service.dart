import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:last/core/services/session_service.dart';
import 'package:last/core/utils/supabase_config.dart';
import 'package:last/features/auth/models/app_user.dart';
import 'package:last/features/auth/models/user_role.dart';
import 'package:last/features/auth/services/auth_service.dart';
import 'package:last/features/auth/services/demo_auth_service.dart';

class SupabaseAuthService implements AuthService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final DemoAuthService _demoFallback = DemoAuthService();
  AppUser? _currentUser;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Stream<AppUser?> get authStateChanges {
    final controller = StreamController<AppUser?>.broadcast();

    // Check saved session immediately to prevent splash screen hanging
    final saved = SessionService.getUser();
    if (saved != null) {
      _currentUser = saved;
      controller.add(saved);
    } else {
      try {
        final cur = _supabase.auth.currentUser;
        if (cur != null) {
          _currentUser = _mapUser(cur);
          controller.add(_currentUser);
        } else {
          controller.add(null);
        }
      } catch (_) {
        controller.add(null);
      }
    }

    try {
      _supabase.auth.onAuthStateChange.listen((data) {
        final user = data.session?.user;
        if (user == null) {
          _currentUser = null;
          controller.add(null);
        } else {
          _currentUser = _mapUser(user);
          controller.add(_currentUser);
        }
      }, onError: (_) {
        controller.add(null);
      });
    } catch (_) {}

    return controller.stream;
  }

  AppUser _mapUser(User user) {
    final meta = user.userMetadata ?? {};
    final roleStr = meta['role'] as String? ?? 'officer';
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      fullName: meta['full_name'] as String? ?? user.email?.split('@').first ?? 'User',
      role: UserRole.fromString(roleStr),
      phone: meta['phone'] as String? ?? user.phone,
      department: meta['department'] as String?,
      caseNumber: meta['case_number'] as String?,
      officerId: meta['officer_id'] as String?,
      trackerId: meta['tracker_id'] as String?,
      isActive: true,
      supervisionStartDate: meta['supervision_start_date'] as String?,
      supervisionEndDate: meta['supervision_end_date'] as String?,
    );
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
    required UserRole selectedRole,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    // 1. If it's a test/demo account, allow instant login so demo presentations never fail
    if (cleanEmail.contains('ppa-attendance.com') || cleanEmail.contains('ppa-parolee.org')) {
      try {
        final demoUser = await _demoFallback.signIn(
          email: cleanEmail,
          password: password,
          selectedRole: selectedRole,
        );
        _currentUser = demoUser;
        return demoUser;
      } catch (_) {}
    }

    // 2. Real Supabase Authentication for all deployed user accounts
    try {
      final res = await _supabase.auth.signInWithPassword(
        email: cleanEmail,
        password: password,
      );

      final user = res.user;
      if (user == null) {
        throw AuthException('No user account returned from Supabase.');
      }

      final appUser = _mapUser(user);
      if (appUser.role != selectedRole) {
        throw AuthException(
          'Role mismatch. This account is registered as a ${appUser.role.label}, but you selected ${selectedRole.label}.',
        );
      }

      _currentUser = appUser;
      await SessionService.saveUser(appUser);
      return appUser;
    } on AuthApiException catch (e) {
      if (e.message.toLowerCase().contains('email not confirmed')) {
        throw AuthException(
          'Email not confirmed. In Supabase Dashboard → Authentication → Providers → Email, turn OFF "Confirm email" to allow instant login.',
        );
      }
      throw AuthException(e.message);
    } catch (e) {
      try {
        return await _demoFallback.signIn(email: cleanEmail, password: password, selectedRole: selectedRole);
      } catch (_) {}
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phone,
  }) async {
    try {
      final res = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName,
          'role': role.name,
          'phone': phone,
        },
      );

      if (res.user != null) {
        try {
          await _supabase.from('profiles').upsert({
            'id': res.user!.id,
            'email': email.trim(),
            'full_name': fullName,
            'role': role.name,
            'phone': phone,
            'created_at': DateTime.now().toIso8601String(),
          });
        } catch (_) {}
      }
    } on AuthApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException('Registration failed: $e');
    }
  }

  @override
  Future<void> resendVerification({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email.trim(),
      );
    } catch (e) {
      throw AuthException('Failed to resend verification: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {}
    _currentUser = null;
    await SessionService.clear();
  }
}
