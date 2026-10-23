import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/core/widgets/paged_table_column.dart';
import 'package:swr_pmis_mobile/src/core/widgets/table_pagination_footer.dart';
import 'package:swr_pmis_mobile/src/features/quality_test_register/domain/quality_test_register_list.dart';
import 'package:swr_pmis_mobile/src/features/quality_test_register/presentation/pages/quality_test_register_detail_page.dart';
import 'package:swr_pmis_mobile/src/features/quality_test_register/presentation/providers/quality_test_register_provider.dart';
import 'package:swr_pmis_mobile/src/features/quality_test_register/presentation/widgets/quality_test_register_table.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_filter_option.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_clear_button.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_field.dart';

class QualityTestRegisterListView extends ConsumerStatefulWidget {
  const QualityTestRegisterListView({super.key});

  @override
  ConsumerState<QualityTestRegisterListView> createState() =>
      _QualityTestRegisterListViewState();
}

class _QualityTestRegisterListViewState
    extends ConsumerState<QualityTestRegisterListView> {
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
      ref.read(qualityTestRegisterControllerProvider.notifier).setSearch(value);
    });
  }

  Future<void> _retry() {
    return ref.read(qualityTestRegisterControllerProvider.notifier).load();
  }

  Future<void> _onCreate() async {
    await AppDialog.show(
      context,
      variant: AppDialogVariant.info,
      title: 'Create Test Obligation',
      message: 'Create Test Obligation will be added next.',
    );
  }

  Future<void> _onView(QualityTestObligationRow row) async {
    if (!mounted) {
      return;
    }
    await context.push(QualityTestRegisterDetailPage.locationFor(row.id));
  }

  Future<void> _pickDateRange() async {
    final QualityTestRegisterState state = ref.read(
      qualityTestRegisterControllerProvider,
    );
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(now.year - 10);
    final DateTime lastDate = DateTime(now.year + 2, 12, 31);
    DateTimeRange? initial;
    final DateTime? parsedFrom = _parseApiDate(state.query.dateFrom);
    final DateTime? parsedTo = _parseApiDate(state.query.dateTo);
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
        .read(qualityTestRegisterControllerProvider.notifier)
        .selectDateRange(
          from: format.format(picked.start),
          to: format.format(picked.end),
        );
  }

  void _clearDateRange() {
    ref
        .read(qualityTestRegisterControllerProvider.notifier)
        .selectDateRange(from: '', to: '');
  }

  @override
  Widget build(BuildContext context) {
    final QualityTestRegisterState state = ref.watch(
      qualityTestRegisterControllerProvider,
    );
    final bool failed = state.error != null;
    final List<QualityTestObligationRow> rows = failed
        ? const <QualityTestObligationRow>[]
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _FilterBar(
                  state: state,
                  enabled: !state.loading,
                  onProject: (String? value) {
                    ref
                        .read(qualityTestRegisterControllerProvider.notifier)
                        .selectProject(value ?? '');
                  },
                  onSection: (String? value) {
                    ref
                        .read(qualityTestRegisterControllerProvider.notifier)
                        .selectSection(value ?? '');
                  },
                  onContract: (String? value) {
                    ref
                        .read(qualityTestRegisterControllerProvider.notifier)
                        .selectContract(value ?? '');
                  },
                  onMaterial: (String? value) {
                    ref
                        .read(qualityTestRegisterControllerProvider.notifier)
                        .selectMaterial(value ?? '');
                  },
                  onTestStatus: (String? value) {
                    ref
                        .read(qualityTestRegisterControllerProvider.notifier)
                        .selectTestStatus(value ?? '');
                  },
                  onDateRange: _pickDateRange,
                  onClearDateRange: _clearDateRange,
                  onClear: () {
                    _search.clear();
                    ref
                        .read(qualityTestRegisterControllerProvider.notifier)
                        .clearFilters();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 8),
                // Create is intrinsic-width only — never Expanded / never share a
                // Row with the search field (unbounded Expanded flex crash).
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _onCreate,
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Create'),
                  ),
                ),
                if (showSearch) ...<Widget>[
                  const SizedBox(height: 8),
                  // Full-width search alone (Issues / Material Receipts pattern).
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
      body: failed
          ? _message(
              message: state.error is DioException
                  ? userFriendlyErrorMessage(state.error! as DioException)
                  : state.error.toString(),
              onRetry: _retry,
            )
          : state.loading && rows.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : rows.isEmpty
          ? _message(
              message: 'No test obligations found.',
              onRetry: _retry,
            )
          : QualityTestRegisterTable(rows: rows, onView: _onView),
      footer: showFooter
          ? TablePaginationFooter(
              label: label,
              total: total,
              page: page,
              pageCount: pageCount,
              pageSize: pageSize,
              onPageChanged: (int next) {
                ref
                    .read(qualityTestRegisterControllerProvider.notifier)
                    .setPage(next);
              },
              onPageSizeChanged: (int size) {
                ref
                    .read(qualityTestRegisterControllerProvider.notifier)
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
    required this.onTestStatus,
    required this.onDateRange,
    required this.onClearDateRange,
    required this.onClear,
  });

  final QualityTestRegisterState state;
  final bool enabled;
  final ValueChanged<String?> onProject;
  final ValueChanged<String?> onSection;
  final ValueChanged<String?> onContract;
  final ValueChanged<String?> onMaterial;
  final ValueChanged<String?> onTestStatus;
  final VoidCallback onDateRange;
  final VoidCallback onClearDateRange;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final QualityTestRegisterListQuery query = state.query;
    final QualityTestRegisterSnapshot snapshot = state.snapshot;
    final String? dateLabel = _dateRangeLabel(query.dateFrom, query.dateTo);
    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: RfiFilterGrid(
          children: <Widget>[
            _field(
              label: 'Select Project',
              options: snapshot.projects,
              selected: query.projectId,
              onChanged: onProject,
            ),
            _field(
              label: 'Select Section',
              options: snapshot.sections,
              selected: query.sectionId,
              onChanged: onSection,
            ),
            _field(
              label: 'Select Contract',
              options: snapshot.contracts,
              selected: query.contractId,
              onChanged: onContract,
            ),
            _field(
              label: 'Select Material',
              options: snapshot.materials,
              selected: query.materialCode,
              onChanged: onMaterial,
            ),
            _field(
              label: 'All',
              emptyLabel: 'All',
              options: qualityTestStatusOptions,
              selected: query.testStatus,
              onChanged: onTestStatus,
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
    required List<QualityTestOption> options,
    required String selected,
    required ValueChanged<String?> onChanged,
    String? emptyLabel,
  }) {
    final String? selectedId = selected.isEmpty ? null : selected;
    return RfiFilterField(
      label: label,
      emptyLabel: emptyLabel ?? label,
      showLabel: false,
      value: _optionLabel(options, selectedId),
      options: <RfiFilterOption>[
        for (final QualityTestOption option in options)
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
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final BorderRadius radius = BorderRadius.circular(AppTheme.cardRadius);
    final bool hasValue = value != null && value!.trim().isNotEmpty;
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      color: dark ? AppTheme.cardDark : AppTheme.surfaceLight,
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
                  value ?? 'dd/mm/yyyy',
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
  final DateFormat format = DateFormat('dd/MM/yyyy');
  return '${format.format(start)} - ${format.format(end)}';
}

DateTime? _parseApiDate(String value) {
  final String text = value.trim();
  if (text.isEmpty) {
    return null;
  }
  return DateTime.tryParse(text);
}

String? _optionLabel(List<QualityTestOption> options, String? id) {
  if (id == null) {
    return null;
  }
  for (final QualityTestOption option in options) {
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
