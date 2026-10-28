import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/paging/table_page.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_filter_section.dart';
import 'package:swr_pmis_mobile/src/core/widgets/paged_table_column.dart';
import 'package:swr_pmis_mobile/src/core/widgets/table_pagination_footer.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_filter_option.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_clear_button.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_field.dart';
import 'package:swr_pmis_mobile/src/features/structures/domain/structure_list.dart';
import 'package:swr_pmis_mobile/src/features/structures/presentation/pages/add_structure_form_page.dart';
import 'package:swr_pmis_mobile/src/features/structures/presentation/providers/structures_provider.dart';
import 'package:swr_pmis_mobile/src/features/structures/presentation/widgets/structures_table.dart';

class StructuresListView extends ConsumerStatefulWidget {
  const StructuresListView({super.key});

  @override
  ConsumerState<StructuresListView> createState() => _StructuresListViewState();
}

class _StructuresListViewState extends ConsumerState<StructuresListView> {
  final TextEditingController _search = TextEditingController();
  Timer? _searchDebounce;
  int _pageSize = TablePage.defaultPageSize;
  int _page = 1;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _resetPage() {
    setState(() => _page = 1);
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) {
        return;
      }
      _resetPage();
      ref.read(structuresControllerProvider.notifier).setSearch(value);
    });
  }

  Future<void> _retry() {
    _resetPage();
    return ref.read(structuresControllerProvider.notifier).load();
  }

  Future<void> _onAdd() async {
    final Object? saved = await context.push<Object?>(
      AddStructureFormPage.routePath,
    );
    if (!mounted || saved != true) {
      return;
    }
    await _retry();
  }

  Future<void> _onEdit(StructureSummaryRow row) async {
    final String id = row.projectId.trim();
    if (id.isEmpty) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.warning,
        title: 'Edit Structure',
        message: 'This row has no project id to edit.',
      );
      return;
    }
    final Object? saved = await context.push<Object?>(
      AddStructureFormPage.location(projectId: id),
    );
    if (!mounted || saved != true) {
      return;
    }
    await _retry();
  }

  @override
  Widget build(BuildContext context) {
    final StructuresState state = ref.watch(structuresControllerProvider);
    final bool failed = state.error != null;
    final List<StructureSummaryRow> loaded = failed
        ? const <StructureSummaryRow>[]
        : state.snapshot.rows;
    final List<StructureSummaryRow> visible = loaded
        .where(
          (StructureSummaryRow row) => structureRowMatches(row, state.query),
        )
        .toList(growable: false);
    final TablePage<StructureSummaryRow> tablePage = TablePage.slice(
      visible,
      page: _page,
      pageSize: _pageSize,
    );
    if (tablePage.page != _page) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _page != tablePage.page) {
          setState(() => _page = tablePage.page);
        }
      });
    }
    final bool showFooter = !failed && !state.loading;
    final bool showSearch = !failed;

    return PagedTableColumn(
      header: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          RfiContentLoader(loading: state.loading),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: state.loading ? null : _onAdd,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add'),
                  ),
                ),
                const SizedBox(height: 12),
                AppFilterSection(
                  activeCount: AppFilterSection.countActive(<String?>[
                    state.query.projectId,
                  ]),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _FilterBar(
                        state: state,
                        enabled: !state.loading,
                        onProject: (String? value) {
                          _resetPage();
                          ref
                              .read(structuresControllerProvider.notifier)
                              .selectProject(value ?? '');
                        },
                        onClear: () {
                          _resetPage();
                          ref
                              .read(structuresControllerProvider.notifier)
                              .clearFilters();
                        },
                      ),
                      if (showSearch) ...<Widget>[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _search,
                          textInputAction: TextInputAction.search,
                          onChanged: (String value) {
                            setState(() {});
                            _onSearchChanged(value);
                          },
                          decoration: InputDecoration(
                            hintText: 'Search project',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _search.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear',
                                    onPressed: () {
                                      _search.clear();
                                      _onSearchChanged('');
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                            isDense: true,
                          ),
                        ),
                      ],
                    ],
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
          : state.loading && loaded.isEmpty
          ? const SizedBox.shrink()
          : visible.isEmpty
          ? _message(
              message: 'No structure records found.',
              onRetry: _retry,
            )
          : StructuresTable(rows: tablePage.items, onEdit: _onEdit),
      footer: showFooter
          ? TablePaginationFooter(
              label: tablePage.label,
              total: tablePage.total,
              page: tablePage.page,
              pageCount: tablePage.pageCount,
              pageSize: _pageSize,
              onPageChanged: (int next) {
                setState(() => _page = next);
              },
              onPageSizeChanged: (int size) {
                setState(() {
                  _pageSize = size;
                  _page = 1;
                });
              },
            )
          : null,
    );
  }

  Widget _message({required String message, required VoidCallback? onRetry}) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double minHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 0;
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
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

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.state,
    required this.enabled,
    required this.onProject,
    required this.onClear,
  });

  final StructuresState state;
  final bool enabled;
  final ValueChanged<String?> onProject;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final List<RfiFilterOption> projects = <RfiFilterOption>[
      for (final StructureOption option in state.snapshot.projects)
        RfiFilterOption(id: option.value, label: option.label),
    ];
    final String selected = state.query.projectId.trim();
    String? selectedLabel;
    if (selected.isNotEmpty) {
      selectedLabel = selected;
      for (final RfiFilterOption option in projects) {
        if (option.id == selected) {
          selectedLabel = option.label;
          break;
        }
      }
    }

    return RfiFilterGrid(
      children: <Widget>[
        RfiFilterField(
          label: 'Project',
          emptyLabel: 'Select Project',
          value: selectedLabel,
          options: projects,
          selectedId: selected.isEmpty ? null : selected,
          onClear: enabled && selected.isNotEmpty
              ? () => onProject('')
              : null,
          onPick: enabled
              ? (RfiFilterOption option) => onProject(option.id)
              : (_) {},
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: RfiFilterClearButton(
            label: 'Clear Filters',
            onPressed: enabled && selected.isNotEmpty ? onClear : null,
          ),
        ),
      ],
    );
  }
}
