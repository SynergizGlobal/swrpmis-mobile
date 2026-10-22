import 'package:swr_pmis_mobile/src/app/bootstrap/bootstrap.dart';
import 'package:swr_pmis_mobile/src/app/config/app_config.dart';
import 'package:swr_pmis_mobile/src/core/constants/app_constants.dart';

Future<void> main() async {
  await bootstrap(
    AppConfig(
      appName: AppConstants.appName,
      // Overwritten after Environment.init in bootstrap.
      baseUrl: '',
    ),
  );
}
