import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/app/config/app_config_controller.dart';
import 'package:swr_pmis_mobile/src/app/theme/theme_mode_provider.dart';
import 'package:swr_pmis_mobile/src/core/config/env.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/pages/login_page.dart';
import 'package:swr_pmis_mobile/src/features/settings/presentation/pages/privacy_policy_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const String routeName = 'settings';
  static const String routePath = '/settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode mode = ref.watch(themeModeProvider);
    final Env environment = ref.watch(appEnvironmentProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  title: const Text('System default'),
                  subtitle: const Text('Follow the phone light/dark setting'),
                  trailing: mode == ThemeMode.system
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () => ref
                      .read(themeModeProvider.notifier)
                      .setMode(ThemeMode.system),
                ),
                ListTile(
                  title: const Text('Light'),
                  trailing: mode == ThemeMode.light
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () => ref
                      .read(themeModeProvider.notifier)
                      .setMode(ThemeMode.light),
                ),
                ListTile(
                  title: const Text('Dark'),
                  trailing: mode == ThemeMode.dark
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () => ref
                      .read(themeModeProvider.notifier)
                      .setMode(ThemeMode.dark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'API environment',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  title: const Text('QA'),
                  subtitle: const Text('Staging server (115.124.125.151:8443)'),
                  trailing: environment == Env.qa
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () => _switchEnvironment(context, ref, Env.qa),
                ),
                ListTile(
                  title: const Text('Production'),
                  subtitle: const Text('pmis-swrindianrailways.org'),
                  trailing: environment == Env.prod
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () => _switchEnvironment(context, ref, Env.prod),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Legal',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('Privacy Policy'),
              subtitle: const Text('Permissions and how we use data'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.pushNamed(PrivacyPolicyPage.routeName),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _switchEnvironment(
    BuildContext context,
    WidgetRef ref,
    Env env,
  ) async {
    if (ref.read(appEnvironmentProvider) == env) {
      return;
    }
    await ref.read(appConfigProvider.notifier).setEnvironment(env);
    await ref.read(authControllerProvider.notifier).logout();
    if (!context.mounted) {
      return;
    }
    context.goNamed(LoginPage.routeName);
  }
}
