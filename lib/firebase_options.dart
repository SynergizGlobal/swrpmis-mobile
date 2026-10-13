import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for the SWR Firebase app `swr-pmis-by-synergiz`.
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
    apiKey: 'AIzaSyDWbAfdfcz3GjuDC-4xzfLmjBV2Z1s1B9E',
    appId: '1:964871981157:android:00615df15758414fe81e8c',
    messagingSenderId: '964871981157',
    projectId: 'swr-pmis-by-synergiz',
    storageBucket: 'swr-pmis-by-synergiz.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD7WphhAJ0rvum9nHC0wgFBYCOEm3FW0PU',
    appId: '1:964871981157:ios:623429851d856f6be81e8c',
    messagingSenderId: '964871981157',
    projectId: 'swr-pmis-by-synergiz',
    storageBucket: 'swr-pmis-by-synergiz.firebasestorage.app',
    iosBundleId: 'com.synergiz.swr.pmis',
  );
}
