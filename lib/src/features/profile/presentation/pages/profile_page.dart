import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/constants/app_constants.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_action_card.dart';
import 'package:swr_pmis_mobile/src/core/widgets/global_dialog.dart';
import 'package:swr_pmis_mobile/src/features/auth/domain/entities/auth_session.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/pages/login_page.dart';
import 'package:swr_pmis_mobile/src/features/settings/presentation/pages/settings_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  static const String routeName = 'profile';
  static const String routePath = '/profile';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthSession? session = ref.watch(authControllerProvider).valueOrNull;
    final AppPalette palette = AppPalette.of(context);
    final String initial = _initialFor(session);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Center(
            child: CircleAvatar(
              radius: 36,
              backgroundColor: palette.avatarFill,
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: palette.avatarText,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  _row(context, 'Name', session?.userName ?? '-'),
                  _row(context, 'User ID', session?.userId ?? '-'),
                  _row(
                    context,
                    'Role',
                    session?.userRoleNameFk.isNotEmpty == true
                        ? session!.userRoleNameFk
                        : '-',
                  ),
                  _row(
                    context,
                    'Designation',
                    session?.designation.isNotEmpty == true
                        ? session!.designation
                        : '-',
                  ),
                  _row(
                    context,
                    'Department',
                    session?.departmentFk.isNotEmpty == true
                        ? session!.departmentFk
                        : '-',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppActionCard(
            title: 'Forgot password',
            icon: Icons.lock_reset_rounded,
            onTap: () => context.pushNamed(ForgotPasswordPage.routeName),
          ),
          const SizedBox(height: 10),
          AppActionCard(
            title: 'Settings',
            icon: Icons.settings_outlined,
            onTap: () => context.pushNamed(SettingsPage.routeName),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () async {
              final bool ok = await GlobalDialog.confirm(
                title: 'Log out',
                message: 'Sign out of ${AppConstants.appName}?',
                confirmLabel: 'Log out',
              );
              if (!ok) {
                return;
              }
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) {
                context.goNamed(LoginPage.routeName);
              }
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log out'),
          ),
          const SizedBox(height: 16),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (BuildContext context, AsyncSnapshot<PackageInfo> snap) {
              final String version = snap.data == null
                  ? AppConstants.appName
                  : '${AppConstants.appName}  ${snap.data!.version} (${snap.data!.buildNumber})';
              return Text(
                version,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _initialFor(AuthSession? session) {
    final String source = (session?.userName ?? session?.userId ?? 'S').trim();
    if (source.isEmpty) {
      return 'S';
    }
    return source.substring(0, 1).toUpperCase();
  }
}
