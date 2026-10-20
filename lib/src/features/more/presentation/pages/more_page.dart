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
        _ExpandableRow(
          title: rdso.title,
          icon: rdso.icon,
          expanded: _rdsoExpanded,
          childCount: rdso.children.length,
          onTap: () => setState(() => _rdsoExpanded = !_rdsoExpanded),
          children: rdso.children,
        ),
        const SizedBox(height: 10),
        _LeafRow(
          title: 'Reports',
          icon: Icons.insights_rounded,
          onTap: () => context.pushNamed(ReportsPage.routeName),
        ),
        const SizedBox(height: 10),
        _LeafRow(
          title: mail.title,
          icon: mail.icon,
          onTap: () => context.pushNamed(mail.routeName),
        ),
        const SizedBox(height: 10),
        _LeafRow(
          title: help.title,
          icon: help.icon,
          onTap: () => context.pushNamed(help.routeName),
        ),
      ],
    );
  }
}

class _ExpandableRow extends StatelessWidget {
  const _ExpandableRow({
    required this.title,
    required this.icon,
    required this.expanded,
    required this.childCount,
    required this.onTap,
    required this.children,
  });

  final String title;
  final IconData icon;
  final bool expanded;
  final int childCount;
  final VoidCallback onTap;
  final List<AppModule> children;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      color: palette.cardSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(
          color: expanded ? colors.primary : colors.outlineVariant,
        ),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.topCenter,
        child: Padding(
          padding: AppTheme.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: <Widget>[
                      _IconBadge(icon: icon),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colors.onSurface,
                              ),
                        ),
                      ),
                      Text(
                        '$childCount',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: palette.mutedText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Icon(
                        expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: palette.mutedText,
                      ),
                    ],
                  ),
                ),
              ),
              if (expanded)
                for (final AppModule child in children)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ChildRow(module: child),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeafRow extends StatelessWidget {
  const _LeafRow({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      color: palette.cardSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Padding(
          padding: AppTheme.cardPadding,
          child: Row(
            children: <Widget>[
              _IconBadge(icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildRow extends StatelessWidget {
  const _ChildRow({required this.module});

  final AppModule module;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      color: AppPalette.of(context).cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: () => context.pushNamed(module.routeName),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Padding(
          padding: AppTheme.cardPadding,
          child: Row(
            children: <Widget>[
              Icon(module.icon, color: colors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  module.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Icon(icon, color: colors.primary),
    );
  }
}
