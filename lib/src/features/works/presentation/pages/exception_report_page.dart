import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/paging/table_page.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_filter_section.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_fullscreen_loader.dart';
import 'package:swr_pmis_mobile/src/core/widgets/table_pagination_footer.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/entities/exception_report.dart';
import 'package:swr_pmis_mobile/src/features/works/presentation/pages/exception_report_detail_page.dart';
import 'package:swr_pmis_mobile/src/features/works/presentation/pages/project_overview_page.dart';
import 'package:swr_pmis_mobile/src/features/works/presentation/providers/works_providers.dart';

class ExceptionReportPage extends ConsumerStatefulWidget {
  const ExceptionReportPage({
    super.key,
    required this.projectId,
    required this.fallbackName,
    this.embedded = false,
  });

  static const String routeName = 'works-exception-report';
  static const String routePath = '/works/exception-report/:projectId';

  final String projectId;
  final String fallbackName;

  /// When true, renders list/content only (no Scaffold/AppBar) for hub embedding.
  final bool embedded;

  @override
  ConsumerState<ExceptionReportPage> createState() =>
      _ExceptionReportPageState();
}

class _ExceptionReportPageState extends ConsumerState<ExceptionReportPage> {
  ExceptionReportFilterState _filters = ExceptionReportFilterState.cleared;
  final TextEditingController _searchController = TextEditingController();
  int _page = 1;
  int _pageSize = TablePage.defaultPageSize;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.goNamed(
      ProjectOverviewPage.routeName,
      pathParameters: <String, String>{'projectId': widget.projectId},
      queryParameters: <String, String>{
        if (widget.fallbackName.trim().isNotEmpty) 'name': widget.fallbackName,
      },
    );
  }

  void _resetFilters() {
    setState(() {
      _filters = ExceptionReportFilterState.cleared;
      _searchController.clear();
      _page = 1;
    });
  }

  void _applyFilters(ExceptionReportFilterState next) {
    setState(() {
      _filters = next;
      _page = 1;
    });
  }

  void _openDetail(ExceptionReportStructure row) {
    context.pushNamed(
      ExceptionReportDetailPage.routeName,
      pathParameters: <String, String>{
        'projectId': widget.projectId,
        'structureId': '${row.id}',
      },
      queryParameters: <String, String>{
        if (widget.fallbackName.trim().isNotEmpty) 'name': widget.fallbackName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ExceptionReportData> async = ref.watch(
      exceptionReportProvider(widget.projectId),
    );

    final Widget body = async.when(
      loading: () => const AppFullscreenLoader(),
      error: (Object error, StackTrace _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                error is DioException
                    ? userFriendlyErrorMessage(error)
                    : error.toString(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => ref.invalidate(
                  exceptionReportProvider(widget.projectId),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (ExceptionReportData data) => _content(context, data),
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => _goBack(context)),
        title: const Text('Exception Report'),
      ),
      body: body,
    );
  }

  Widget _content(BuildContext context, ExceptionReportData data) {
    final List<ExceptionReportStructure> filtered =
        ExceptionReportFilters.apply(data.structures, _filters);
    final TablePage<ExceptionReportStructure> page = TablePage.slice(
      filtered,
      page: _page,
      pageSize: _pageSize,
    );
    if (_page != page.page) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() => _page = page.page);
      });
    }

    return Column(
      children: <Widget>[
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(exceptionReportProvider(widget.projectId));
              await ref.read(
                exceptionReportProvider(widget.projectId).future,
              );
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              children: <Widget>[
                Text(
                  'STRUCTURE-WISE EXCEPTION REPORT',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Project: ${widget.projectId}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                _SummaryCards(summary: data.summary),
                const SizedBox(height: 12),
                AppFilterSection(
                  activeCount: _filters.activeCount,
                  initiallyExpanded: true,
                  child: _FiltersPanel(
                    structures: data.structures,
                    filters: _filters,
                    searchController: _searchController,
                    onChanged: _applyFilters,
                    onReset: _resetFilters,
                  ),
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        data.structures.isEmpty
                            ? 'No structures in exception report.'
                            : 'No structures match the selected filters.',
                      ),
                    ),
                  )
                else
                  _StructuresTable(
                    page: page,
                    onView: _openDetail,
                  ),
              ],
            ),
          ),
        ),
        TablePaginationFooter(
          label: page.label,
          total: page.total,
          page: page.page,
          pageCount: page.pageCount,
          pageSize: page.pageSize,
          onPageChanged: (int value) => setState(() => _page = value),
          onPageSizeChanged: (int value) => setState(() {
            _pageSize = value;
            _page = 1;
          }),
        ),
      ],
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.summary});

  final ExceptionReportSummary summary;

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool wide = constraints.maxWidth >= 720;
        final List<_SummarySpec> specs = <_SummarySpec>[
          _SummarySpec(
            label: 'Structures Monitored',
            value: summary.structuresMonitored,
            icon: Icons.account_balance_rounded,
            tint: AppTheme.softMetricFill(
              brightness,
              lightFill: const Color(0xFFDBEAFE),
              accent: const Color(0xFF1D4ED8),
              darkAlpha: 0.18,
            ),
            accent: AppTheme.softMetricForeground(
              brightness,
              lightForeground: const Color(0xFF1D4ED8),
              darkForeground: const Color(0xFF93C5FD),
            ),
          ),
          _SummarySpec(
            label: 'Critical Exceptions',
            value: summary.criticalExceptions,
            icon: Icons.error_outline_rounded,
            tint: AppTheme.softMetricFill(
              brightness,
              lightFill: const Color(0xFFFEE2E2),
              accent: const Color(0xFFDC2626),
              darkAlpha: 0.18,
            ),
            accent: AppTheme.softMetricForeground(
              brightness,
              lightForeground: const Color(0xFFDC2626),
              darkForeground: const Color(0xFFFCA5A5),
            ),
          ),
          _SummarySpec(
            label: 'General Drawings Pending',
            value: summary.generalDrawingsPending,
            icon: Icons.description_outlined,
            tint: AppTheme.softMetricFill(
              brightness,
              lightFill: const Color(0xFFCFFAFE),
              accent: const Color(0xFF0891B2),
              darkAlpha: 0.18,
            ),
            accent: AppTheme.softMetricForeground(
              brightness,
              lightForeground: const Color(0xFF0891B2),
              darkForeground: const Color(0xFF67E8F9),
            ),
          ),
          _SummarySpec(
            label: 'Detailed Drawings Pending',
            value: summary.detailedDrawingsPending,
            icon: Icons.article_outlined,
            tint: AppTheme.softMetricFill(
              brightness,
              lightFill: const Color(0xFFEDE9FE),
              accent: const Color(0xFF7C3AED),
              darkAlpha: 0.18,
            ),
            accent: AppTheme.softMetricForeground(
              brightness,
              lightForeground: const Color(0xFF7C3AED),
              darkForeground: const Color(0xFFC4B5FD),
            ),
          ),
          _SummarySpec(
            label: 'Utility Shifting Impacted',
            value: summary.utilityShiftingImpacted,
            icon: Icons.electrical_services_rounded,
            tint: AppTheme.softMetricFill(
              brightness,
              lightFill: const Color(0xFFF3E8FF),
              accent: const Color(0xFF9333EA),
              darkAlpha: 0.18,
            ),
            accent: AppTheme.softMetricForeground(
              brightness,
              lightForeground: const Color(0xFF9333EA),
              darkForeground: const Color(0xFFD8B4FE),
            ),
          ),
        ];

        if (wide) {
          return Row(
            children: <Widget>[
              for (int i = 0; i < specs.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _SummaryCard(spec: specs[i])),
              ],
            ],
          );
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: specs
              .map(
                (_SummarySpec spec) => SizedBox(
                  width: (constraints.maxWidth - 8) / 2,
                  child: _SummaryCard(spec: spec),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _SummarySpec {
  const _SummarySpec({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
    required this.accent,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color tint;
  final Color accent;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.spec});

  final _SummarySpec spec;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool dark = theme.brightness == Brightness.dark;
    return Material(
      // Light pastels stay slightly translucent; dark fills are already soft.
      color: dark ? spec.tint : spec.tint.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: spec.accent.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(spec.icon, color: spec.accent, size: 22),
            const SizedBox(height: 10),
            Text(
              '${spec.value}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              spec.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltersPanel extends StatelessWidget {
  const _FiltersPanel({
    required this.structures,
    required this.filters,
    required this.searchController,
    required this.onChanged,
    required this.onReset,
  });

  final List<ExceptionReportStructure> structures;
  final ExceptionReportFilterState filters;
  final TextEditingController searchController;
  final ValueChanged<ExceptionReportFilterState> onChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final List<String> types =
        ExceptionReportFilters.structureTypeOptions(structures);
    final List<String> exceptions =
        ExceptionReportFilters.exceptionCategoryOptions(structures);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _FilterDropdown(
              label: 'Structure Type',
              value: filters.structureType,
              options: types,
              onChanged: (String value) =>
                  onChanged(filters.copyWith(structureType: value)),
            ),
            SizedBox(
              width: 220,
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  labelText: 'Structure / Chainage',
                  hintText: 'Search structure or chainage...',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                ),
                onChanged: (String value) =>
                    onChanged(filters.copyWith(searchQuery: value)),
              ),
            ),
            _FilterDropdown(
              label: 'Drawing Status',
              value: filters.drawingStatus,
              options: ExceptionReportFilters.drawingStatusOptions,
              onChanged: (String value) =>
                  onChanged(filters.copyWith(drawingStatus: value)),
            ),
            _FilterDropdown(
              label: 'Front Availability',
              value: filters.frontAvailability,
              options: ExceptionReportFilters.frontAvailabilityOptions,
              onChanged: (String value) =>
                  onChanged(filters.copyWith(frontAvailability: value)),
            ),
            _FilterDropdown(
              label: 'Utility Shifting',
              value: filters.utilityShifting,
              options: ExceptionReportFilters.utilityShiftingOptions,
              onChanged: (String value) =>
                  onChanged(filters.copyWith(utilityShifting: value)),
            ),
            _FilterDropdown(
              label: 'Exception Category',
              value: filters.exceptionCategory,
              options: exceptions,
              onChanged: (String value) =>
                  onChanged(filters.copyWith(exceptionCategory: value)),
            ),
            OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reset Filters'),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final String selected =
        options.contains(value) ? value : ExceptionReportFilters.all;
    return SizedBox(
      width: 170,
      child: DropdownButtonFormField<String>(
        key: ValueKey<String>('$label|$selected|${options.length}'),
        initialValue: selected,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
        ),
        items: options
            .map(
              (String option) => DropdownMenuItem<String>(
                value: option,
                child: Text(option, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(growable: false),
        onChanged: (String? next) {
          if (next != null) {
            onChanged(next);
          }
        },
      ),
    );
  }
}

class _StructuresTable extends StatelessWidget {
  const _StructuresTable({
    required this.page,
    required this.onView,
  });

  final TablePage<ExceptionReportStructure> page;
  final ValueChanged<ExceptionReportStructure> onView;

  static const double _indexW = 44;
  static const double _typeW = 120;
  static const double _nameW = 220;
  static const double _frontW = 130;
  static const double _utilityW = 130;
  static const double _drawingW = 130;
  static const double _issuesW = 64;
  static const double _scopeW = 90;
  static const double _actualW = 140;
  static const double _tdcW = 110;
  static const double _actionW = 88;
  static const double _pad = 8;

  static double get _totalWidth =>
      _indexW +
      _typeW +
      _nameW +
      _frontW +
      _utilityW +
      _drawingW +
      _drawingW +
      _issuesW +
      _scopeW +
      _actualW +
      _tdcW +
      _actionW +
      (_pad * 2);

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _totalWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _header(context),
              for (int i = 0; i < page.items.length; i++) ...<Widget>[
                Divider(
                  height: 1,
                  thickness: 0.6,
                  color: cs.outlineVariant.withValues(alpha: 0.45),
                ),
                _row(
                  context,
                  page.items[i],
                  serial: page.serial(i),
                  striped: i.isOdd,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      color: AppTheme.dataTableHeaderFill,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: _pad),
      child: Row(
        children: <Widget>[
          _h('#', _indexW, centered: true),
          _h('Structure Type', _typeW),
          _h('Structure / Chainage', _nameW),
          _h('Front Available', _frontW),
          _h('Utility Shifting', _utilityW),
          _h('General Drawing', _drawingW),
          _h('Detailed Drawing', _drawingW),
          _h('Issues', _issuesW, centered: true),
          _h('Scope', _scopeW),
          _h('Actual Progress', _actualW),
          _h('TDC', _tdcW),
          _h('Action', _actionW, centered: true),
        ],
      ),
    );
  }

  Widget _h(String label, double width, {bool centered = false}) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        textAlign: centered ? TextAlign.center : TextAlign.left,
        style: const TextStyle(
          color: AppTheme.dataTableHeaderOnFill,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    ExceptionReportStructure row, {
    required int serial,
    required bool striped,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return Container(
      color: striped
          ? cs.surfaceContainerHighest.withValues(alpha: 0.28)
          : cs.surface,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: _pad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: _indexW,
            child: Text(
              '$serial',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ),
          SizedBox(
            width: _typeW,
            child: Text(row.type, style: theme.textTheme.bodySmall),
          ),
          SizedBox(
            width: _nameW,
            child: Text(
              row.name,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: _frontW,
            child: Text(
              row.frontAvailableLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.primary,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: _utilityW,
            child: Text(
              row.utilityShiftingLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: row.utilityShiftingLabel == '—'
                    ? cs.onSurfaceVariant
                    : cs.primary,
                decoration: row.utilityShiftingLabel == '—'
                    ? TextDecoration.none
                    : TextDecoration.underline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: _drawingW,
            child: _DrawingStatusCell(
              label: row.generalDrawingLabel,
              dot: row.generalDrawingDot,
            ),
          ),
          SizedBox(
            width: _drawingW,
            child: _DrawingStatusCell(
              label: row.detailedDrawingLabel,
              dot: row.detailedDrawingDot,
            ),
          ),
          SizedBox(
            width: _issuesW,
            child: Text(
              '${row.issues}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: row.issues > 0
                    ? AppTheme.softMetricForeground(
                        theme.brightness,
                        lightForeground: const Color(0xFFDC2626),
                        darkForeground: const Color(0xFFFCA5A5),
                      )
                    : null,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: _scopeW,
            child: Text(row.scope, style: theme.textTheme.bodySmall),
          ),
          SizedBox(
            width: _actualW,
            child: _ActualProgressCell(
              label: row.actualProgressLabel,
              fraction: row.actualProgressFraction,
            ),
          ),
          SizedBox(
            width: _tdcW,
            child: Text(row.tdcLabel, style: theme.textTheme.bodySmall),
          ),
          SizedBox(
            width: _actionW,
            child: Center(
              child: TextButton.icon(
                onPressed: () => onView(row),
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('View'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawingStatusCell extends StatelessWidget {
  const _DrawingStatusCell({
    required this.label,
    required this.dot,
  });

  final String label;
  final DrawingStatusDot dot;

  @override
  Widget build(BuildContext context) {
    final Color? color = switch (dot) {
      DrawingStatusDot.approved => const Color(0xFF16A34A),
      DrawingStatusDot.underReview => const Color(0xFFDC2626),
      DrawingStatusDot.none => null,
    };
    return Row(
      children: <Widget>[
        if (color != null) ...<Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ActualProgressCell extends StatelessWidget {
  const _ActualProgressCell({
    required this.label,
    required this.fraction,
  });

  final String label;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: cs.surfaceContainerHighest,
            color: cs.primary,
          ),
        ),
      ],
    );
  }
}
