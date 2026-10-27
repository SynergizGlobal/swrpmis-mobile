import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_list_scaffold.dart';
import 'package:swr_pmis_mobile/src/features/auth/domain/entities/auth_session.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_filter.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_dashboard_card.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_list_kind.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_menu.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_user_role.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/providers/rfi_inspection_provider.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/providers/rfi_log_provider.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/providers/rfi_section_launch.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_assign_executive_view.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_dashboard_view.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_inspection_view.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_list_view.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_log_view.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_reference_view.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_validation_view.dart';

class RfiPage extends ConsumerStatefulWidget {
  const RfiPage({super.key});

  static const String routeName = 'rfi';
  static const String routePath = '/rfi';

  @override
  ConsumerState<RfiPage> createState() => _RfiPageState();
}

class _RfiPageState extends ConsumerState<RfiPage> {
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
    final RfiMenuId sectionId = ref.watch(rfiCurrentSectionProvider);
    final RfiMenuItem? section = RfiMenuItem.byId(sectionId.name);
    final RfiListKind? listKind = RfiListKind.fromMenuId(section?.id);
    final bool interceptBack = _interceptSystemBack;

    return PopScope(
      canPop: !interceptBack,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop || !interceptBack) {
          return;
        }
        handleRfiBack(
          ref,
          shellIndex: StatefulNavigationShell.of(context).currentIndex,
          goHome: () => StatefulNavigationShell.of(context).goBranch(0),
        );
      },
      child: AppListScaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: creates.isEmpty || sectionId != RfiMenuId.home
            ? null
            : FloatingActionButton(
                tooltip: 'RFI',
                onPressed: () => _openCreateSheet(creates),
                child: const Icon(Icons.add_rounded),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: nav.bar.isEmpty
            ? null
            : _RfiNavBar(
                items: nav.bar,
                overflow: nav.overflow,
                selected: sectionId,
                onSelected: _selectSection,
              ),
        body: listKind != null
            ? RfiListView(key: ValueKey<RfiListKind>(listKind), kind: listKind)
            : section?.id == RfiMenuId.inspection
            ? const RfiInspectionView()
            : section?.id == RfiMenuId.validation
            ? const RfiValidationView()
            : section?.id == RfiMenuId.log
            ? const RfiLogView()
            : section?.id == RfiMenuId.assignExecutive
            ? const RfiAssignExecutiveView()
            : section?.id == RfiMenuId.inspectionReference
            ? const RfiReferenceView()
            : section == null || section.id == RfiMenuId.home
            ? RfiDashboardView(onOpenCard: _openCard)
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
    ref.read(rfiCurrentSectionProvider.notifier).select(picked);
  }

  void _selectSection(RfiMenuId id) {
    if (id == ref.read(rfiCurrentSectionProvider)) {
      return;
    }
    if (id == RfiMenuId.inspection) {
      _showInspection(const RfiInspectionFilter());
      return;
    }
    if (id == RfiMenuId.log) {
      _showLog(const RfiInspectionFilter());
      return;
    }
    ref.read(rfiCurrentSectionProvider.notifier).select(id);
  }

  void _openCard(RfiDashboardCardTarget target) {
    if (target.section == RfiMenuId.log) {
      _showLog(target.filter);
      return;
    }
    _showInspection(target.filter);
  }

  void _showInspection(RfiInspectionFilter filter) {
    ref.read(rfiSectionLaunchProvider.notifier).setInspection(filter);
    final bool already =
        ref.read(rfiCurrentSectionProvider) == RfiMenuId.inspection;
    ref.read(rfiCurrentSectionProvider.notifier).select(RfiMenuId.inspection);
    if (already) {
      ref.read(rfiInspectionControllerProvider.notifier).apply(filter);
    }
  }

  void _showLog(RfiInspectionFilter filter) {
    ref.read(rfiSectionLaunchProvider.notifier).setLog(filter);
    final bool already = ref.read(rfiCurrentSectionProvider) == RfiMenuId.log;
    ref.read(rfiCurrentSectionProvider.notifier).select(RfiMenuId.log);
    if (already) {
      ref.read(rfiLogControllerProvider.notifier).apply(filter);
    }
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
