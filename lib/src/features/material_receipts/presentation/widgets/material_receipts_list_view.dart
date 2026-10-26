import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:swr_pmis_mobile/src/app/config/app_config_controller.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_filter_section.dart';
import 'package:swr_pmis_mobile/src/core/widgets/paged_table_column.dart';
import 'package:swr_pmis_mobile/src/core/widgets/table_pagination_footer.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/data/datasources/material_receipt_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/data/material_receipt_file_actions.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/data/material_receipt_pdf_builder.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/domain/material_receipt_list.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/presentation/pages/material_receipt_form_page.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/presentation/providers/material_receipts_provider.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/presentation/widgets/material_receipts_table.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_filter_option.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_clear_button.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_field.dart';

class MaterialReceiptsListView extends ConsumerStatefulWidget {
  const MaterialReceiptsListView({super.key});

  @override
  ConsumerState<MaterialReceiptsListView> createState() =>
      _MaterialReceiptsListViewState();
}

class _MaterialReceiptsListViewState
    extends ConsumerState<MaterialReceiptsListView> {
  final TextEditingController _search = TextEditingController();
  Timer? _searchDebounce;
  String? _busyReceiptId;

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
      ref.read(materialReceiptsControllerProvider.notifier).setSearch(value);
    });
  }

  Future<void> _retry() {
    return ref.read(materialReceiptsControllerProvider.notifier).load();
  }

  Future<void> _onAdd() async {
    final Object? saved = await context.push<Object?>(
      MaterialReceiptFormPage.locationAdd(),
    );
    if (saved == true && mounted) {
      await ref.read(materialReceiptsControllerProvider.notifier).load();
    }
  }

  Future<void> _onOpen(MaterialReceiptRow row) async {
    if (!mounted) {
      return;
    }
    final Object? saved = await context.push<Object?>(
      MaterialReceiptFormPage.locationFor(row.receiptId),
    );
    if (saved == true && mounted) {
      await ref.read(materialReceiptsControllerProvider.notifier).load();
    }
  }

  Future<void> _onDownload(MaterialReceiptRow row) async {
    if (_busyReceiptId != null || !mounted) {
      return;
    }
    final Rect origin = _shareOrigin(context);
    final String baseUrl = ref.read(appConfigProvider).baseUrl;
    final ValueNotifier<String> progress = ValueNotifier<String>(
      'Preparing PDF…',
    );
    setState(() => _busyReceiptId = row.receiptId);
    _showProgressDialog(progress);
    try {
      final ({Uint8List bytes, String fileName}) file =
          await buildMergedMaterialReceiptPdf(
            source: ref.read(materialReceiptRemoteDataSourceProvider),
            receiptId: row.receiptId,
            baseUrl: baseUrl,
            onProgress: (String message) {
              progress.value = message;
            },
          );
      if (!mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      await presentMaterialReceiptPdf(
        bytes: file.bytes,
        fileName: file.fileName,
        sharePositionOrigin: origin,
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Download',
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : error is StateError
            ? error.message
            : 'Unable to prepare the material receipt PDF.',
      );
    } finally {
      progress.dispose();
      if (mounted) {
        setState(() => _busyReceiptId = null);
      }
    }
  }

  void _showProgressDialog(ValueNotifier<String> progress) {
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            icon: Icon(
              AppDialog.iconFor(AppDialogVariant.info),
              color: Theme.of(dialogContext).colorScheme.primary,
            ),
            title: const Text('Download PDF'),
            content: ValueListenableBuilder<String>(
              valueListenable: progress,
              builder: (BuildContext context, String message, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    const SizedBox(height: 16),
                    Text(message, textAlign: TextAlign.center),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickDateRange() async {
    final MaterialReceiptsState state = ref.read(
      materialReceiptsControllerProvider,
    );
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(now.year - 10);
    final DateTime lastDate = DateTime(now.year + 2, 12, 31);
    DateTimeRange? initial;
    final DateTime? parsedFrom = _parseApiDate(state.query.deliveryDateFrom);
    final DateTime? parsedTo = _parseApiDate(state.query.deliveryDateTo);
    if (parsedFrom != null && parsedTo != null) {
      initial = DateTimeRange(start: parsedFrom, end: parsedTo);
    }
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: initial,
    );
    if (picked == null || !mounted) {
      return;
    }
    final DateFormat format = DateFormat('yyyy-MM-dd');
    ref
        .read(materialReceiptsControllerProvider.notifier)
        .selectDateRange(
          from: format.format(picked.start),
          to: format.format(picked.end),
        );
  }

  void _clearDateRange() {
    ref
        .read(materialReceiptsControllerProvider.notifier)
        .selectDateRange(from: '', to: '');
  }

  @override
  Widget build(BuildContext context) {
    final MaterialReceiptsState state = ref.watch(
      materialReceiptsControllerProvider,
    );
    final bool failed = state.error != null;
    final List<MaterialReceiptRow> rows = failed
        ? const <MaterialReceiptRow>[]
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
    final bool busy = _busyReceiptId != null;

    return PagedTableColumn(
      header: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          RfiContentLoader(loading: state.loading || busy),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: busy ? null : _onAdd,
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Add'),
                  ),
                ),
                const SizedBox(height: 12),
                AppFilterSection(
                  activeCount: AppFilterSection.countActive(<String?>[
                    state.query.projectId,
                    state.query.sectionId,
                    state.query.contractId,
                    state.query.materialId,
                    state.query.deliveryDateFrom.isNotEmpty ||
                            state.query.deliveryDateTo.isNotEmpty
                        ? 'range'
                        : '',
                  ]),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _FilterBar(
                        state: state,
                        enabled: !state.loading && !busy,
                        onProject: (String? value) {
                          ref
                              .read(materialReceiptsControllerProvider.notifier)
                              .selectProject(value ?? '');
                        },
                        onSection: (String? value) {
                          ref
                              .read(materialReceiptsControllerProvider.notifier)
                              .selectSection(value ?? '');
                        },
                        onContract: (String? value) {
                          ref
                              .read(materialReceiptsControllerProvider.notifier)
                              .selectContract(value ?? '');
                        },
                        onMaterial: (String? value) {
                          ref
                              .read(materialReceiptsControllerProvider.notifier)
                              .selectMaterial(value ?? '');
                        },
                        onDateRange: _pickDateRange,
                        onClearDateRange: _clearDateRange,
                        onClear: () {
                          ref
                              .read(materialReceiptsControllerProvider.notifier)
                              .clearFilters();
                        },
                      ),
                      if (showSearch) ...<Widget>[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _search,
                          textInputAction: TextInputAction.search,
                          onChanged: (String value) {
                            _onSearchChanged(value);
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            hintText: 'Search...',
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
          : state.loading && rows.isEmpty
          ? const SizedBox.shrink()
          : rows.isEmpty
          ? _message(
              message: 'No material receipts found.',
              onRetry: _retry,
            )
          : MaterialReceiptsTable(
              rows: rows,
              busyReceiptId: _busyReceiptId,
              onOpen: _onOpen,
              onDownload: _onDownload,
              onEdit: _onOpen,
            ),
      footer: showFooter
          ? TablePaginationFooter(
              label: label,
              total: total,
              page: page,
              pageCount: pageCount,
              pageSize: pageSize,
              onPageChanged: (int next) {
                ref
                    .read(materialReceiptsControllerProvider.notifier)
                    .setPage(next);
              },
              onPageSizeChanged: (int size) {
                ref
                    .read(materialReceiptsControllerProvider.notifier)
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
    required this.onSection,
    required this.onContract,
    required this.onMaterial,
    required this.onDateRange,
    required this.onClearDateRange,
    required this.onClear,
  });

  final MaterialReceiptsState state;
  final bool enabled;
  final ValueChanged<String?> onProject;
  final ValueChanged<String?> onSection;
  final ValueChanged<String?> onContract;
  final ValueChanged<String?> onMaterial;
  final VoidCallback onDateRange;
  final VoidCallback onClearDateRange;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final MaterialReceiptListQuery query = state.query;
    final MaterialReceiptListSnapshot snapshot = state.snapshot;
    final String? dateLabel = _dateRangeLabel(
      query.deliveryDateFrom,
      query.deliveryDateTo,
    );
    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: RfiFilterGrid(
          children: <Widget>[
            _field(
              label: 'Project',
              options: snapshot.projects,
              selected: query.projectId,
              onChanged: onProject,
            ),
            _field(
              label: 'Section',
              options: snapshot.sections,
              selected: query.sectionId,
              onChanged: onSection,
            ),
            _field(
              label: 'Contract',
              options: snapshot.contracts,
              selected: query.contractId,
              onChanged: onContract,
            ),
            _field(
              label: 'Material',
              options: snapshot.materials,
              selected: query.materialId,
              onChanged: onMaterial,
            ),
            _DateRangeField(
              value: dateLabel,
              onTap: onDateRange,
              onClear: dateLabel == null ? null : onClearDateRange,
            ),
            RfiFilterClearButton(
              label: 'Reset',
              onPressed: enabled ? onClear : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required List<MaterialReceiptOption> options,
    required String selected,
    required ValueChanged<String?> onChanged,
  }) {
    final String? selectedId = selected.isEmpty ? null : selected;
    return RfiFilterField(
      label: label,
      value: _optionLabel(options, selectedId),
      options: <RfiFilterOption>[
        for (final MaterialReceiptOption option in options)
          RfiFilterOption(id: option.value, label: option.label),
      ],
      selectedId: selectedId,
      onClear: selectedId == null ? null : () => onChanged(null),
      onPick: (RfiFilterOption option) => onChanged(option.id),
    );
  }
}

class _DateRangeField extends StatelessWidget {
  const _DateRangeField({
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  final String? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final BorderRadius radius = BorderRadius.circular(AppTheme.cardRadius);
    final bool hasValue = value != null && value!.trim().isNotEmpty;
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      color: palette.fieldFill,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 7, 4, 7),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  value ?? 'dd-mm-yyyy - dd-mm-yyyy',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.2,
                    color: hasValue ? colors.onSurface : palette.mutedText,
                  ),
                ),
              ),
              if (onClear != null)
                IconButton(
                  tooltip: 'Clear date range',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 32,
                  ),
                  onPressed: onClear,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: palette.mutedText,
                  ),
                ),
              Icon(
                Icons.calendar_month_rounded,
                size: 18,
                color: palette.mutedText,
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}

String? _dateRangeLabel(String from, String to) {
  final DateTime? start = _parseApiDate(from);
  final DateTime? end = _parseApiDate(to);
  if (start == null || end == null) {
    return null;
  }
  final DateFormat format = DateFormat('dd-MM-yyyy');
  return '${format.format(start)} - ${format.format(end)}';
}

DateTime? _parseApiDate(String value) {
  final String text = value.trim();
  if (text.isEmpty) {
    return null;
  }
  return DateTime.tryParse(text);
}

String? _optionLabel(List<MaterialReceiptOption> options, String? id) {
  if (id == null) {
    return null;
  }
  for (final MaterialReceiptOption option in options) {
    if (option.value == id) {
      return option.label;
    }
  }
  return id;
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
