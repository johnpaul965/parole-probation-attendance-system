import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:last/core/services/session_service.dart';
import 'package:last/features/auth/models/app_user.dart';
import 'package:last/features/auth/models/user_role.dart';
import 'package:last/features/auth/services/auth_service.dart';
import 'package:last/features/tracking/services/phone_location_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
      : _authService = authService ?? createAuthService();

  final AuthService _authService;
  AppUser? _user;
  bool _loading = false;
  bool _initialized = false;
  String? _error;
  StreamSubscription<AppUser?>? _authSub;
  Completer<void>? _ready;

  AppUser? get user => _user;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isInitializing => !_initialized;

  Future<void> initialize() async {
    if (_authSub != null) {
      await _ready?.future;
      return;
    }
    _ready = Completer<void>();
    _authSub = _authService.authStateChanges.listen(
      (user) {
        _user = user;
        if (user != null) {
          SessionService.saveUser(user);
        } else {
          SessionService.clear();
          PhoneLocationService.instance.stop();
        }
        _initialized = true;
        notifyListeners();
        if (!(_ready?.isCompleted ?? true)) {
          _ready!.complete();
        }
      },
      onError: (_) {
        _user = null;
        _initialized = true;
        notifyListeners();
        if (!(_ready?.isCompleted ?? true)) {
          _ready!.complete();
        }
      },
    );

    try {
      await _ready!.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          _initialized = true;
          notifyListeners();
          if (!(_ready?.isCompleted ?? true)) {
            _ready!.complete();
          }
        },
      );
    } catch (_) {
      _initialized = true;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.signIn(
        email: email,
        password: password,
        selectedRole: role,
      );
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _user = null;
      return false;
    } catch (e) {
      _error = 'Login failed. Please try again.';
      _user = null;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phone,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.register(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        phone: phone,
      );
      _user = null;
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _user = null;
      return false;
    } catch (e) {
      _error = 'Registration failed. Please try again.';
      _user = null;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    PhoneLocationService.instance.stop();
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  void updateProfile(AppUser updated) {
    _user = updated;
    SessionService.saveUser(updated);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
