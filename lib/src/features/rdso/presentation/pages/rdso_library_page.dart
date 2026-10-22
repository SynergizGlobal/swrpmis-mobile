import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/navigation/app_system_back.dart';
import 'package:swr_pmis_mobile/src/features/rdso/domain/rdso_list.dart';
import 'package:swr_pmis_mobile/src/features/rdso/presentation/providers/rdso_library_provider.dart';
import 'package:swr_pmis_mobile/src/features/rdso/presentation/widgets/rdso_library_category_panel.dart';
import 'package:swr_pmis_mobile/src/features/rdso/presentation/widgets/rdso_library_list_view.dart';

class RdsoLibraryPage extends ConsumerStatefulWidget {
  const RdsoLibraryPage({super.key});

  static const String routeName = 'more-rdso';
  static const String routePath = '/module/rdso';

  @override
  ConsumerState<RdsoLibraryPage> createState() => _RdsoLibraryPageState();
}

class _RdsoLibraryPageState extends ConsumerState<RdsoLibraryPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Set<String> _expandedCategories = <String>{};

  void _toggleCategory(String categoryId) {
    final bool expanding = !_expandedCategories.contains(categoryId);
    setState(() {
      if (expanding) {
        _expandedCategories.add(categoryId);
      } else {
        _expandedCategories.remove(categoryId);
      }
    });
    if (expanding) {
      ref.read(rdsoLibraryControllerProvider.notifier).loadSubheads(categoryId);
    }
  }

  void _revealCategory(String categoryId) {
    if (!_expandedCategories.contains(categoryId)) {
      setState(() => _expandedCategories.add(categoryId));
    }
    ref.read(rdsoLibraryControllerProvider.notifier).loadSubheads(categoryId);
  }

  void _selectSubhead(RdsoSubhead subhead) {
    ref.read(rdsoLibraryControllerProvider.notifier).selectSubhead(subhead);
  }

  Widget _categoryPanel({VoidCallback? onClose}) {
    final RdsoLibraryState state = ref.watch(rdsoLibraryControllerProvider);
    return RdsoLibraryCategoryPanel(
      state: state,
      expanded: _expandedCategories,
      onToggleCategory: _toggleCategory,
      onRevealCategory: _revealCategory,
      onSelectSubhead: _selectSubhead,
      onClose: onClose,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool wide = width >= 900;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('RDSO Digital Library'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => AppSystemBack.invoke(context),
        ),
      ),
      drawer: wide
          ? null
          : Drawer(
              width: math.min(width * 0.88, 340),
              child: _categoryPanel(
                onClose: () => Navigator.of(context).pop(),
              ),
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (!wide)
            _RdsoCategoryBrowseBar(
              onOpenCategories: () =>
                  _scaffoldKey.currentState?.openDrawer(),
            ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (wide)
                  SizedBox(
                    width: 300,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                      ),
                      child: _categoryPanel(),
                    ),
                  ),
                const Expanded(child: RdsoLibraryListView()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Secondary bar below the app bar: opens the category drawer on narrow layouts.
class _RdsoCategoryBrowseBar extends StatelessWidget {
  const _RdsoCategoryBrowseBar({required this.onOpenCategories});

  final VoidCallback onOpenCategories;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool dark = colors.brightness == Brightness.dark;
    final Color barFill = Color.alphaBlend(
      colors.primary.withValues(alpha: dark ? 0.14 : 0.06),
      colors.surface,
    );

    return Material(
      color: barFill,
      child: InkWell(
        onTap: onOpenCategories,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: colors.outlineVariant),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: <Widget>[
                IconButton(
                  tooltip: 'Categories',
                  icon: Icon(Icons.menu_rounded, color: colors.onSurface),
                  onPressed: onOpenCategories,
                ),
                Expanded(
                  child: Text(
                    'Browse categories',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
