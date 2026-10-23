import 'package:swr_pmis_mobile/src/core/config/env.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_hosts.dart';

export 'package:swr_pmis_mobile/src/core/config/env.dart';

/// App-wide API environment. Call [init] once from `main` before [bootstrap].
class Environment {
  Environment._();

  static late Env _env;

  static void init(Env env) {
    _env = env;
  }

  static Env get current => _env;

  static bool get isQa => _env == Env.qa;

  static bool get isProd => _env == Env.prod;

  static String get swrBaseUrl {
    switch (_env) {
      case Env.qa:
        return ApiHosts.qaBaseUrl;
      case Env.prod:
        return ApiHosts.prodBaseUrl;
    }
  }

  static Uri get swrOriginUri => ApiHosts.originUriFor(swrBaseUrl);

  static String get privacyPolicyUrl =>
      ApiHosts.privacyPolicyUrlFor(swrBaseUrl);
}
