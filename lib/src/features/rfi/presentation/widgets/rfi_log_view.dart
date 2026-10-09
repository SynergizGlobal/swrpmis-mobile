import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/datasources/rfi_log_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/rfi_log_print.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_log_row.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/providers/rfi_log_provider.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_log_filter_bar.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_log_preview_dialog.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_log_table.dart';

class RfiLogView extends ConsumerStatefulWidget {
  const RfiLogView({super.key, this.showTitle = true});

  final bool showTitle;

  @override
  ConsumerState<RfiLogView> createState() => _RfiLogViewState();
}

class _RfiLogViewState extends ConsumerState<RfiLogView> {
  final TextEditingController _search = TextEditingController();
  RfiLogRow? _downloadingRow;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() {
    return ref.read(rfiLogControllerProvider.notifier).load();
  }

  Future<void> _preview(RfiLogRow row) async {
    final int? id = row.id;
    if (id == null) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Preview unavailable',
        message: 'This RFI does not have a report id.',
      );
      return;
    }
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      useSafeArea: false,
      builder: (BuildContext context) => RfiLogPreviewDialog(id: id),
    );
  }

  Future<void> _download(RfiLogRow row) async {
    if (_downloadingRow != null) {
      return;
    }
    if (!row.canDownload) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Download unavailable',
        message: 'The download is not available yet.',
      );
      return;
    }
    setState(() => _downloadingRow = row);
    try {
      final bytes = await ref
          .read(rfiLogRemoteDataSourceProvider)
          .downloadPdf(rfiId: row.rfiId, txnId: row.txnId);
      if (!mounted) {
        return;
      }
      await shareRfiLogFile(
        bytes: bytes,
        fileName: '${row.rfiId}.pdf',
        sharePositionOrigin: _shareOrigin(context),
      );
    } on Object {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Download unavailable',
        message: 'The download is not available yet.',
      );
    } finally {
      if (mounted) {
        setState(() => _downloadingRow = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final RfiLogState log = ref.watch(rfiLogControllerProvider);
    final RfiLogController controller = ref.read(
      rfiLogControllerProvider.notifier,
    );
    final List<RfiLogRow> visible = log.rows
        .where((RfiLogRow row) => _matches(row, _search.text))
        .toList(growable: false);
    final bool hasError = log.error != null;
    final bool showSearch = !hasError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RfiContentLoader(loading: log.loading),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (widget.showTitle)
                Text(
                  'RFI Log',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              if (showSearch) ...<Widget>[
                if (widget.showTitle) const SizedBox(height: 2),
                Text(
                  _countLabel(visible.length),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppPalette.of(context).mutedText,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              RfiLogFilterBar(
                filter: log.filter,
                catalog: log.catalog,
                enabled: !log.loading && _downloadingRow == null,
                onClear: controller.clearFilters,
                onCategory: controller.selectCategory,
                onProject: controller.selectProject,
                onContract: controller.selectContract,
                onStructureType: controller.selectStructureType,
                onStructure: controller.selectStructure,
                onItem: controller.selectItem,
                onMaterial: controller.selectMaterial,
                onQuality: controller.selectQuality,
              ),
              if (showSearch) ...<Widget>[
                const SizedBox(height: 12),
                TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search RFI...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear',
                            onPressed: () {
                              _search.clear();
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
        Expanded(child: _body(log, visible)),
      ],
    );
  }

  Widget _body(RfiLogState log, List<RfiLogRow> visible) {
    if (log.error != null && log.rows.isEmpty) {
      return _scrollMessage(
        message: log.error is DioException
            ? userFriendlyErrorMessage(log.error! as DioException)
            : log.error.toString(),
        onRetry: _refresh,
      );
    }
    if (log.loading && log.rows.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: const _FillScroll(minHeight: 240, child: SizedBox.shrink()),
      );
    }
    if (log.error != null) {
      return _scrollMessage(
        message: log.error is DioException
            ? userFriendlyErrorMessage(log.error! as DioException)
            : log.error.toString(),
        onRetry: _refresh,
      );
    }
    if (visible.isEmpty) {
      return _scrollMessage(
        message: log.rows.isEmpty ? 'No RFI logs found.' : 'No matching RFIs.',
        onRetry: log.rows.isEmpty ? _refresh : null,
      );
    }
    return RfiLogTable(
      rows: visible,
      onRefresh: _refresh,
      onPreview: _preview,
      onDownload: _download,
      downloadingRow: _downloadingRow,
    );
  }

  Widget _scrollMessage({
    required String message,
    required VoidCallback? onRetry,
  }) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double minHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 0;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: _FillScroll(
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
          ),
        );
      },
    );
  }
}

bool _matches(RfiLogRow row, String query) {
  final String needle = query.trim().toLowerCase();
  if (needle.isEmpty) {
    return true;
  }
  final List<String> parts = <String>[
    row.rfiCategory,
    row.rfiId,
    row.dateRaised,
    row.structure,
    row.rfiDescription,
    row.nameOfRepresentative,
    row.person,
    row.conRespondedDate,
    row.enggRespondedDate,
    row.status,
    row.statusLabel,
    row.notes,
    row.contract,
    row.project,
  ];
  return parts.any((String part) => part.toLowerCase().contains(needle));
}

String _countLabel(int count) {
  if (count == 1) {
    return '1 record total';
  }
  return '$count records total';
}

Rect _shareOrigin(BuildContext context) {
  final RenderObject? object = context.findRenderObject();
  if (object is RenderBox && object.hasSize) {
    return object.localToGlobal(Offset.zero) & object.size;
  }
  final Size size = MediaQuery.sizeOf(context);
  return Rect.fromCenter(
    center: Offset(size.width / 2, size.height / 2),
    width: 2,
    height: 2,
  );
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
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(height: math.max(height, minHeight), child: child),
        );
      },
    );
  }
}
