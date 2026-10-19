import 'package:last/core/constants/login_credentials.dart';
import 'package:last/core/services/session_service.dart';
import 'package:last/core/utils/supabase_config.dart';
import 'package:last/features/auth/models/app_user.dart';
import 'package:last/features/auth/models/user_role.dart';
import 'package:last/features/auth/services/auth_service.dart';

/// Offline sign-in using test credentials when Firebase is not configured.
class DemoAuthService implements AuthService {
  AppUser? _user;

  static final Map<String, AppUser> _accounts = {
    LoginCredentials.officerEmail: AppUser(
      id: 'demo-officer',
      email: LoginCredentials.officerEmail,
      fullName: 'Maria Santos',
      role: UserRole.officer,
      department: 'District 4',
      avatarInitials: 'MS',
    ),
    LoginCredentials.paroleeEmail: AppUser(
      id: 'demo-parolee',
      email: LoginCredentials.paroleeEmail,
      fullName: 'Juan Dela Cruz',
      role: UserRole.parolee,
      caseNumber: 'PP-2024-1847',
      officerId: 'demo-officer',
      avatarInitials: 'JD',
    ),
  };

  @override
  AppUser? get currentUser => _user ?? SessionService.getUser();

  @override
  Stream<AppUser?> get authStateChanges async* {
    yield currentUser;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
    required UserRole selectedRole,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final normalized = email.trim().toLowerCase();

    if (password != LoginCredentials.password) {
      throw AuthException('Invalid email or password');
    }

    final account = _accounts[normalized];
    if (account == null) {
      throw AuthException('No demo account for this email. Use officer or parolee test emails.');
    }
    if (account.role != selectedRole) {
      throw AuthException('Wrong role selected. Switch the role tab to ${account.role.label}.');
    }

    _user = account;
    await SessionService.saveUser(account);
    return account;
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phone,
  }) async {
    if (SupabaseConfig.isConfigured) {
      await SupabaseConfig.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'role': role.name, 'phone': phone},
      );
      return;
    }
    throw AuthException('Supabase configuration error.');
  }

  @override
  Future<void> resendVerification({
    required String email,
    required String password,
  }) async {
    throw AuthException('Email verification requires Firebase.');
  }

  @override
  Future<void> signOut() async {
    _user = null;
    await SessionService.clear();
  }
}
