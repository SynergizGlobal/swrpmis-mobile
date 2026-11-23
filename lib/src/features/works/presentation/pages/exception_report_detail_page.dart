import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/paging/table_page.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_fullscreen_loader.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/entities/exception_report_detail.dart';
import 'package:swr_pmis_mobile/src/features/works/presentation/pages/exception_report_page.dart';
import 'package:swr_pmis_mobile/src/features/works/presentation/providers/works_providers.dart';

class ExceptionReportDetailPage extends ConsumerStatefulWidget {
  const ExceptionReportDetailPage({
    super.key,
    required this.projectId,
    required this.structureId,
    required this.fallbackName,
  });

  static const String routeName = 'works-exception-report-detail';
  static const String routePath =
      '/works/exception-report/:projectId/structures/:structureId';

  final String projectId;
  final int structureId;
  final String fallbackName;

  @override
  ConsumerState<ExceptionReportDetailPage> createState() =>
      _ExceptionReportDetailPageState();
}

class _ExceptionReportDetailPageState
    extends ConsumerState<ExceptionReportDetailPage> {
  int _utilityPage = 1;
  static const int _utilityPageSize = 10;

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.goNamed(
      ExceptionReportPage.routeName,
      pathParameters: <String, String>{'projectId': widget.projectId},
      queryParameters: <String, String>{
        if (widget.fallbackName.trim().isNotEmpty) 'name': widget.fallbackName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ExceptionReportDetail> async = ref.watch(
      exceptionReportDetailProvider(widget.structureId),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
          onPressed: () => _goBack(context),
        ),
        title: const Text('Structure details'),
      ),
      body: async.when(
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
                    exceptionReportDetailProvider(widget.structureId),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (ExceptionReportDetail detail) => _body(context, detail),
      ),
    );
  }

  Widget _body(BuildContext context, ExceptionReportDetail detail) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final Color activeFill = AppTheme.softMetricFill(
      theme.brightness,
      lightFill: const Color(0xFFDCFCE7),
      accent: const Color(0xFF16A34A),
    );
    final Color activeFg = AppTheme.softMetricForeground(
      theme.brightness,
      lightForeground: const Color(0xFF15803D),
      darkForeground: const Color(0xFF34D399),
    );
    final TablePage<ExceptionUtilitySegment> utilityPage = TablePage.slice(
      detail.utility.segments,
      page: _utilityPage,
      pageSize: _utilityPageSize,
    );
    if (_utilityPage != utilityPage.page) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() => _utilityPage = utilityPage.page);
      });
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(exceptionReportDetailProvider(widget.structureId));
        await ref.read(
          exceptionReportDetailProvider(widget.structureId).future,
        );
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
        children: <Widget>[
          Text(
            'Exception Report > Structure details',
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  detail.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (detail.isActive) ...<Widget>[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: activeFill,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: activeFg,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        detail.status,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: activeFg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (detail.contract.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              detail.contract,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool wide = constraints.maxWidth >= 900;
              final Widget front = _FrontCard(section: detail.front);
              final Widget utility = _UtilityCard(
                section: detail.utility,
                page: utilityPage,
                onPrev: utilityPage.page > 1
                    ? () => setState(() => _utilityPage = utilityPage.page - 1)
                    : null,
                onNext: utilityPage.page < utilityPage.pageCount
                    ? () => setState(() => _utilityPage = utilityPage.page + 1)
                    : null,
              );
              final Widget drawings = _DrawingsCard(
                general: detail.generalDrawings,
                detailed: detail.detailedDrawings,
              );
              final Widget issues = _IssuesCard(issues: detail.issues);

              if (!wide) {
                return Column(
                  children: <Widget>[
                    front,
                    const SizedBox(height: 12),
                    utility,
                    const SizedBox(height: 12),
                    drawings,
                    const SizedBox(height: 12),
                    issues,
                  ],
                );
              }

              return Column(
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: front),
                      const SizedBox(width: 12),
                      Expanded(child: utility),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: drawings),
                      const SizedBox(width: 12),
                      Expanded(child: issues),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return Material(
      color: AppPalette.of(context).cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, size: 20, color: iconColor ?? cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (trailing != null) ...<Widget>[
                  const SizedBox(width: 8),
                  Flexible(child: trailing!),
                ],
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _FrontCard extends StatelessWidget {
  const _FrontCard({required this.section});

  final ExceptionFrontSection section;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return _SectionCard(
      icon: Icons.checklist_rounded,
      title: 'Front Availability',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            section.summaryLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: section.fraction,
              minHeight: 8,
              backgroundColor: cs.surfaceContainerHighest,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 12),
          _MiniTable(
            headers: const <String>[
              '#',
              'Chainage From',
              'Chainage To',
              'Length (km)',
              'Status',
              'Remarks',
            ],
            columnWidths: const <double>[
              36,
              100,
              100,
              90,
              120,
              140,
            ],
            rows: <Widget>[
              for (int i = 0; i < section.segments.length; i++)
                _frontRow(context, i + 1, section.segments[i]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _frontRow(
    BuildContext context,
    int index,
    ExceptionFrontSegment segment,
  ) {
    final bool available = segment.isAvailable;
    return _MiniTableRow(
      cells: <Widget>[
        Text('$index'),
        Text(_num(segment.from)),
        Text(_num(segment.to)),
        Text(_num(segment.length)),
        _StatusDotLabel(
          label: segment.status,
          color: available
              ? const Color(0xFF16A34A)
              : const Color(0xFFDC2626),
        ),
        Text(segment.remarks),
      ],
      widths: const <double>[36, 100, 100, 90, 120, 140],
    );
  }
}

class _UtilityCard extends StatelessWidget {
  const _UtilityCard({
    required this.section,
    required this.page,
    required this.onPrev,
    required this.onNext,
  });

  final ExceptionUtilitySection section;
  final TablePage<ExceptionUtilitySegment> page;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return _SectionCard(
      icon: Icons.bar_chart_rounded,
      title: 'Utility Shifting',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            section.summaryLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: section.fraction,
              minHeight: 8,
              backgroundColor: cs.surfaceContainerHighest,
              color: const Color(0xFFEA580C),
            ),
          ),
          const SizedBox(height: 12),
          _MiniTable(
            headers: const <String>[
              '#',
              'Chainage From',
              'Chainage To',
              'Length (km)',
              'Status',
              'Utility Type',
              'Remarks',
            ],
            columnWidths: const <double>[
              36,
              100,
              100,
              90,
              110,
              160,
              80,
            ],
            rows: <Widget>[
              for (int i = 0; i < page.items.length; i++)
                _utilityRow(context, page.serial(i), page.items[i]),
            ],
          ),
          if (page.total > 0) ...<Widget>[
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${page.start + 1}–${page.end} of ${page.total}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onPrev,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Previous'),
                ),
                Flexible(
                  child: Text(
                    'Page ${page.page} of ${page.pageCount}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium,
                  ),
                ),
                TextButton(
                  onPressed: onNext,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _utilityRow(
    BuildContext context,
    int index,
    ExceptionUtilitySegment segment,
  ) {
    final Color color = segment.isCompleted
        ? const Color(0xFF16A34A)
        : const Color(0xFFEA580C);
    return _MiniTableRow(
      cells: <Widget>[
        Text('$index'),
        Text(_num(segment.from)),
        Text(_num(segment.to)),
        Text(_num(segment.length)),
        _StatusDotLabel(label: segment.status, color: color),
        Text(segment.type),
        Text(segment.remarks),
      ],
      widths: const <double>[36, 100, 100, 90, 110, 160, 80],
    );
  }
}

class _DrawingsCard extends StatelessWidget {
  const _DrawingsCard({
    required this.general,
    required this.detailed,
  });

  final ExceptionDrawingsSection general;
  final ExceptionDrawingsSection detailed;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.description_outlined,
      title: 'Drawing Status',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _DrawingSubsection(title: 'General Drawings', section: general),
          const SizedBox(height: 14),
          _DrawingSubsection(title: 'Detailed Drawings', section: detailed),
        ],
      ),
    );
  }
}

class _DrawingSubsection extends StatelessWidget {
  const _DrawingSubsection({
    required this.title,
    required this.section,
  });

  final String title;
  final ExceptionDrawingsSection section;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  section.statusLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (section.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: Text(
                'No drawings recorded for this structure.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          _MiniTable(
            headers: const <String>[
              'Structure',
              'Drawing Category',
              'Total',
              'Approved',
              'Pending',
              'Remarks',
            ],
            columnWidths: const <double>[120, 130, 60, 70, 70, 100],
            rows: <Widget>[
              for (final ExceptionDrawingRow row in section.rows)
                _MiniTableRow(
                  cells: <Widget>[
                    Text(row.structure),
                    Text(row.drawingCategory),
                    Text(row.total),
                    Text(row.approved),
                    Text(row.pending),
                    Text(row.remarks),
                  ],
                  widths: const <double>[120, 130, 60, 70, 70, 100],
                ),
            ],
          ),
      ],
    );
  }
}

class _IssuesCard extends StatelessWidget {
  const _IssuesCard({required this.issues});

  final List<ExceptionIssueRow> issues;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color issueAccent = AppTheme.softMetricForeground(
      theme.brightness,
      lightForeground: const Color(0xFFDC2626),
      darkForeground: const Color(0xFFFCA5A5),
    );
    return _SectionCard(
      icon: Icons.error_outline_rounded,
      iconColor: issueAccent,
      title: 'Issues',
      trailing: Text(
        'Total Issues ${issues.length}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: issueAccent,
        ),
      ),
      child: issues.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  'No issues recorded for this structure.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          : _MiniTable(
              headers: const <String>[
                'Issue ID',
                'Category',
                'Description',
                'Status',
                'Raised On',
                'Target Date',
              ],
              columnWidths: const <double>[80, 120, 200, 80, 100, 100],
              rows: <Widget>[
                for (final ExceptionIssueRow issue in issues)
                  _MiniTableRow(
                    cells: <Widget>[
                      Text(issue.id),
                      Text(issue.category),
                      Text(issue.description),
                      Text(issue.status),
                      Text(issue.raisedOnLabel),
                      Text(issue.targetDateLabel),
                    ],
                    widths: const <double>[80, 120, 200, 80, 100, 100],
                  ),
              ],
            ),
    );
  }
}

