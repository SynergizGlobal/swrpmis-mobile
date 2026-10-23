import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/app/config/app_config.dart';
import 'package:swr_pmis_mobile/src/core/config/environment.dart';

/// Set in [bootstrap] from the [AppConfig] built in `main.dart`.
final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError('AppConfig must be overridden in bootstrap');
});

/// Mirrors [Environment.current] set via `Environment.init` in `main.dart`.
final appEnvironmentProvider = Provider<Env>((ref) => Environment.current);
