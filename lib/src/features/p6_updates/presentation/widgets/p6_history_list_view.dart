import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/paging/table_page.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_filter_section.dart';
import 'package:swr_pmis_mobile/src/core/widgets/paged_table_column.dart';
import 'package:swr_pmis_mobile/src/core/widgets/table_pagination_footer.dart';
import 'package:swr_pmis_mobile/src/features/p6_updates/domain/p6_list.dart';
import 'package:swr_pmis_mobile/src/features/p6_updates/presentation/providers/p6_providers.dart';
import 'package:swr_pmis_mobile/src/features/p6_updates/presentation/widgets/p6_history_table.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_filter_option.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_clear_button.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_field.dart';

class P6HistoryListView extends ConsumerStatefulWidget {
  const P6HistoryListView({super.key});

  @override
  ConsumerState<P6HistoryListView> createState() => _P6HistoryListViewState();
}

class _P6HistoryListViewState extends ConsumerState<P6HistoryListView> {
  final TextEditingController _search = TextEditingController();
  int _pageSize = TablePage.defaultPageSize;
  int _page = 1;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _resetPage() {
    setState(() => _page = 1);
  }

  void _selectContract(String? value) {
    _resetPage();
    ref
        .read(p6HistoryControllerProvider.notifier)
        .selectContract(value ?? '');
  }

  void _selectUploadType(String? value) {
    _resetPage();
    ref
        .read(p6HistoryControllerProvider.notifier)
        .selectUploadType(value ?? '');
  }

  void _selectStatus(String? value) {
    _resetPage();
    ref.read(p6HistoryControllerProvider.notifier).selectStatus(value ?? '');
  }

  void _clearFilters() {
    _resetPage();
    ref.read(p6HistoryControllerProvider.notifier).clearFilters();
  }

  Future<void> _retry() {
    _resetPage();
    return ref.read(p6HistoryControllerProvider.notifier).load();
  }

  Future<void> _onFileTap(P6HistoryRow row) async {
    if (!mounted || row.uploadedFile.trim().isEmpty) {
      return;
    }
    await AppDialog.show(
      context,
      title: 'Download',
      message:
          'File download for "${row.uploadedFile}" is not wired yet — '
          'no confirmed P6 file URL pattern was found.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final P6HistoryState state = ref.watch(p6HistoryControllerProvider);
    final bool failed = state.error != null;
    final List<P6HistoryRow> loaded = failed
        ? const <P6HistoryRow>[]
        : state.snapshot.rows;
    final List<P6HistoryRow> visible = loaded
        .where((P6HistoryRow row) => _matches(row, _search.text))
        .toList(growable: false);
    final TablePage<P6HistoryRow> tablePage = TablePage.slice(
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
            child: AppFilterSection(
              activeCount: AppFilterSection.countActive(<String?>[
                state.query.contractId,
                state.query.uploadType,
                state.query.status,
              ]),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _FilterBar(
                    state: state,
                    enabled: !state.loading,
                    onContract: _selectContract,
                    onUploadType: _selectUploadType,
                    onStatus: _selectStatus,
                    onClear: _clearFilters,
                  ),
                  if (showSearch) ...<Widget>[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _search,
                      textInputAction: TextInputAction.search,
                      onChanged: (_) => _resetPage(),
                      decoration: InputDecoration(
                        hintText: 'Search',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _search.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear',
                                onPressed: () {
                                  _search.clear();
                                  _resetPage();
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
              message: loaded.isEmpty
                  ? 'No P6 data history found.'
                  : 'No matching history rows.',
              onRetry: loaded.isEmpty ? _retry : null,
            )
          : P6HistoryTable(rows: tablePage.items, onOpenFile: _onFileTap),
      footer: showFooter
          ? TablePaginationFooter(
              label: tablePage.label,
              total: tablePage.total,
              page: tablePage.page,
              pageCount: tablePage.pageCount,
              pageSize: _pageSize,
              onPageChanged: (int page) => setState(() => _page = page),
              onPageSizeChanged: (int size) => setState(() {
                _pageSize = size;
                _page = 1;
              }),
            )
          : null,
    );
  }

  bool _matches(P6HistoryRow row, String query) {
    final String needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return true;
    }
    return p6HistoryExportCells(
      row,
    ).any((String part) => part.toLowerCase().contains(needle));
  }

  Widget _message({required String message, required VoidCallback? onRetry}) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double minHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 0;
        return _FillScroll(
          minHeight: minHeight,
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
        );
      },
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.state,
    required this.enabled,
    required this.onContract,
    required this.onUploadType,
    required this.onStatus,
    required this.onClear,
  });

  final P6HistoryState state;
  final bool enabled;
  final ValueChanged<String?> onContract;
  final ValueChanged<String?> onUploadType;
  final ValueChanged<String?> onStatus;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final P6HistoryQuery query = state.query;
    final P6HistorySnapshot snapshot = state.snapshot;
    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: RfiFilterGrid(
          children: <Widget>[
            _field(
              label: 'Select contract',
              emptyLabel: 'Select contract',
              options: snapshot.contracts,
              selected: query.contractId,
              onChanged: onContract,
            ),
            _field(
              label: 'Select dataType',
              emptyLabel: 'Select dataType',
              options: snapshot.uploadTypes,
              selected: query.uploadType,
              onChanged: onUploadType,
            ),
            _field(
              label: 'Select status',
              emptyLabel: 'Select status',
              options: snapshot.statuses,
              selected: query.status,
              onChanged: onStatus,
            ),
            RfiFilterClearButton(
              label: 'Clear Filter',
              onPressed: enabled ? onClear : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required String emptyLabel,
    required List<P6Option> options,
    required String selected,
    required ValueChanged<String?> onChanged,
  }) {
    final String? selectedId = selected.isEmpty ? null : selected;
    return RfiFilterField(
      label: label,
      emptyLabel: emptyLabel,
      value: _label(options, selectedId),
      options: <RfiFilterOption>[
        for (final P6Option option in options)
          RfiFilterOption(id: option.value, label: option.label),
      ],
      selectedId: selectedId,
      onClear: selectedId == null ? null : () => onChanged(null),
      onPick: (RfiFilterOption option) => onChanged(option.id),
    );
  }
}

String? _label(List<P6Option> options, String? id) {
  if (id == null) {
    return null;
  }
  for (final P6Option option in options) {
    if (option.value == id) {
      return option.label;
    }
  }
  return id;
}

class _FillScroll extends StatelessWidget {
  const _FillScroll({required this.child, required this.minHeight});

  final Widget child;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: math.max(minHeight, 0)),
        child: child,
      ),
    );
  }
}