class _MiniTable extends StatelessWidget {
  const _MiniTable({
    required this.headers,
    required this.columnWidths,
    required this.rows,
  });

  static const double _hPad = 6;

  final List<String> headers;
  final List<double> columnWidths;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    // Include horizontal padding so fixed-width column Rows fit the SizedBox.
    final double width =
        columnWidths.fold(0.0, (double a, double b) => a + b) + (_hPad * 2);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: _hPad,
                ),
                child: Row(
                  children: <Widget>[
                    for (int i = 0; i < headers.length; i++)
                      SizedBox(
                        width: columnWidths[i],
                        child: Text(
                          headers[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                  ],
                ),
              ),
              if (rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No rows',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              else
                ...rows,
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniTableRow extends StatelessWidget {
  const _MiniTableRow({
    required this.cells,
    required this.widths,
  });

  final List<Widget> cells;
  final List<double> widths;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.55)),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: _MiniTable._hPad,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < cells.length; i++)
            SizedBox(
              width: widths[i],
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.bodySmall!,
                child: cells[i],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusDotLabel extends StatelessWidget {
  const _StatusDotLabel({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

String _num(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  final String fixed = value.toStringAsFixed(2);
  if (fixed.endsWith('0')) {
    return value.toStringAsFixed(1);
  }
  return fixed;
}
