import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_filter_section.dart';
import 'package:swr_pmis_mobile/src/core/widgets/paged_table_column.dart';
import 'package:swr_pmis_mobile/src/core/widgets/table_pagination_footer.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_filter_option.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_clear_button.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_field.dart';
import 'package:swr_pmis_mobile/src/features/structure_form/domain/structure_form_list.dart';
import 'package:swr_pmis_mobile/src/features/structure_form/presentation/pages/update_structure_form_page.dart';
import 'package:swr_pmis_mobile/src/features/structure_form/presentation/providers/structure_form_list_provider.dart';
import 'package:swr_pmis_mobile/src/features/structure_form/presentation/widgets/structure_form_table.dart';

class StructureFormListView extends ConsumerStatefulWidget {
  const StructureFormListView({super.key});

  @override
  ConsumerState<StructureFormListView> createState() =>
      _StructureFormListViewState();
}

class _StructureFormListViewState extends ConsumerState<StructureFormListView> {
  final TextEditingController _search = TextEditingController();
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) {
        return;
      }
      ref.read(structureFormListControllerProvider.notifier).setSearch(value);
    });
  }

  Future<void> _retry() {
    return ref.read(structureFormListControllerProvider.notifier).load();
  }

  Future<void> _onEdit(StructureFormRow row) async {
    final String id = row.structureId.trim();
    if (id.isEmpty) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.warning,
        title: 'Update Structure',
        message: 'This row has no structure id to edit.',
      );
      return;
    }
    final Object? saved = await context.push<Object?>(
      UpdateStructureFormPage.location(structureId: id),
    );
    if (!mounted || saved != true) {
      return;
    }
    await _retry();
  }

  @override
  Widget build(BuildContext context) {
    final StructureFormListState state = ref.watch(
      structureFormListControllerProvider,
    );
    final bool failed = state.error != null;
    final List<StructureFormRow> rows = failed
        ? const <StructureFormRow>[]
        : state.snapshot.rows;
    final int total = failed ? 0 : state.snapshot.total;
    final int pageSize = state.query.pageSize < 1 ? 10 : state.query.pageSize;
    final int pageCount = total == 0 ? 1 : (total / pageSize).ceil();
    int page = state.query.page < 1 ? 1 : state.query.page;
    if (page > pageCount) {
      page = pageCount;
    }
    final int start = total == 0 ? 0 : (page - 1) * pageSize;
    final int end = total == 0 ? 0 : math.min(start + rows.length, total);
    final String label = total == 0
        ? 'Showing 0 to 0 of 0 entries'
        : 'Showing ${start + 1} to $end of $total entries';
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
                state.query.contractIdFk,
                state.query.structureTypeFk,
                state.query.workStatusFk,
              ]),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _FilterBar(
                    state: state,
                    enabled: !state.loading,
                    onContract: (String? value) {
                      ref
                          .read(structureFormListControllerProvider.notifier)
                          .selectContract(value ?? '');
                    },
                    onStructureType: (String? value) {
                      ref
                          .read(structureFormListControllerProvider.notifier)
                          .selectStructureType(value ?? '');
                    },
                    onWorkStatus: (String? value) {
                      ref
                          .read(structureFormListControllerProvider.notifier)
                          .selectWorkStatus(value ?? '');
                    },
                    onClear: () {
                      ref
                          .read(structureFormListControllerProvider.notifier)
                          .clearFilters();
                    },
                  ),
                  if (showSearch) ...<Widget>[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _search,
                      textInputAction: TextInputAction.search,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search structures...',
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
              message: 'No structures found.',
              onRetry: _retry,
            )
          : StructureFormTable(rows: rows, onEdit: _onEdit),
      footer: showFooter
          ? TablePaginationFooter(
              label: label,
              total: total,
              page: page,
              pageCount: pageCount,
              pageSize: pageSize,
              onPageChanged: (int next) {
                ref
                    .read(structureFormListControllerProvider.notifier)
                    .setPage(next);
              },
              onPageSizeChanged: (int size) {
                ref
                    .read(structureFormListControllerProvider.notifier)
                    .setPageSize(size);
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
    required this.onStructureType,
    required this.onWorkStatus,
    required this.onClear,
  });

  final StructureFormListState state;
  final bool enabled;
  final ValueChanged<String?> onContract;
  final ValueChanged<String?> onStructureType;
  final ValueChanged<String?> onWorkStatus;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final StructureFormListQuery query = state.query;
    final StructureFormListSnapshot snapshot = state.snapshot;
    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: RfiFilterGrid(
          children: <Widget>[
            _field(
              label: 'Contract',
              emptyLabel: 'Select Contract',
              options: snapshot.contracts,
              selected: query.contractIdFk,
              onChanged: onContract,
            ),
            _field(
              label: 'Structure Type',
              emptyLabel: 'Select Structure Type',
              options: snapshot.structureTypes,
              selected: query.structureTypeFk,
              onChanged: onStructureType,
            ),
            _field(
              label: 'Work Status',
              emptyLabel: 'Select Work Status',
              options: snapshot.workStatuses,
              selected: query.workStatusFk,
              onChanged: onWorkStatus,
            ),
            RfiFilterClearButton(
              label: 'Clear Filters',
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
    required List<StructureFormOption> options,
    required String selected,
    required ValueChanged<String?> onChanged,
  }) {
    final String? selectedId = selected.isEmpty ? null : selected;
    return RfiFilterField(
      label: label,
      emptyLabel: emptyLabel,
      value: _label(options, selectedId),
      options: <RfiFilterOption>[
        for (final StructureFormOption option in options)
          RfiFilterOption(id: option.value, label: option.label),
      ],
      selectedId: selectedId,
      onClear: selectedId == null ? null : () => onChanged(null),
      onPick: (RfiFilterOption option) => onChanged(option.id),
    );
  }
}

String? _label(List<StructureFormOption> options, String? id) {
  if (id == null) {
    return null;
  }
  for (final StructureFormOption option in options) {
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
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : minHeight;
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(
            context,
          ).copyWith(overscroll: false, physics: const ClampingScrollPhysics()),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: SizedBox(height: math.max(height, minHeight), child: child),
          ),
        );
      },
    );
  }
}
