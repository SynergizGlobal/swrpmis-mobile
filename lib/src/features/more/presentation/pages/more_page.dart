import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/navigation/module_catalog.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/pages/reports_page.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  static const String routeName = 'more';
  static const String routePath = '/more';

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  bool _rdsoExpanded = false;

  @override
  Widget build(BuildContext context) {
    final List<AppModule> modules = ModuleCatalog.byGroup(ModuleGroup.more);
    final AppModule rdso = modules.firstWhere(
      (AppModule module) => module.id == 'rdso',
    );
    final AppModule mail = modules.firstWhere(
      (AppModule module) => module.id == 'mail',
    );
    final AppModule help = modules.firstWhere(
      (AppModule module) => module.id == 'help',
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: <Widget>[
        _CardRow(
          left: _MoreCard(
            title: rdso.title,
            icon: rdso.icon,
            expandable: true,
            expanded: _rdsoExpanded,
            onTap: () => setState(() => _rdsoExpanded = !_rdsoExpanded),
          ),
          right: _MoreCard(
            title: 'Reports',
            icon: Icons.insights_rounded,
            onTap: () => context.pushNamed(ReportsPage.routeName),
          ),
        ),
        if (_rdsoExpanded) ...<Widget>[
          const SizedBox(height: 12),
          _RdsoChildren(children: rdso.children),
        ],
        const SizedBox(height: 12),
        _CardRow(
          left: _MoreCard(
            title: mail.title,
            icon: mail.icon,
            onTap: () => context.pushNamed(mail.routeName),
          ),
          right: _MoreCard(
            title: help.title,
            icon: help.icon,
            onTap: () => context.pushNamed(help.routeName),
          ),
        ),
      ],
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(child: left),
          const SizedBox(width: 12),
          Expanded(child: right),
        ],
      ),
    );
  }
}

class _MoreCard extends StatelessWidget {
  const _MoreCard({
    required this.title,
    required this.icon,
    required this.onTap,
    this.expandable = false,
    this.expanded = false,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool expandable;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    return Material(
      color: palette.cardSurface,
      elevation: 0,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: expanded ? colors.primary : palette.borderSubtle,
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 132),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(icon, size: 32, color: colors.primary),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      color: colors.onSurface,
                    ),
                  ),
                  if (expandable) ...<Widget>[
                    const SizedBox(height: 4),
                    Icon(
                      expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 22,
                      color: palette.mutedText,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RdsoChildren extends StatelessWidget {
  const _RdsoChildren({required this.children});

  final List<AppModule> children;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0E1F36)
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int index = 0; index < children.length; index++) ...<Widget>[
                if (index > 0) const SizedBox(width: 10),
                Expanded(child: _RdsoChildCard(module: children[index])),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RdsoChildCard extends StatelessWidget {
  const _RdsoChildCard({required this.module});

  final AppModule module;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF1A3354) : palette.cardSurface,
      elevation: 0,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.pushNamed(module.routeName),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.borderSubtle),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(module.icon, size: 26, color: colors.primary),
                const SizedBox(height: 8),
                Text(
                  module.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: colors.onSurface,
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
