import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/paging/table_page.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/core/widgets/paged_table_column.dart';
import 'package:swr_pmis_mobile/src/core/widgets/table_pagination_footer.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';
import 'package:swr_pmis_mobile/src/features/utility_shifting/domain/utility_shifting_list.dart';
import 'package:swr_pmis_mobile/src/features/utility_shifting/presentation/providers/utility_shifting_provider.dart';
import 'package:swr_pmis_mobile/src/features/utility_shifting/presentation/widgets/utility_shifting_uploads_table.dart';

class UtilityShiftingUploadsListView extends ConsumerStatefulWidget {
  const UtilityShiftingUploadsListView({super.key});

  @override
  ConsumerState<UtilityShiftingUploadsListView> createState() =>
      _UtilityShiftingUploadsListViewState();
}

class _UtilityShiftingUploadsListViewState
    extends ConsumerState<UtilityShiftingUploadsListView> {
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

  Future<void> _retry() {
    _resetPage();
    return ref.read(utilityShiftingUploadsControllerProvider.notifier).load();
  }

  Future<void> _onFileTap(UtilityShiftingUploadRow row) async {
    if (!mounted || row.uploadedFile.trim().isEmpty) {
      return;
    }
    await AppDialog.show(
      context,
      title: 'Download',
      message: 'File download will be available later',
    );
  }

  @override
  Widget build(BuildContext context) {
    final UtilityShiftingUploadsState state = ref.watch(
      utilityShiftingUploadsControllerProvider,
    );
    final bool failed = state.error != null;
    final List<UtilityShiftingUploadRow> loaded = failed
        ? const <UtilityShiftingUploadRow>[]
        : state.rows;
    final List<UtilityShiftingUploadRow> visible = loaded
        .where((UtilityShiftingUploadRow row) => _matches(row, _search.text))
        .toList(growable: false);
    final TablePage<UtilityShiftingUploadRow> tablePage = TablePage.slice(
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          RfiContentLoader(loading: state.loading),
          if (showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                onChanged: (_) => _resetPage(),
                decoration: InputDecoration(
                  hintText: 'Search uploads',
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
                  ? 'No uploaded utility shifting data found.'
                  : 'No matching uploads.',
              onRetry: loaded.isEmpty ? _retry : null,
            )
          : UtilityShiftingUploadsTable(
              rows: tablePage.items,
              onOpenFile: _onFileTap,
            ),
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

  bool _matches(UtilityShiftingUploadRow row, String query) {
    final String needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return true;
    }
    return <String>[
      row.uploadedFile,
      row.status,
      row.remarks,
      row.uploadedBy,
      row.uploadedOn,
    ].any((String part) => part.toLowerCase().contains(needle));
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
