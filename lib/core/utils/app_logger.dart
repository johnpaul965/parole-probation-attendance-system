import 'package:flutter/foundation.dart';

/// Lightweight debug logging for Firebase/dashboard flows.
class AppLogger {
  static void d(String tag, Object message, [Object? detail]) {
    if (kDebugMode) {
      debugPrint('[$tag] $message${detail != null ? ' | $detail' : ''}');
    }
  }

  static void e(String tag, Object message, [Object? error, StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('[$tag] ERROR: $message');
      if (error != null) debugPrint('[$tag] $error');
      if (stack != null) debugPrint('[$tag] $stack');
    }
  }
}
