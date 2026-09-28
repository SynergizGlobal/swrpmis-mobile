import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swr_pmis_mobile/src/app/app.dart';
import 'package:swr_pmis_mobile/src/app/config/app_config.dart';
import 'package:swr_pmis_mobile/src/app/config/app_config_provider.dart';
import 'package:swr_pmis_mobile/src/core/config/shared_prefs_provider.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';

Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      appConfigProvider.overrideWithValue(config),
      sharedPrefsProvider.overrideWithValue(prefs),
    ],
  );

  await container.read(sessionCookieManagerProvider.future);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const App(),
    ),
  );
}
