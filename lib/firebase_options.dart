import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for the SWR Firebase app `swrpmismobile`.
class DefaultFirebaseOptions {
  static bool get isConfigured => true;

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('SWR-PMIS does not support web.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError('macOS is not configured for SWR-PMIS.');
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Desktop platforms are not configured for SWR-PMIS.',
        );
      default:
        throw UnsupportedError('Unsupported platform: $defaultTargetPlatform');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCni-El2sFul6YBbpl-L1yDMhvRS2fDT3s',
    appId: '1:945704282160:android:55e294c022528c7c08e5f5',
    messagingSenderId: '945704282160',
    projectId: 'swrpmismobile',
    storageBucket: 'swrpmismobile.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAuh-VnbzfR78RXDjZ3ABcTPH3-w6YUnQQ',
    appId: '1:945704282160:ios:8bad771f27f57bf208e5f5',
    messagingSenderId: '945704282160',
    projectId: 'swrpmismobile',
    storageBucket: 'swrpmismobile.firebasestorage.app',
    iosBundleId: 'com.synergiz.swrpmismobile',
  );
}
