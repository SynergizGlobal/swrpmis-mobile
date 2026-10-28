import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/paging/table_page.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/core/widgets/paged_table_column.dart';
import 'package:swr_pmis_mobile/src/core/widgets/table_pagination_footer.dart';
import 'package:swr_pmis_mobile/src/features/contractors/data/contractor_export_file.dart';
import 'package:swr_pmis_mobile/src/features/contractors/domain/contractor_list.dart';
import 'package:swr_pmis_mobile/src/features/contractors/presentation/pages/add_contractor_form_page.dart';
import 'package:swr_pmis_mobile/src/features/contractors/presentation/providers/contractors_provider.dart';
import 'package:swr_pmis_mobile/src/features/contractors/presentation/widgets/contractors_table.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';

class ContractorsListView extends ConsumerStatefulWidget {
  const ContractorsListView({super.key});

  @override
  ConsumerState<ContractorsListView> createState() =>
      _ContractorsListViewState();
}

class _ContractorsListViewState extends ConsumerState<ContractorsListView> {
  final TextEditingController _search = TextEditingController();
  Timer? _searchDebounce;
  int _pageSize = TablePage.defaultPageSize;
  int _page = 1;
  bool _exporting = false;

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
      ref.read(contractorsControllerProvider.notifier).setSearch(value);
    });
  }

  Future<void> _retry() {
    _resetPage();
    return ref.read(contractorsControllerProvider.notifier).load();
  }

  Future<void> _onAdd() async {
    final Object? saved = await context.push<Object?>(
      AddContractorFormPage.routePath,
    );
    if (!mounted || saved != true) {
      return;
    }
    await _retry();
  }

  Future<void> _onEdit(ContractorRow row) async {
    final Object? saved = await context.push<Object?>(
      AddContractorFormPage.location(contractorId: row.contractorId),
      extra: row,
    );
    if (!mounted || saved != true) {
      return;
    }
    await _retry();
  }

  Rect _shareOrigin(BuildContext origin) {
    final RenderObject? box = origin.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      return box.localToGlobal(Offset.zero) & box.size;
    }
    return Rect.zero;
  }

  Future<void> _onExport(BuildContext origin) async {
    if (_exporting || !mounted) {
      return;
    }
    final ContractorsState current = ref.read(contractorsControllerProvider);
    if (current.loading || current.error != null) {
      return;
    }
    final List<ContractorRow> rows = current.snapshot.rows
        .where((ContractorRow row) => contractorRowMatches(row, current.query))
        .toList(growable: false);
    if (rows.isEmpty) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.info,
        title: 'Export',
        message: 'There are no records to export.',
      );
      return;
    }
    final Rect originRect = _shareOrigin(origin);
    setState(() => _exporting = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) {
        return;
      }
      await shareContractorXlsx(
        rows: rows,
        sharePositionOrigin: originRect,
      );
    } on Object {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Export',
        message: 'Unable to export contractors to Excel.',
      );
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ContractorsState state = ref.watch(contractorsControllerProvider);
    final bool failed = state.error != null;
    final List<ContractorRow> loaded = failed
        ? const <ContractorRow>[]
        : state.snapshot.rows;
    final List<ContractorRow> visible = loaded
        .where((ContractorRow row) => contractorRowMatches(row, state.query))
        .toList(growable: false);
    final TablePage<ContractorRow> tablePage = TablePage.slice(
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
          RfiContentLoader(loading: state.loading || _exporting),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: state.loading || _exporting ? null : _onAdd,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add'),
                      ),
                      OutlinedButton.icon(
                        onPressed: state.loading || failed || _exporting
                            ? null
                            : () => _onExport(context),
                        icon: _exporting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Export'),
                      ),
                    ],
                  ),
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
                      hintText: 'Search',
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
      body: failed
          ? _message(
              message: state.error is DioException
                  ? userFriendlyErrorMessage(state.error as DioException)
                  : state.error.toString(),
              onRetry: _retry,
            )
          : state.loading
          ? const SizedBox.shrink()
          : visible.isEmpty
          ? _message(
              message: state.query.search.trim().isEmpty
                  ? 'No contractors found.'
                  : 'No contractors match your search.',
              onRetry: null,
            )
          : ContractorsTable(rows: tablePage.items, onEdit: _onEdit),
      footer: showFooter
          ? TablePaginationFooter(
              label: tablePage.label,
              total: tablePage.total,
              page: tablePage.page,
              pageCount: tablePage.pageCount,
              pageSize: tablePage.pageSize,
              onPageChanged: (int page) => setState(() => _page = page),
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
