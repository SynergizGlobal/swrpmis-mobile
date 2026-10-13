import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:swr_pmis_mobile/firebase_options.dart';

class RemoteConfigInitializer {
  const RemoteConfigInitializer._();

  static bool _initialized = false;

  static bool get isAvailable =>
      !kIsWeb && DefaultFirebaseOptions.isConfigured && _initialized;

  static Future<void> initialize() async {
    if (kIsWeb || !DefaultFirebaseOptions.isConfigured) {
      if (kDebugMode && !DefaultFirebaseOptions.isConfigured) {
        debugPrint(
          'Firebase Remote Config skipped: Firebase options are not configured.',
        );
      }
      return;
    }

    final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 12),
        minimumFetchInterval: kDebugMode
            ? const Duration(minutes: 1)
            : const Duration(hours: 3),
      ),
    );

    await remoteConfig.setDefaults(<String, dynamic>{
      'update_check_enabled': true,
      'min_version': '0.0.0',
      'latest_version': '0.0.0',
      'min_version_android': '',
      'min_version_ios': '',
      'latest_version_android': '',
      'latest_version_ios': '',
      'optional_update_interval_hours': 24,
      'force_update_message':
          'A required update is available. Please update SWR-PMIS from the store to continue.',
      'optional_update_message':
          'A new version of SWR-PMIS is available with improvements and fixes.',
      'android_store_url': '',
      'ios_store_url': '',
      'ios_app_store_id': '',
    });

    try {
      await remoteConfig.fetchAndActivate();
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Remote Config fetch failed, using defaults/cache: $error');
        debugPrint('$stackTrace');
      }
    }

    _initialized = true;
  }
}
