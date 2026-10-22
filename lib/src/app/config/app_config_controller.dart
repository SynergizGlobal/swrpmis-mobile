import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swr_pmis_mobile/src/app/config/app_config.dart';
import 'package:swr_pmis_mobile/src/core/config/env.dart';
import 'package:swr_pmis_mobile/src/core/config/environment.dart';

class AppConfigController extends StateNotifier<AppConfig> {
  AppConfigController(this._prefs, AppConfig seed, Env initialEnv)
      : _env = initialEnv,
        super(seed) {
    Environment.init(_env);
  }

  static const String environmentPrefsKey = 'app_api_environment';

  final SharedPreferences _prefs;
  Env _env;

  Env get environment => _env;

  static Env readStoredEnvironment(
    SharedPreferences prefs, {
    required Env fallback,
  }) {
    return switch (prefs.getString(environmentPrefsKey)) {
      'prod' => Env.prod,
      'qa' => Env.qa,
      _ => fallback,
    };
  }

  Future<void> setEnvironment(Env env) async {
    if (_env == env) {
      return;
    }
    _env = env;
    Environment.init(env);
    await _prefs.setString(environmentPrefsKey, env.name);
    state = state.copyWith(baseUrl: Environment.swrBaseUrl);
  }
}

final appConfigProvider =
    StateNotifierProvider<AppConfigController, AppConfig>((ref) {
  throw UnimplementedError('AppConfig must be overridden in bootstrap');
});

final appEnvironmentProvider = Provider<Env>((ref) {
  ref.watch(appConfigProvider);
  return ref.read(appConfigProvider.notifier).environment;
});
