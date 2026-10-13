import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/app_update/app_update_config.dart';
import 'package:swr_pmis_mobile/src/core/app_update/app_update_prompt.dart';
import 'package:swr_pmis_mobile/src/core/app_update/app_update_provider.dart';
import 'package:swr_pmis_mobile/src/core/app_update/app_update_service.dart';

/// Runs the version check when the signed-in shell first appears.
class AppUpdateHost extends ConsumerStatefulWidget {
  const AppUpdateHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppUpdateHost> createState() => _AppUpdateHostState();
}

class _AppUpdateHostState extends ConsumerState<AppUpdateHost> {
  AppUpdateConfig? _forceUpdateConfig;
  bool _updateCheckStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForAppUpdate());
  }

  Future<void> _checkForAppUpdate() async {
    if (_updateCheckStarted) {
      return;
    }
    _updateCheckStarted = true;
    try {
      final AppUpdateService service = ref.read(appUpdateServiceProvider);
      final AppUpdateConfig config = await service.evaluate();
      if (!mounted) {
        return;
      }
      if (config.isForce) {
        setState(() => _forceUpdateConfig = config);
        return;
      }
      if (config.promptType == AppUpdatePromptType.optional) {
        await AppUpdatePrompt.showOptional(
          context: context,
          config: config,
          service: service,
        );
      }
    } catch (_) {
      // Fail open: never block the shell when update checks fail.
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppUpdateConfig? forceUpdate = _forceUpdateConfig;
    if (forceUpdate != null) {
      return AppUpdatePrompt.forceUpdateScreen(config: forceUpdate);
    }
    return widget.child;
  }
}
