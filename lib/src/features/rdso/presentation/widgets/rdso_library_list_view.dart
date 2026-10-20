import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/paged_table_column.dart';
import 'package:swr_pmis_mobile/src/core/widgets/table_pagination_footer.dart';
import 'package:swr_pmis_mobile/src/features/rdso/domain/rdso_list.dart';
import 'package:swr_pmis_mobile/src/features/rdso/presentation/pages/rdso_drawing_detail_page.dart';
import 'package:swr_pmis_mobile/src/features/rdso/presentation/providers/rdso_library_provider.dart';
import 'package:swr_pmis_mobile/src/features/rdso/presentation/widgets/rdso_library_dialogs.dart';
import 'package:swr_pmis_mobile/src/features/rdso/presentation/widgets/rdso_revision_table.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_filter_option.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_field.dart';

class RdsoLibraryListView extends ConsumerStatefulWidget {
  const RdsoLibraryListView({super.key});

  @override
  ConsumerState<RdsoLibraryListView> createState() =>
      _RdsoLibraryListViewState();
}

class _RdsoLibraryListViewState extends ConsumerState<RdsoLibraryListView> {
  final TextEditingController _search = TextEditingController();
  final Set<String> _expandedCategories = <String>{};
  bool _syncBusy = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openDrawing(RdsoDrawingRow row) {
    context.push(RdsoDrawingDetailPage.routePathFor(row.id), extra: row);
  }

  Future<void> _retry() {
    return ref.read(rdsoLibraryControllerProvider.notifier).loadCategories();
  }

  Future<void> _onImportStatus() {
    return showRdsoImportStatusDialog(context: context, ref: ref);
  }

