import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/app/theme/theme_mode_provider.dart';
import 'package:swr_pmis_mobile/src/core/navigation/module_catalog.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_action_card.dart';
import 'package:swr_pmis_mobile/src/features/settings/presentation/pages/settings_page.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  static const String routeName = 'more';
  static const String routePath = '/more';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode mode = ref.watch(themeModeProvider);
    final List<AppModule> modules = ModuleCatalog.byGroup(ModuleGroup.more);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: <Widget>[
        Text(
          'Appearance',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            _ThemeChip(
              label: 'System',
              icon: Icons.brightness_auto_rounded,
              selected: mode == ThemeMode.system,
              onTap: () => ref
                  .read(themeModeProvider.notifier)
                  .setMode(ThemeMode.system),
            ),
            const SizedBox(width: 8),
            _ThemeChip(
              label: 'Light',
              icon: Icons.light_mode_rounded,
              selected: mode == ThemeMode.light,
              onTap: () =>
                  ref.read(themeModeProvider.notifier).setMode(ThemeMode.light),
            ),
            const SizedBox(width: 8),
            _ThemeChip(
              label: 'Dark',
              icon: Icons.dark_mode_rounded,
              selected: mode == ThemeMode.dark,
              onTap: () =>
                  ref.read(themeModeProvider.notifier).setMode(ThemeMode.dark),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          'Modules',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        ...modules.map(
          (AppModule module) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppActionCard(
              title: module.title,
              subtitle: module.subtitle,
              icon: module.icon,
              titleMaxLines: 2,
              onTap: () => context.pushNamed(module.routeName),
            ),
          ),
        ),
        AppActionCard(
          title: 'Settings',
          subtitle: 'Theme, account and app details',
          icon: Icons.settings_rounded,
          onTap: () => context.pushNamed(SettingsPage.routeName),
        ),
      ],
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    return Expanded(
      child: Material(
        color: selected
            ? colorScheme.primary.withValues(alpha: 0.14)
            : palette.cardSurface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: <Widget>[
                Icon(
                  icon,
                  color: selected ? colorScheme.primary : palette.mutedText,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
