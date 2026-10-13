import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:swr_pmis_mobile/firebase_options.dart';

/// Initializes the SWR Firebase app when [DefaultFirebaseOptions] is set.
Future<void> initializeFirebase() async {
  if (kIsWeb || !DefaultFirebaseOptions.isConfigured) {
    if (kDebugMode && !DefaultFirebaseOptions.isConfigured) {
      debugPrint(
        'Firebase skipped: add android/app/google-services.json and '
        'ios/Runner/GoogleService-Info.plist.',
      );
    }
    return;
  }

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
