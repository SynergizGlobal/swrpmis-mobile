import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:swr_pmis_mobile/firebase_options.dart';

/// Initializes Firebase and wires Flutter / async errors to Crashlytics.
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

  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
    !kDebugMode,
  );

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}

/// Runs [body] in one zone so binding + [runApp] share it (Flutter requirement).
/// Uncaught async errors are reported to Crashlytics when Firebase is configured.
Future<void> runAppWithCrashlyticsZone(Future<void> Function() body) async {
  if (!DefaultFirebaseOptions.isConfigured) {
    await body();
    return;
  }
  await runZonedGuarded(body, (Object error, StackTrace stack) {
    FirebaseCrashlytics.instance.recordError(error, stack);
  });
}

Future<void> setCrashlyticsUserId(String? userId) async {
  if (kIsWeb || !DefaultFirebaseOptions.isConfigured) {
    return;
  }
  final String id = userId?.trim() ?? '';
  await FirebaseCrashlytics.instance.setUserIdentifier(id);
}
