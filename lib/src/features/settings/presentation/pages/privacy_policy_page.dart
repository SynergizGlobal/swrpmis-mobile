import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/config/environment.dart';
import 'package:swr_pmis_mobile/src/core/constants/legal_assets.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  static const String routeName = 'privacy-policy';
  static const String routePath = '/privacy-policy';

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  late final WebViewController _controller;
  bool _loading = true;
  Brightness? _appliedBrightness;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              _syncWebViewTheme(Theme.of(context).brightness);
              setState(() => _loading = false);
            }
          },
        ),
      )
      ..loadFlutterAsset(LegalAssets.privacyPolicyHtml);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncWebViewTheme(Theme.of(context).brightness);
  }

  void _syncWebViewTheme(Brightness brightness) {
    if (_appliedBrightness == brightness) {
      return;
    }
    _appliedBrightness = brightness;
    final bool isDark = brightness == Brightness.dark;
    final Color background =
        isDark ? AppTheme.scaffoldDark : AppTheme.scaffoldLight;
    _controller.setBackgroundColor(background);
    _controller.runJavaScript(
      "document.documentElement.setAttribute('data-theme', "
      "'${isDark ? 'dark' : 'light'}');",
    );
  }

  Future<void> _openHostedCopy() async {
    final Uri uri = Uri.parse(Environment.privacyPolicyUrl);
    final bool opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Could not open link',
        message:
            'The privacy policy could not be opened in your browser. '
            'You can still read the copy bundled in the app.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Open on web',
            onPressed: _openHostedCopy,
            icon: const Icon(Icons.open_in_new_rounded),
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
