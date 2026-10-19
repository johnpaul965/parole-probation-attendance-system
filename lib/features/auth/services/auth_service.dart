import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:last/core/constants/firestore_collections.dart';
import 'package:last/core/services/session_service.dart';
import 'package:last/core/utils/firebase_config.dart';
import 'package:last/core/utils/supabase_config.dart';
import 'package:last/features/auth/models/app_user.dart';
import 'package:last/features/auth/models/user_role.dart';
import 'package:last/features/auth/services/demo_auth_service.dart';
import 'package:last/features/auth/services/supabase_auth_service.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class AuthService {
  Future<AppUser> signIn({
    required String email,
    required String password,
    required UserRole selectedRole,
  });

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phone,
  });

  Future<void> resendVerification({
    required String email,
    required String password,
  });

  Future<void> signOut();
  AppUser? get currentUser;
  Stream<AppUser?> get authStateChanges;
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    fb.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  AppUser? _cached;

  @override
  AppUser? get currentUser => _cached;

  @override
  Stream<AppUser?> get authStateChanges async* {
    await for (final fbUser in _auth.authStateChanges()) {
      if (fbUser == null) {
        _cached = null;
        yield null;
        continue;
      }
      if (!fbUser.emailVerified) {
        _cached = null;
        yield null;
        continue;
      }
      try {
        _cached = await _requireActiveProfile(fbUser.uid, signOutOnFailure: false);
        if (_cached == null) {
          yield null;
          continue;
        }
        yield _cached;
      } on AuthException {
        _cached = null;
        yield null;
      }
    }
  }

  Future<AppUser?> _fetchUser(String uid) async {
    final doc = await _firestore.collection(FirestoreCollections.users).doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap({...doc.data()!, 'id': uid});
  }

  Future<AppUser> _requireActiveProfile(String uid, {required bool signOutOnFailure}) async {
    final user = await _fetchUser(uid);
    if (user == null) {
      if (signOutOnFailure) await _auth.signOut();
      throw AuthException(
        'This account has no Firestore profile. Create users/$uid in Firebase Console with role officer or parolee.',
      );
    }
    if (!user.isActive) {
      if (signOutOnFailure) await _auth.signOut();
      throw AuthException('This account has been disabled');
    }
    return user;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
    required UserRole selectedRole,
  }) async {
    fb.UserCredential cred;
    try {
      cred = await _signInWithRetry(email.trim(), password);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    }

    await cred.user!.reload();
    final fbUser = _auth.currentUser;
    if (fbUser == null || !fbUser.emailVerified) {
      try {
        await fbUser?.sendEmailVerification();
      } catch (_) {}
      await _auth.signOut();
      throw AuthException(
        'Verify your email before signing in. We sent a new verification link if this account exists.',
      );
    }

    try {
      final user = await _requireActiveProfile(fbUser.uid, signOutOnFailure: true);

      if (user.role != selectedRole) {
        await _auth.signOut();
        throw AuthException(
          'Wrong role tab. This account is ${user.role.label}. Select ${user.role.label} and try again.',
        );
      }
      _cached = user;
      await SessionService.saveUser(user);
      return user;
    } on AuthException {
      rethrow;
    } on FirebaseException catch (e) {
      await _auth.signOut();
      throw AuthException(_mapFirestoreError(e));
    }
  }

  Future<fb.UserCredential> _signInWithRetry(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'unavailable' || e.code == 'network-request-failed') {
        await Future<void>.delayed(const Duration(seconds: 2));
        return await _auth.signInWithEmailAndPassword(email: email, password: password);
      }
      rethrow;
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
    final trimmedEmail = email.trim();
    final name = fullName.trim();
    fb.UserCredential cred;
    try {
      cred = await _auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    }

    final uid = cred.user!.uid;
    try {
      await cred.user!.updateDisplayName(name);
      await _firestore.collection(FirestoreCollections.users).doc(uid).set({
        'id': uid,
        'email': trimmedEmail,
        'fullName': name,
        'role': role.name,
        'isActive': true,
        'avatarInitials': _initials(name),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      });
      await cred.user!.sendEmailVerification();
    } on fb.FirebaseAuthException catch (e) {
      await _auth.signOut();
      throw AuthException(_mapAuthError(e));
    } on FirebaseException catch (e) {
      await _auth.signOut();
      throw AuthException(_mapFirestoreError(e));
    }
    await _auth.signOut();
    _cached = null;
    await SessionService.clear();
  }

  @override
  Future<void> resendVerification({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (cred.user != null && !cred.user!.emailVerified) {
        await cred.user!.sendEmailVerification();
      }
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    } finally {
      await _auth.signOut();
      _cached = null;
    }
  }

  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  String _mapAuthError(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists for this email. Sign in or reset your password.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      case 'unavailable':
        return 'Firebase Auth cannot be reached. Check internet, use a Google Play emulator, and enable Email/Password in Firebase Console.';
      case 'network-request-failed':
        return 'No internet connection. Turn on Wi‑Fi or mobile data and try again.';
      default:
        return e.message ?? 'Authentication failed (${e.code})';
    }
  }

  String _mapFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Firestore access denied. Deploy firestore.rules and ensure users/${_auth.currentUser?.uid} exists.';
      case 'unavailable':
        return 'Firestore is unavailable. Check your connection and the pptac-attendance-capstone project.';
      case 'not-found':
        return 'Firestore database not found. Create it in Firebase Console → Firestore Database.';
      default:
        return 'Database error: ${e.message ?? e.code}';
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    _cached = null;
    await SessionService.clear();
  }
}

AuthService createAuthService() {
  if (SupabaseConfig.isConfigured) {
    return SupabaseAuthService();
  }
  if (FirebaseConfig.isConfigured) {
    return FirebaseAuthService();
  }
  return DemoAuthService();
}
