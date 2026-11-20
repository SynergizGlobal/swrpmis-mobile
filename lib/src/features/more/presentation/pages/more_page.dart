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
              if (expanded) ...<Widget>[
                const SizedBox(height: 6),
                _ChildrenPanel(
                  children: <Widget>[
                    for (int i = 0; i < children.length; i++) ...<Widget>[
                      if (i > 0) const _ChildDivider(),
                      _ChildRow(module: children[i], index: i),
                    ],
                  ],
                ),
              ],
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
    final Color accent = _accentFor(title, colors);
    return Material(
      color: palette.cardSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: accent.withValues(alpha: 0.28)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Padding(
          padding: AppTheme.cardPadding,
          child: Row(
            children: <Widget>[
              _IconBadge(icon: icon, accent: accent),
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

class _ChildrenPanel extends StatelessWidget {
  const _ChildrenPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class _ChildDivider extends StatelessWidget {
  const _ChildDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 44,
      endIndent: 8,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35),
    );
  }
}

class _ChildRow extends StatelessWidget {
  const _ChildRow({required this.module, required this.index});

  final AppModule module;
  final int index;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color accent = _accentFor(module.title, colors, index: index);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushNamed(module.routeName),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 6, 10),
          child: Row(
            children: <Widget>[
              _IconBadge(
                icon: module.icon,
                accent: accent,
                size: 34,
                iconSize: 18,
                radius: 10,
              ),
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
              Icon(
                Icons.chevron_right_rounded,
                color: accent.withValues(alpha: 0.9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    this.accent,
    this.size = 40,
    this.iconSize = 22,
    this.radius,
  });

  final IconData icon;
  final Color? accent;
  final double size;
  final double iconSize;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final Color tone = accent ?? Theme.of(context).colorScheme.primary;
    final double r = radius ?? AppTheme.cardRadius;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: tone.withValues(alpha: 0.22)),
      ),
      child: Icon(icon, color: tone, size: iconSize),
    );
  }
}

Color _accentFor(String name, ColorScheme colors, {int index = 0}) {
  const List<double> hues = <double>[210, 160, 28, 280, 190, 340];
  final int seed = name.trim().isEmpty
      ? index
      : name.toLowerCase().codeUnits.fold<int>(0, (int a, int b) => a + b);
  final double hue = hues[(seed + index) % hues.length];
  return HSLColor.fromAHSL(
    1,
    hue,
    colors.brightness == Brightness.dark ? 0.42 : 0.48,
    colors.brightness == Brightness.dark ? 0.72 : 0.42,
  ).toColor();
}
