import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/features/rdso/domain/rdso_list.dart';
import 'package:swr_pmis_mobile/src/features/rdso/presentation/providers/rdso_library_provider.dart';

/// Side panel / drawer content: expandable category → subhead browser.
class RdsoLibraryCategoryPanel extends StatefulWidget {
  const RdsoLibraryCategoryPanel({
    super.key,
    required this.state,
    required this.expanded,
    required this.onToggleCategory,
    required this.onSelectSubhead,
    this.onRevealCategory,
    this.onClose,
  });

  final RdsoLibraryState state;
  final Set<String> expanded;
  final ValueChanged<String> onToggleCategory;
  final ValueChanged<RdsoSubhead> onSelectSubhead;
  final ValueChanged<String>? onRevealCategory;
  final VoidCallback? onClose;

  @override
  State<RdsoLibraryCategoryPanel> createState() =>
      _RdsoLibraryCategoryPanelState();
}

class _RdsoLibraryCategoryPanelState extends State<RdsoLibraryCategoryPanel> {
  final TextEditingController _filter = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  bool _isArchivedCategory(RdsoCategory category) {
    final String name = category.name.toLowerCase();
    return name.contains('archiv');
  }

  void _expandAll(Iterable<RdsoCategory> categories) {
    for (final RdsoCategory category in categories) {
      if (!widget.expanded.contains(category.id)) {
        widget.onToggleCategory(category.id);
      }
    }
  }

  void _collapseAll() {
    for (final String id in widget.expanded.toList(growable: false)) {
      widget.onToggleCategory(id);
    }
  }

  bool _categoryMatchesFilter(RdsoCategory category, String q) {
    if (category.name.toLowerCase().contains(q)) {
      return true;
    }
    final List<RdsoSubhead> subheads =
        widget.state.subheadsByCategory[category.id] ?? const <RdsoSubhead>[];
    return subheads.any((RdsoSubhead s) => s.name.toLowerCase().contains(q));
  }

  List<RdsoCategory> _filtered(List<RdsoCategory> source) {
    final String q = _query.trim().toLowerCase();
    if (q.isEmpty) {
      return source;
    }
    return source
        .where((RdsoCategory category) => _categoryMatchesFilter(category, q))
        .toList(growable: false);
  }

