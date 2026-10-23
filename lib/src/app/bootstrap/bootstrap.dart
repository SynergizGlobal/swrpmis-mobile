import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swr_pmis_mobile/firebase_options.dart';
import 'package:swr_pmis_mobile/src/app/app.dart';
import 'package:swr_pmis_mobile/src/app/config/app_config.dart';
import 'package:swr_pmis_mobile/src/app/config/app_config_controller.dart';
import 'package:swr_pmis_mobile/src/core/config/shared_prefs_provider.dart';
import 'package:swr_pmis_mobile/src/core/firebase/firebase_initializer.dart';
import 'package:swr_pmis_mobile/src/core/firebase/remote_config_initializer.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/core/notifications/fcm_background_handler.dart';

Future<void> bootstrap(AppConfig config) async {
  await runAppWithCrashlyticsZone(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await initializeFirebase();
    if (DefaultFirebaseOptions.isConfigured) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }
    await RemoteConfigInitializer.initialize();

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        sharedPrefsProvider.overrideWithValue(prefs),
        appConfigProvider.overrideWithValue(config),
      ],
    );

    await container.read(sessionCookieManagerProvider.future);

    runApp(UncontrolledProviderScope(container: container, child: const App()));
  });
}
