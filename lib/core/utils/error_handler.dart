import 'package:cloud_firestore/cloud_firestore.dart';

class AppException implements Exception {
  AppException(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => message;
}

class ErrorHandler {
  static String friendlyMessage(Object error) {
    if (error is AppException) return error.message;
    if (error is FirebaseException) return _mapFirebaseError(error);
    final msg = error.toString();
    if (msg.contains('permission-denied')) {
      return 'Access denied. Check your Firestore security rules.';
    }
    if (msg.contains('unavailable') || msg.contains('network')) {
      return 'Network unavailable. Check your connection and try again.';
    }
    return msg.replaceFirst('Exception: ', '');
  }

  static String _mapFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Access denied. Check your Firestore security rules.';
      case 'unavailable':
        return 'Firebase is unreachable. Check your internet connection.';
      case 'not-found':
        return 'Requested resource not found in Firestore.';
      case 'already-exists':
        return 'This record already exists.';
      case 'failed-precondition':
        return 'Operation requires a Firestore composite index. Check the debug console for the creation link.';
      case 'deadline-exceeded':
        return 'Request timed out. Try again.';
      default:
        return e.message ?? 'Firebase error (${e.code})';
    }
  }

  static AppException wrap(Object error, [String? context]) {
    final msg = friendlyMessage(error);
    final prefix = context != null ? '$context: ' : '';
    return AppException('$prefix$msg');
  }
}