  void _onFilterChanged(String value) {
    setState(() => _query = value);
    final String q = value.trim().toLowerCase();
    final ValueChanged<String>? reveal = widget.onRevealCategory;
    if (q.isEmpty || reveal == null) {
      return;
    }
    for (final RdsoCategory category in widget.state.categories) {
      if (_categoryMatchesFilter(category, q)) {
        reveal(category.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    final List<RdsoCategory> all = widget.state.categories;
    final List<RdsoCategory> active = all
        .where((RdsoCategory c) => !_isArchivedCategory(c))
        .toList(growable: false);
    final List<RdsoCategory> archived = all
        .where(_isArchivedCategory)
        .toList(growable: false);

    final List<RdsoCategory> filteredActive = _filtered(active);
    final List<RdsoCategory> filteredArchived = _filtered(archived);
    final bool hasFilter = _query.trim().isNotEmpty;

    final bool inDrawer = widget.onClose != null;
    final Widget header = Container(
      padding: EdgeInsets.fromLTRB(16, inDrawer ? 14 : 16, 4, 14),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(color: colors.outlineVariant),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.account_tree_rounded, color: colors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Categories',
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
                Text(
                  'Pick a subhead to load drawings',
                  style: text.labelSmall?.copyWith(
                    color: palette.mutedText,
                  ),
                ),
              ],
            ),
          ),
          if (widget.onClose != null)
            IconButton(
              tooltip: 'Close',
              onPressed: widget.onClose,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
    );

    return Material(
      color: colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (inDrawer)
            SafeArea(bottom: false, child: header)
          else
            header,
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _filter,
              textInputAction: TextInputAction.search,
              onChanged: _onFilterChanged,
              decoration: InputDecoration(
                hintText: 'Filter categories…',
                isDense: true,
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear filter',
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _filter.clear();
                          _onFilterChanged('');
                        },
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: <Widget>[
                TextButton.icon(
                  onPressed: filteredActive.isEmpty && filteredArchived.isEmpty
                      ? null
                      : () => _expandAll(<RdsoCategory>[
                          ...filteredActive,
                          ...filteredArchived,
                        ]),
                  icon: const Icon(Icons.unfold_more_rounded, size: 18),
                  label: const Text('Expand all'),
                ),
                TextButton.icon(
                  onPressed: widget.expanded.isEmpty ? null : _collapseAll,
                  icon: const Icon(Icons.unfold_less_rounded, size: 18),
                  label: const Text('Collapse'),
                ),
              ],
            ),
          ),
          Expanded(
            child: all.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No categories loaded yet.',
                        textAlign: TextAlign.center,
                        style: text.bodyMedium?.copyWith(color: palette.mutedText),
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                    children: <Widget>[
                      if (filteredActive.isNotEmpty) ...<Widget>[
                        _SectionLabel(
                          title: 'DRAWINGS',
                          trailing: '${filteredActive.length}',
                        ),
                        ...filteredActive.map(
                          (RdsoCategory category) => _CategoryNode(
                            category: category,
                            state: widget.state,
                            expanded: widget.expanded.contains(category.id),
                            filterQuery: _query,
                            onToggle: () => widget.onToggleCategory(category.id),
                            onSelectSubhead: (RdsoSubhead subhead) {
                              widget.onSelectSubhead(subhead);
                              widget.onClose?.call();
                            },
                          ),
                        ),
                      ],
                      if (filteredArchived.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 8),
                        Divider(height: 1, color: colors.outlineVariant),
                        const SizedBox(height: 8),
                        _SectionLabel(
                          title: 'ARCHIVED DRAWINGS',
                          icon: Icons.inventory_2_outlined,
                          trailing: '${filteredArchived.length}',
                        ),
                        ...filteredArchived.map(
                          (RdsoCategory category) => _CategoryNode(
                            category: category,
                            state: widget.state,
                            expanded: widget.expanded.contains(category.id),
                            filterQuery: _query,
                            archivedTone: true,
                            onToggle: () => widget.onToggleCategory(category.id),
                            onSelectSubhead: (RdsoSubhead subhead) {
                              widget.onSelectSubhead(subhead);
                              widget.onClose?.call();
                            },
                          ),
                        ),
                      ],
                      if (filteredActive.isEmpty &&
                          filteredArchived.isEmpty &&
                          hasFilter)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No categories match “$_query”.',
                            textAlign: TextAlign.center,
                            style: text.bodyMedium?.copyWith(
                              color: palette.mutedText,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.title,
    this.trailing,
    this.icon,
  });

  final String title;
  final String? trailing;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 14, color: palette.mutedText),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: palette.mutedText,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: palette.mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryNode extends StatelessWidget {
  const _CategoryNode({
    required this.category,
    required this.state,
    required this.expanded,
    required this.filterQuery,
    required this.onToggle,
    required this.onSelectSubhead,
    this.archivedTone = false,
  });

  final RdsoCategory category;
  final RdsoLibraryState state;
  final bool expanded;
  final String filterQuery;
  final VoidCallback onToggle;
  final ValueChanged<RdsoSubhead> onSelectSubhead;
  final bool archivedTone;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    final bool loading = state.loadingSubheads.contains(category.id);
    final Object? loadError = state.subheadErrorsByCategory[category.id];
    final List<RdsoSubhead> subheads =
        state.subheadsByCategory[category.id] ?? const <RdsoSubhead>[];
    final String q = filterQuery.trim().toLowerCase();
    final List<RdsoSubhead> visibleSubheads = q.isEmpty
        ? subheads
        : subheads
            .where((RdsoSubhead s) => s.name.toLowerCase().contains(q))
            .toList(growable: false);
    final bool categoryMatches =
        q.isNotEmpty && category.name.toLowerCase().contains(q);

    final Color categoryIconBg = archivedTone
        ? colors.outlineVariant.withValues(alpha: 0.35)
        : colors.primary.withValues(alpha: 0.12);
    final Color categoryIconColor =
        archivedTone ? colors.onSurfaceVariant : colors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: palette.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.8)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            InkWell(
              onTap: onToggle,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Row(
                    children: <Widget>[
                      AnimatedRotation(
                        turns: expanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: categoryIconBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          archivedTone
                              ? Icons.inventory_2_outlined
                              : Icons.folder_outlined,
                          size: 20,
                          color: categoryIconColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          category.name,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (subheads.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${subheads.length}',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _SubheadList(
                loading: loading && subheads.isEmpty,
                loadError: loadError,
                subheads: visibleSubheads,
                showCategoryMatchHint: categoryMatches && visibleSubheads.isEmpty,
                selectedSubheadId: state.selectedSubheadId,
                onSelectSubhead: onSelectSubhead,
              ),
              crossFadeState: expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
              sizeCurve: Curves.easeOutCubic,
            ),
          ],
        ),
      ),
    );
  }
}

class _SubheadList extends StatelessWidget {
  const _SubheadList({
    required this.loading,
    this.loadError,
    required this.subheads,
    required this.showCategoryMatchHint,
    required this.selectedSubheadId,
    required this.onSelectSubhead,
  });

  final bool loading;
  final Object? loadError;
  final List<RdsoSubhead> subheads;
  final bool showCategoryMatchHint;
  final String selectedSubheadId;
  final ValueChanged<RdsoSubhead> onSelectSubhead;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);

    if (loading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(12, 4, 12, 14),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (subheads.isEmpty) {
      final Object? error = loadError;
      if (error != null) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
          child: Text(
            error is DioException
                ? userFriendlyErrorMessage(error)
                : error.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.error,
            ),
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
        child: Text(
          showCategoryMatchHint
              ? 'Expand to load subheads for this category.'
              : 'No subheads in this category.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: palette.mutedText,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 8, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: colors.primary.withValues(alpha: 0.35),
              width: 2,
            ),
          ),
        ),
        child: Column(
          children: subheads
              .map(
                (RdsoSubhead subhead) => _SubheadTile(
                  subhead: subhead,
                  selected: subhead.id == selectedSubheadId,
                  onTap: () => onSelectSubhead(subhead),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _SubheadTile extends StatelessWidget {
  const _SubheadTile({
    required this.subhead,
    required this.selected,
    required this.onTap,
  });

  final RdsoSubhead subhead;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color bg = selected
        ? colors.primaryContainer
        : Colors.transparent;
    final Color fg = selected ? colors.onPrimaryContainer : colors.onSurface;

    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: <Widget>[
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.description_outlined,
                    size: 20,
                    color: selected ? colors.primary : colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      subhead.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: fg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
