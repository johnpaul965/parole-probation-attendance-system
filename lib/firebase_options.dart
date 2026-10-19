// Run `flutterfire configure` to replace with your project credentials.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        return windows;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBUfgqd43tnEt0KOl-nztE5KgzV0k_8Sag',
    appId: '1:682020472681:web:737ec21296726eca151ff8',
    messagingSenderId: '682020472681',
    projectId: 'pptac-attendance-capstone',
    authDomain: 'pptac-attendance-capstone.firebaseapp.com',
    storageBucket: 'pptac-attendance-capstone.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBUoaz8xCr9lvWcdd4Dw26l9WxA1jDSPrk',
    appId: '1:682020472681:android:7906687f15435a1f151ff8',
    messagingSenderId: '682020472681',
    projectId: 'pptac-attendance-capstone',
    authDomain: 'pptac-attendance-capstone.firebaseapp.com',
    storageBucket: 'pptac-attendance-capstone.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCBQAC14qkmain0Dsu9PChihzVpRG-avn8',
    appId: '1:682020472681:ios:52c0a65b85f6308a151ff8',
    messagingSenderId: '682020472681',
    projectId: 'pptac-attendance-capstone',
    storageBucket: 'pptac-attendance-capstone.firebasestorage.app',
    iosBundleId: 'com.example.last',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCBQAC14qkmain0Dsu9PChihzVpRG-avn8',
    appId: '1:682020472681:ios:52c0a65b85f6308a151ff8',
    messagingSenderId: '682020472681',
    projectId: 'pptac-attendance-capstone',
    storageBucket: 'pptac-attendance-capstone.firebasestorage.app',
    iosBundleId: 'com.example.last',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBUfgqd43tnEt0KOl-nztE5KgzV0k_8Sag',
    appId: '1:682020472681:web:9b017689e9f053d7151ff8',
    messagingSenderId: '682020472681',
    projectId: 'pptac-attendance-capstone',
    authDomain: 'pptac-attendance-capstone.firebaseapp.com',
    storageBucket: 'pptac-attendance-capstone.firebasestorage.app',
  );

}