import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/features/auth/domain/entities/auth_session.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_menu.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_user_role.dart';

class RfiPage extends ConsumerStatefulWidget {
  const RfiPage({super.key});

  static const String routeName = 'rfi';
  static const String routePath = '/rfi';

  @override
  ConsumerState<RfiPage> createState() => _RfiPageState();
}

class _RfiPageState extends ConsumerState<RfiPage> {
  RfiMenuId _section = RfiMenuId.home;
  GoRouterDelegate? _routerDelegate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final GoRouterDelegate delegate = GoRouter.of(context).routerDelegate;
    if (!identical(_routerDelegate, delegate)) {
      _routerDelegate?.removeListener(_onRouterChanged);
      _routerDelegate = delegate;
      _routerDelegate!.addListener(_onRouterChanged);
    }
  }

  void _onRouterChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _routerDelegate?.removeListener(_onRouterChanged);
    super.dispose();
  }

  bool get _interceptSystemBack =>
      StatefulNavigationShell.maybeOf(context)?.currentIndex == 3;

  @override
  Widget build(BuildContext context) {
    final AuthSession? session = ref.watch(authControllerProvider).valueOrNull;
    final RfiUserRole role = RfiUserRoleResolver.fromFields(
      userTypeFk: session?.userTypeFk ?? '',
      userRoleNameFk: session?.userRoleNameFk ?? '',
    );
    final ({List<RfiMenuItem> bar, List<RfiMenuItem> overflow}) nav =
        RfiMenuItem.navBarFor(role);
    final List<RfiMenuItem> creates = RfiMenuItem.createItemsFor(role);
    final RfiMenuItem? section = RfiMenuItem.byId(_section.name);
    final bool interceptBack = _interceptSystemBack;

    return PopScope(
      canPop: !interceptBack,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop || !interceptBack) {
          return;
        }
        StatefulNavigationShell.of(context).goBranch(0);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: creates.isEmpty
            ? null
            : FloatingActionButton(
                tooltip: 'Create RFI',
                onPressed: () => _openCreateSheet(creates),
                child: const Icon(Icons.add_rounded),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: nav.bar.isEmpty
            ? null
            : _RfiNavBar(
                items: nav.bar,
                overflow: nav.overflow,
                selected: _section,
                onSelected: (RfiMenuId id) {
                  setState(() => _section = id);
                },
              ),
        body: section == null || section.id == RfiMenuId.home
            ? const _RfiDashboard()
            : _RfiSectionBody(item: section),
      ),
    );
  }

  Future<void> _openCreateSheet(List<RfiMenuItem> creates) async {
    final RfiMenuId? picked = await showModalBottomSheet<RfiMenuId>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: creates
                .map(
                  (RfiMenuItem item) => ListTile(
                    leading: Icon(item.icon),
                    title: Text(item.title),
                    onTap: () => Navigator.pop(context, item.id),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _section = picked);
  }
}

class _RfiDashboard extends StatelessWidget {
  const _RfiDashboard();

  static const List<({String label, String value})> _samples =
      <({String label, String value})>[
        (label: 'RFI Created', value: '5'),
        (label: 'Under Inspection', value: '3'),
        (label: 'Validation Pending', value: '2'),
        (label: 'Approved', value: '4'),
      ];

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      children: <Widget>[
        Text(
          'RFI Dashboard',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Sample figures',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: palette.mutedText),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _samples.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.7,
          ),
          itemBuilder: (BuildContext context, int index) {
            final ({String label, String value}) sample = _samples[index];
            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFF1E4F8A), Color(0xFF3A7AB8)],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          sample.value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF34D399),
                          size: 22,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      sample.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RfiSectionBody extends StatelessWidget {
  const _RfiSectionBody({required this.item});

  final RfiMenuItem item;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 88),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              item.icon,
              size: 36,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              item.title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              item.pendingMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _RfiNavBar extends StatelessWidget {
  const _RfiNavBar({
    required this.items,
    required this.overflow,
    required this.selected,
    required this.onSelected,
  });

  final List<RfiMenuItem> items;
  final List<RfiMenuItem> overflow;
  final RfiMenuId selected;
  final ValueChanged<RfiMenuId> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool moreSelected = overflow.any(
      (RfiMenuItem item) => item.id == selected,
    );
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.navBarFill,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: palette.borderSubtle)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
          child: Row(
            children: <Widget>[
              for (final RfiMenuItem item in items)
                Expanded(
                  child: _NavButton(
                    icon: item.icon,
                    label: item.navLabel,
                    selected: item.id == selected,
                    onTap: () => onSelected(item.id),
                  ),
                ),
              if (overflow.isNotEmpty)
                Expanded(
                  child: _NavButton(
                    icon: Icons.more_horiz_rounded,
                    label: 'More',
                    selected: moreSelected,
                    onTap: () => _openOverflow(context),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openOverflow(BuildContext context) async {
    final RfiMenuId? picked = await showModalBottomSheet<RfiMenuId>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: overflow
                .map(
                  (RfiMenuItem item) => ListTile(
                    leading: Icon(item.icon),
                    title: Text(item.title),
                    onTap: () => Navigator.pop(context, item.id),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
    if (picked != null) {
      onSelected(picked);
    }
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool dark = colors.brightness == Brightness.dark;
    final Color foreground = selected ? colors.primary : palette.mutedText;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected
                ? Color.alphaBlend(
                    colors.primary.withValues(alpha: dark ? 0.45 : 0.22),
                    palette.navBarFill,
                  )
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: selected
                ? Border.all(
                    color: colors.primary.withValues(alpha: dark ? 0.75 : 0.5),
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 22, color: foreground),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: foreground,
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
