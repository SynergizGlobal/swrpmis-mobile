import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_filter_section.dart';
import 'package:swr_pmis_mobile/src/core/widgets/paged_table_column.dart';
import 'package:swr_pmis_mobile/src/core/widgets/table_pagination_footer.dart';
import 'package:swr_pmis_mobile/src/features/contracts/domain/contract_list.dart';
import 'package:swr_pmis_mobile/src/features/contracts/presentation/pages/add_contract_form_page.dart';
import 'package:swr_pmis_mobile/src/features/contracts/presentation/providers/contracts_provider.dart';
import 'package:swr_pmis_mobile/src/features/contracts/presentation/widgets/contracts_table.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_filter_option.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_clear_button.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_field.dart';

class ContractsListView extends ConsumerStatefulWidget {
  const ContractsListView({super.key});

  @override
  ConsumerState<ContractsListView> createState() => _ContractsListViewState();
}

class _ContractsListViewState extends ConsumerState<ContractsListView> {
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
      ref.read(contractsControllerProvider.notifier).setSearch(value);
    });
  }

  Future<void> _retry() {
    return ref.read(contractsControllerProvider.notifier).load();
  }

  Future<void> _onAdd() async {
    final Object? saved = await context.push<Object?>(
      AddContractFormPage.routePath,
    );
    if (!mounted || saved != true) {
      return;
    }
    await _retry();
  }

  @override
  Widget build(BuildContext context) {
    final ContractsState state = ref.watch(contractsControllerProvider);
    final bool failed = state.error != null;
    final List<ContractRow> rows = failed
        ? const <ContractRow>[]
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
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Contracts / Tenders',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: state.loading ? null : _onAdd,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: AppFilterSection(
              activeCount: AppFilterSection.countActive(<String?>[
                state.query.projectIdFk,
                state.query.designation,
                state.query.dyHod,
                state.query.contractorIdFk,
                state.query.contractStatus,
                state.query.status,
              ]),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _FilterBar(
                    state: state,
                    enabled: !state.loading,
                    onProject: (String? value) {
                      ref
                          .read(contractsControllerProvider.notifier)
                          .selectProject(value ?? '');
                    },
                    onHod: (String? value) {
                      ref
                          .read(contractsControllerProvider.notifier)
                          .selectHod(value ?? '');
                    },
                    onDyHod: (String? value) {
                      ref
                          .read(contractsControllerProvider.notifier)
                          .selectDyHod(value ?? '');
                    },
                    onContractor: (String? value) {
                      ref
                          .read(contractsControllerProvider.notifier)
                          .selectContractor(value ?? '');
                    },
                    onContractStatus: (String? value) {
                      ref
                          .read(contractsControllerProvider.notifier)
                          .selectContractStatus(value ?? '');
                    },
                    onWorkStatus: (String? value) {
                      ref
                          .read(contractsControllerProvider.notifier)
                          .selectWorkStatus(value ?? '');
                    },
                    onClear: () {
                      ref
                          .read(contractsControllerProvider.notifier)
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
                        hintText: 'Search contracts...',
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
          ? _message(message: 'No contracts found.', onRetry: _retry)
          : ContractsTable(rows: rows),
      footer: showFooter
          ? TablePaginationFooter(
              label: label,
              total: total,
              page: page,
              pageCount: pageCount,
              pageSize: pageSize,
              onPageChanged: (int next) {
                ref.read(contractsControllerProvider.notifier).setPage(next);
              },
              onPageSizeChanged: (int size) {
                ref
                    .read(contractsControllerProvider.notifier)
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
    required this.onProject,
    required this.onHod,
    required this.onDyHod,
    required this.onContractor,
    required this.onContractStatus,
    required this.onWorkStatus,
    required this.onClear,
  });

  final ContractsState state;
  final bool enabled;
  final ValueChanged<String?> onProject;
  final ValueChanged<String?> onHod;
  final ValueChanged<String?> onDyHod;
  final ValueChanged<String?> onContractor;
  final ValueChanged<String?> onContractStatus;
  final ValueChanged<String?> onWorkStatus;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final ContractListQuery query = state.query;
    final ContractListSnapshot snapshot = state.snapshot;
    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: RfiFilterGrid(
          children: <Widget>[
            _field(
              label: 'Project',
              emptyLabel: 'Select Project',
              options: snapshot.projects,
              selected: query.projectIdFk,
              onChanged: onProject,
            ),
            _field(
              label: 'HOD',
              emptyLabel: 'Select HOD',
              options: snapshot.hods,
              selected: query.designation,
              onChanged: onHod,
            ),
            _field(
              label: 'Dy HOD',
              emptyLabel: 'Select Dy HOD',
              options: snapshot.dyHods,
              selected: query.dyHod,
              onChanged: onDyHod,
            ),
            _field(
              label: 'Contractor',
              emptyLabel: 'Select Contractor',
              options: snapshot.contractors,
              selected: query.contractorIdFk,
              onChanged: onContractor,
            ),
            _field(
              label: 'Contract Status',
              emptyLabel: 'Select Contract Status',
              options: snapshot.contractStatuses,
              selected: query.contractStatus,
              onChanged: onContractStatus,
            ),
            _field(
              label: 'Status of Work',
              emptyLabel: 'Select Status of Work',
              options: snapshot.workStatuses,
              selected: query.status,
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
    required List<ContractOption> options,
    required String selected,
    required ValueChanged<String?> onChanged,
  }) {
    final String? selectedId = selected.isEmpty ? null : selected;
    return RfiFilterField(
      label: label,
      emptyLabel: emptyLabel,
      value: _label(options, selectedId),
      options: <RfiFilterOption>[
        for (final ContractOption option in options)
          RfiFilterOption(id: option.value, label: option.label),
      ],
      selectedId: selectedId,
      onClear: selectedId == null ? null : () => onChanged(null),
      onPick: (RfiFilterOption option) => onChanged(option.id),
    );
  }
}

String? _label(List<ContractOption> options, String? id) {
  if (id == null) {
    return null;
  }
  for (final ContractOption option in options) {
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
