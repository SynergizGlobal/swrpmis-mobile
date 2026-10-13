import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:swr_pmis_mobile/src/core/app_update/app_update_config.dart';
import 'package:swr_pmis_mobile/src/core/app_update/app_update_service.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';

class AppUpdatePrompt {
  const AppUpdatePrompt._();

  static Future<void> showOptional({
    required BuildContext context,
    required AppUpdateConfig config,
    required AppUpdateService service,
  }) async {
    await AppDialog.show(
      context,
      variant: AppDialogVariant.confirm,
      icon: Icons.system_update_rounded,
      title: 'Update available',
      message: _messageBody(config),
      primaryLabel: 'Update',
      secondaryLabel: 'Later',
      barrierDismissible: false,
      onPrimary: () {
        _openStore(config.storeUrl);
      },
      onSecondary: () {
        service.recordOptionalDismissal();
      },
    );
  }

  static Widget forceUpdateScreen({required AppUpdateConfig config}) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.system_update_alt_rounded, size: 56),
                const SizedBox(height: 20),
                const Text(
                  'Update required',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(_messageBody(config), textAlign: TextAlign.center),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _openStore(config.storeUrl),
                    child: const Text('Update from store'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _messageBody(AppUpdateConfig config) {
    final String base = config.message.trim();
    final String versions =
        'Installed: ${config.currentVersion}\nRequired: ${config.isForce ? config.minVersion : config.latestVersion}';
    if (base.isEmpty) {
      return versions;
    }
    return '$base\n\n$versions';
  }

  static Future<void> _openStore(String storeUrl) async {
    final String url = storeUrl.trim();
    if (url.isEmpty) {
      return;
    }
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }
    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      await Clipboard.setData(ClipboardData(text: url));
    }
  }
}