  Future<void> _onSyncNow() async {
    if (_syncBusy) {
      return;
    }
    setState(() => _syncBusy = true);
    try {
      await runRdsoSyncNow(context: context, ref: ref);
    } finally {
      if (mounted) {
        setState(() => _syncBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final RdsoLibraryState state = ref.watch(rdsoLibraryControllerProvider);
    if (state.draft.q.isEmpty && _search.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            ref.read(rdsoLibraryControllerProvider).draft.q.isEmpty &&
            _search.text.isNotEmpty) {
          _search.clear();
        }
      });
    }

    final bool failed = state.error != null && state.categories.isEmpty;
    final List<RdsoDrawingRow> rows = failed
        ? const <RdsoDrawingRow>[]
        : state.visibleDrawings;
    final int total = failed ? 0 : state.total;
    final int pageSize = state.query.size < 1
        ? RdsoRevisionQuery.defaultSize
        : state.query.size;
    final bool searchMode = state.mode == RdsoLibraryListMode.search;
    final int pageCount = searchMode
        ? (total == 0 ? 1 : (total / pageSize).ceil())
        : 1;
    int page = state.query.page < 1 ? 1 : state.query.page;
    if (page > pageCount) {
      page = pageCount;
    }
    final int start = total == 0 ? 0 : (page - 1) * pageSize;
    final int end = total == 0
        ? 0
        : math.min(start + rows.length, total);
    final String label = total == 0
        ? 'Showing 0 to 0 of 0 entries'
        : 'Showing ${start + 1} to $end of $total entries';
    final bool showFooter =
        searchMode && !failed && !state.loading && total > 0;
    final bool filtersEnabled = !state.loading && !_syncBusy;

    return PagedTableColumn(
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          RfiContentLoader(loading: state.loading || _syncBusy),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: _syncBusy ? null : _onImportStatus,
                      icon: const Icon(Icons.info_outline_rounded, size: 18),
                      label: const Text('Import Status'),
                    ),
                    FilledButton.icon(
                      onPressed: _syncBusy ? null : _onSyncNow,
                      icon: const Icon(Icons.sync_rounded, size: 18),
                      label: const Text('Sync Now'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _LibraryFilterBar(
                  state: state,
                  search: _search,
                  enabled: filtersEnabled,
                  onSearchChanged: (String value) {
                    ref
                        .read(rdsoLibraryControllerProvider.notifier)
                        .setDraftSearch(value);
                    setState(() {});
                  },
                  onCategory: (String? value) {
                    ref
                        .read(rdsoLibraryControllerProvider.notifier)
                        .setDraftCategory(value ?? '');
                  },
                  onStatus: (String? value) {
                    ref
                        .read(rdsoLibraryControllerProvider.notifier)
                        .setDraftStatus(value ?? '');
                  },
                  onSearch: () {
                    ref
                        .read(rdsoLibraryControllerProvider.notifier)
                        .applySearch();
                  },
                  onReset: () {
                    _search.clear();
                    ref
                        .read(rdsoLibraryControllerProvider.notifier)
                        .resetFilters();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                if (!failed && state.categories.isNotEmpty)
                  _CategoryTree(
                    state: state,
                    expanded: _expandedCategories,
                    onToggle: (String categoryId) {
                      setState(() {
                        if (_expandedCategories.contains(categoryId)) {
                          _expandedCategories.remove(categoryId);
                        } else {
                          _expandedCategories.add(categoryId);
                        }
                      });
                      ref
                          .read(rdsoLibraryControllerProvider.notifier)
                          .loadSubheads(categoryId);
                    },
                    onSelectSubhead: (RdsoSubhead subhead) {
                      ref
                          .read(rdsoLibraryControllerProvider.notifier)
                          .selectSubhead(subhead);
                    },
                  ),
                if (state.selectedSubheadName.trim().isNotEmpty &&
                    state.mode == RdsoLibraryListMode.tree)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      state.selectedSubheadName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: failed
          ? _message(
              message: state.error is DioException
                  ? userFriendlyErrorMessage(state.error! as DioException)
                  : state.error.toString(),
              onRetry: _retry,
            )
          : state.loading && rows.isEmpty
          ? const SizedBox.shrink()
          : rows.isEmpty
          ? _message(
              message: state.mode == RdsoLibraryListMode.tree &&
                      state.selectedSubheadId.isEmpty
                  ? 'Select a category subhead or search for drawings.'
                  : 'No drawings match these filters.',
              onRetry: state.mode == RdsoLibraryListMode.search ? _retry : null,
            )
          : RdsoLibraryDrawingsTable(
              rows: rows,
              onOpen: _openDrawing,
            ),
      footer: showFooter
          ? TablePaginationFooter(
              label: label,
              total: total,
              page: page,
              pageCount: pageCount,
              pageSize: pageSize,
              onPageChanged: (int next) {
                ref.read(rdsoLibraryControllerProvider.notifier).setPage(next);
              },
              onPageSizeChanged: (int size) {
                ref
                    .read(rdsoLibraryControllerProvider.notifier)
                    .setPageSize(size);
              },
            )
          : null,
    );
  }

  Widget _message({required String message, VoidCallback? onRetry}) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double minHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 0;
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: SizedBox(
            height: math.max(minHeight, 120),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(message, textAlign: TextAlign.center),
                    if (onRetry != null) ...<Widget>[
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: onRetry,
                        child: const Text('Retry'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CategoryTree extends StatelessWidget {
  const _CategoryTree({
    required this.state,
    required this.expanded,
    required this.onToggle,
    required this.onSelectSubhead,
  });

  final RdsoLibraryState state;
  final Set<String> expanded;
  final ValueChanged<String> onToggle;
  final ValueChanged<RdsoSubhead> onSelectSubhead;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      color: palette.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
              child: Text(
                'Category',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            for (final RdsoCategory category in state.categories)
              _CategoryNode(
                category: category,
                expanded: expanded.contains(category.id),
                loading: state.loadingSubheads.contains(category.id),
                subheads: state.subheadsByCategory[category.id] ??
                    const <RdsoSubhead>[],
                selectedSubheadId: state.selectedSubheadId,
                onToggle: () => onToggle(category.id),
                onSelectSubhead: onSelectSubhead,
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryNode extends StatelessWidget {
  const _CategoryNode({
    required this.category,
    required this.expanded,
    required this.loading,
    required this.subheads,
    required this.selectedSubheadId,
    required this.onToggle,
    required this.onSelectSubhead,
  });

  final RdsoCategory category;
  final bool expanded;
  final bool loading;
  final List<RdsoSubhead> subheads;
  final String selectedSubheadId;
  final VoidCallback onToggle;
  final ValueChanged<RdsoSubhead> onSelectSubhead;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ListTile(
          dense: true,
          leading: Icon(
            expanded ? Icons.expand_more : Icons.chevron_right,
            color: colors.primary,
          ),
          title: Text(
            category.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          onTap: onToggle,
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: loading && subheads.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : subheads.isEmpty
                ? const Padding(
                    padding: EdgeInsets.fromLTRB(24, 0, 12, 8),
                    child: Text('No subheads'),
                  )
                : Column(
                    children: subheads
                        .map(
                          (RdsoSubhead subhead) => ListTile(
                            dense: true,
                            selected: subhead.id == selectedSubheadId,
                            title: Text(subhead.name),
                            onTap: () => onSelectSubhead(subhead),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
      ],
    );
  }
}

class _LibraryFilterBar extends StatelessWidget {
  const _LibraryFilterBar({
    required this.state,
    required this.search,
    required this.enabled,
    required this.onSearchChanged,
    required this.onCategory,
    required this.onStatus,
    required this.onSearch,
    required this.onReset,
  });

  final RdsoLibraryState state;
  final TextEditingController search;
  final bool enabled;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onCategory;
  final ValueChanged<String?> onStatus;
  final VoidCallback onSearch;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final RdsoLibraryQuery draft = state.draft;
    final List<RfiFilterOption> categories = state.categories
        .map(
          (RdsoCategory c) => RfiFilterOption(id: c.id, label: c.name),
        )
        .toList(growable: false);
    final List<RfiFilterOption> statuses = const <RfiFilterOption>[
      RfiFilterOption(id: 'Current', label: 'Current'),
      RfiFilterOption(id: 'Archived', label: 'Archived'),
    ];

    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: search,
              textInputAction: TextInputAction.search,
              onChanged: onSearchChanged,
              onSubmitted: (_) => onSearch(),
              decoration: InputDecoration(
                hintText: 'Search drawing no., title, keyword...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        onPressed: () {
                          search.clear();
                          onSearchChanged('');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            RfiFilterGrid(
              children: <Widget>[
                RfiFilterField(
                  label: 'Category',
                  emptyLabel: '-- Select Category --',
                  value: _selectedLabel(categories, draft.categoryId),
                  options: categories,
                  selectedId: draft.categoryId.isEmpty
                      ? null
                      : draft.categoryId,
                  onClear: draft.categoryId.isEmpty
                      ? null
                      : () => onCategory(''),
                  onPick: (RfiFilterOption option) => onCategory(option.id),
                ),
                IgnorePointer(
                  child: Opacity(
                    opacity: 0.55,
                    child: RfiFilterField(
                      label: 'Department',
                      emptyLabel: '-- Select Department --',
                      value: null,
                      options: const <RfiFilterOption>[],
                      selectedId: null,
                      onClear: null,
                      onPick: (_) {},
                    ),
                  ),
                ),
                RfiFilterField(
                  label: 'Status',
                  emptyLabel: '-- Select Status --',
                  value: _selectedLabel(statuses, draft.status),
                  options: statuses,
                  selectedId: draft.status.isEmpty ? null : draft.status,
                  onClear: draft.status.isEmpty ? null : () => onStatus(''),
                  onPick: (RfiFilterOption option) => onStatus(option.id),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: enabled ? onSearch : null,
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: const Text('Search'),
                ),
                OutlinedButton(
                  onPressed: enabled ? onReset : null,
                  child: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _selectedLabel(List<RfiFilterOption> options, String id) {
    if (id.trim().isEmpty) {
      return null;
    }
    for (final RfiFilterOption option in options) {
      if (option.id == id) {
        return option.label;
      }
    }
    return id;
  }
}
