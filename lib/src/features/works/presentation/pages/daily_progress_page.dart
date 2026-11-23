import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_fullscreen_loader.dart';
import 'package:swr_pmis_mobile/src/features/works/data/daily_progress_export_file.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/entities/daily_progress_query.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/entities/daily_progress_row.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/utils/daily_progress_filters.dart';
import 'package:swr_pmis_mobile/src/features/works/presentation/pages/project_overview_page.dart';
import 'package:swr_pmis_mobile/src/features/works/presentation/providers/works_providers.dart';

class DailyProgressPage extends ConsumerStatefulWidget {
  const DailyProgressPage({
    super.key,
    required this.projectId,
    required this.fallbackName,
    this.embedded = false,
  });

  static const String routeName = 'works-daily-progress';
  static const String routePath = '/works/daily-progress/:projectId';

  final String projectId;
  final String fallbackName;

  /// When true, renders content only (no Scaffold/AppBar) for hub embedding.
  final bool embedded;

  @override
  ConsumerState<DailyProgressPage> createState() => _DailyProgressPageState();
}

class _DailyProgressPageState extends ConsumerState<DailyProgressPage> {
  late DateTime _fromDate;
  late DateTime _toDate;
  DailyProgressFilterState _filters = DailyProgressFilterState.cleared;
  final Set<String> _expandedActivities = <String>{};
  final Set<String> _expandedSections = <String>{};
  bool _exportingExcel = false;
  bool _exportingPdf = false;

  static final DateFormat _displayDate = DateFormat('dd-MM-yyyy');
  static final DateFormat _inputDate = DateFormat('dd/MM/yyyy');

  static const Color _completedLightBg = Color(0xFFDCFCE7);
  static const Color _completedAccent = Color(0xFF16A34A);
  static const Color _progressLightBg = Color(0xFFEDE9FE);
  static const Color _progressAccent = Color(0xFF7C3AED);
  static const Color _badgeLightBg = Color(0xFFDBEAFE);
  static const Color _badgeLightFg = Color(0xFF1D4ED8);
  static const Color _badgeDarkFg = Color(0xFF93C5FD);

  bool get _exporting => _exportingExcel || _exportingPdf;

  @override
  void initState() {
    super.initState();
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    _fromDate = today;
    _toDate = today;
  }

  DailyProgressQuery get _query => DailyProgressQuery(
        projectId: widget.projectId,
        fromDate: _fromDate,
        toDate: _toDate,
      );

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

  Future<void> _pickDate({required bool from}) async {
    final DateTime initial = from ? _fromDate : _toDate;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked == null) {
      return;
    }
    final DateTime day = DateUtils.dateOnly(picked);
    setState(() {
      if (from) {
        _fromDate = day;
        if (_toDate.isBefore(_fromDate)) {
          _toDate = _fromDate;
        }
      } else {
        _toDate = day;
        if (_fromDate.isAfter(_toDate)) {
          _fromDate = _toDate;
        }
      }
      _expandedActivities.clear();
      _expandedSections.clear();
    });
  }

  void _applyFilters(DailyProgressFilterState next) {
    setState(() {
      _filters = next;
      _expandedActivities.clear();
      _expandedSections.clear();
    });
  }

  void _toggleActivity(String activity) {
    setState(() {
      if (!_expandedActivities.add(activity)) {
        _expandedActivities.remove(activity);
        _expandedSections.removeWhere(
          (String key) => key.startsWith('$activity||'),
        );
      }
    });
  }

  void _toggleSection(String activity, String section) {
    final String key = '$activity||$section';
    setState(() {
      if (!_expandedSections.add(key)) {
        _expandedSections.remove(key);
      }
    });
  }

  Future<void> _onExportExcel({
    required BuildContext origin,
    required List<DailyProgressActivityGroup> groups,
  }) async {
    await _export(
      origin: origin,
      kind: 'Excel',
      groups: groups,
      setBusy: (bool value) => _exportingExcel = value,
      share: shareDailyProgressXlsx,
    );
  }

  Future<void> _onExportPdf({
    required BuildContext origin,
    required List<DailyProgressActivityGroup> groups,
  }) async {
    await _export(
      origin: origin,
      kind: 'PDF',
      groups: groups,
      setBusy: (bool value) => _exportingPdf = value,
      share: shareDailyProgressPdf,
    );
  }

  Future<void> _export({
    required BuildContext origin,
    required String kind,
    required List<DailyProgressActivityGroup> groups,
    required void Function(bool value) setBusy,
    required Future<void> Function({
      required List<DailyProgressActivityGroup> groups,
      required DateTime reportDate,
      Rect? sharePositionOrigin,
    })
    share,
  }) async {
    if (_exporting || !mounted) {
      return;
    }
    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('There are no records to export to $kind.')),
      );
      return;
    }
    final Rect originRect = _shareOrigin(origin);
    setState(() => setBusy(true));
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) {
        return;
      }
      await share(
        groups: groups,
        reportDate: _toDate,
        sharePositionOrigin: originRect,
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to export Daily Progress to $kind'
            '${error is StateError ? ': ${error.message}' : ''}.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => setBusy(false));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<DailyProgressRow>> async = ref.watch(
      dailyProgressProvider(_query),
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
                onPressed: () =>
                    ref.invalidate(dailyProgressProvider(_query)),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (List<DailyProgressRow> rows) => _content(context, rows),
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => _goBack(context)),
        title: const Text('Daily Progress'),
      ),
      body: body,
    );
  }

  Widget _content(BuildContext context, List<DailyProgressRow> allRows) {
    final List<String> sectionOptions =
        DailyProgressFilters.sectionOptions(allRows);
    final List<String> activityOptions =
        DailyProgressFilters.activityOptions(allRows);
    final DailyProgressFilterState filters = _filters.copyWith(
      section: DailyProgressFilters.sheetValue(sectionOptions, _filters.section),
      activity:
          DailyProgressFilters.sheetValue(activityOptions, _filters.activity),
    );
    if (filters.section != _filters.section ||
        filters.activity != _filters.activity) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() => _filters = filters);
      });
    }

    final List<DailyProgressRow> filtered =
        DailyProgressFilters.apply(allRows, filters);
    final List<DailyProgressActivityGroup> groups =
        groupDailyProgress(filtered);
    final int structureCount = filtered.length;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dailyProgressProvider(_query));
        await ref.read(dailyProgressProvider(_query).future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: <Widget>[
          _filtersCard(
            context,
            sectionOptions: sectionOptions,
            activityOptions: activityOptions,
            filters: filters,
            groups: groups,
          ),
          const SizedBox(height: 12),
          if (allRows.isEmpty)
            const _EmptyState(message: 'No daily progress data for this date.')
          else if (filtered.isEmpty)
            const _EmptyState(
              message: 'No activities match the selected filters.',
            )
          else
            Builder(
              builder: (BuildContext context) {
                final Brightness brightness =
                    Theme.of(context).brightness;
                return _HierarchyTable(
                  groups: groups,
                  expandedActivities: _expandedActivities,
                  expandedSections: _expandedSections,
                  onToggleActivity: _toggleActivity,
                  onToggleSection: _toggleSection,
                  completedBg: AppTheme.softMetricFill(
                    brightness,
                    lightFill: _completedLightBg,
                    accent: _completedAccent,
                  ),
                  progressBg: AppTheme.softMetricFill(
                    brightness,
                    lightFill: _progressLightBg,
                    accent: _progressAccent,
                  ),
                  badgeBg: AppTheme.softMetricFill(
                    brightness,
                    lightFill: _badgeLightBg,
                    accent: _badgeLightFg,
                  ),
                  badgeFg: AppTheme.softMetricForeground(
                    brightness,
                    lightForeground: _badgeLightFg,
                    darkForeground: _badgeDarkFg,
                  ),
                );
              },
            ),
          const SizedBox(height: 12),
          Text(
            'Showing ${groups.length} activities · $structureCount structures',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filtersCard(
    BuildContext context, {
    required List<String> sectionOptions,
    required List<String> activityOptions,
    required DailyProgressFilterState filters,
    required List<DailyProgressActivityGroup> groups,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final bool busy = _exporting;

    return Material(
      color: AppPalette.of(context).cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Daily Progress Report',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Report date: ${_displayDate.format(_toDate)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _DropdownField(
                    value: filters.section,
                    options: sectionOptions,
                    onChanged: (String value) =>
                        _applyFilters(filters.copyWith(section: value)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DropdownField(
                    value: filters.activity,
                    options: activityOptions,
                    onChanged: (String value) =>
                        _applyFilters(filters.copyWith(activity: value)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: _DateField(
                    label: 'From',
                    value: _inputDate.format(_fromDate),
                    onTap: busy ? null : () => _pickDate(from: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DateField(
                    label: 'To',
                    value: _inputDate.format(_toDate),
                    onTap: busy ? null : () => _pickDate(from: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: Builder(
                    builder: (BuildContext buttonContext) {
                      return FilledButton.icon(
                        onPressed: busy
                            ? null
                            : () => _onExportExcel(
                                  origin: buttonContext,
                                  groups: groups,
                                ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(
                            0xFF16A34A,
                          ).withValues(alpha: 0.55),
                          disabledForegroundColor: Colors.white,
                        ),
                        icon: _exportingExcel
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.download_rounded, size: 18),
                        label: Text(
                          _exportingExcel ? 'Exporting…' : 'Export Excel',
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Builder(
                    builder: (BuildContext buttonContext) {
                      return FilledButton.icon(
                        onPressed: busy
                            ? null
                            : () => _onExportPdf(
                                  origin: buttonContext,
                                  groups: groups,
                                ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFB91C1C),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(
                            0xFFB91C1C,
                          ).withValues(alpha: 0.55),
                          disabledForegroundColor: Colors.white,
                        ),
                        icon: _exportingPdf
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.download_rounded, size: 18),
                        label: Text(
                          _exportingPdf ? 'Exporting…' : 'Export PDF',
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return InputDecorator(
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: options.contains(value) ? value : options.first,
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
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: cs.outlineVariant),
          ),
        ),
        child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}

class _HierarchyTable extends StatelessWidget {
  const _HierarchyTable({
    required this.groups,
    required this.expandedActivities,
    required this.expandedSections,
    required this.onToggleActivity,
    required this.onToggleSection,
    required this.completedBg,
    required this.progressBg,
    required this.badgeBg,
    required this.badgeFg,
  });

  final List<DailyProgressActivityGroup> groups;
  final Set<String> expandedActivities;
  final Set<String> expandedSections;
  final ValueChanged<String> onToggleActivity;
  final void Function(String activity, String section) onToggleSection;
  final Color completedBg;
  final Color progressBg;
  final Color badgeBg;
  final Color badgeFg;

  static const double _activityW = 200;
  static const double _unitW = 56;
  static const double _structuresW = 110;
  static const double _numW = 108;
  static const double _tdcW = 100;
  static const double _actionW = 72;
  static const double _pad = 8;

  static double get _parentWidth =>
      _activityW +
      _unitW +
      _structuresW +
      (_numW * 5) +
      _tdcW +
      _actionW +
      (_pad * 2);

  static const double _structNameW = 220;
  static const double _structUnitW = 56;
  static const double _structNumW = 108;
  static const double _structMpW = 72;
  static const double _structTdcW = 100;
  static const double _structMarginL = 18;
  static const double _structMarginR = 8;
  /// Matches [Border.all] width; Container merges decoration padding into child.
  static const double _structBorderW = 1;

  static double get _structColumnsWidth =>
      _structNameW +
      _structUnitW +
      (_structNumW * 5) +
      (_structMpW * 2) +
      _structTdcW;

  /// Inner width of the nested structure table (columns + pad + border inset).
  static double get _structTableWidth =>
      _structColumnsWidth + (_pad * 2) + (_structBorderW * 2);

  /// Outer horizontal scroll extent must fit the indented structure table.
  static double get _childWidth =>
      _structTableWidth + _structMarginL + _structMarginR;

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
          width: _parentWidth > _childWidth ? _parentWidth : _childWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _parentHeader(context),
              for (final DailyProgressActivityGroup group in groups)
                _activityBlock(context, group),
            ],
          ),
        ),
      ),
    );
  }

  Widget _parentHeader(BuildContext context) {
    return Container(
      color: AppTheme.dataTableHeaderFill,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: _pad),
      child: Row(
        children: <Widget>[
          _h(context, 'Activity', _activityW),
          _h(context, 'Unit', _unitW),
          _h(context, 'Structures', _structuresW),
          _h(context, 'Scope', _numW, align: TextAlign.right),
          _h(context, 'Completed Qty', _numW, align: TextAlign.right),
          _h(context, 'Balance', _numW, align: TextAlign.right),
          _h(context, 'Asking Rate', _numW, align: TextAlign.right),
          _h(context, 'Progress on Date', _numW, align: TextAlign.right),
          _h(context, 'TDC', _tdcW),
          _h(context, 'Action', _actionW, align: TextAlign.center),
        ],
      ),
    );
  }

  Widget _activityBlock(
    BuildContext context,
    DailyProgressActivityGroup group,
  ) {
    final bool expanded = expandedActivities.contains(group.activity);
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InkWell(
          onTap: () => onToggleActivity(group.activity),
          child: Container(
            color: cs.primary.withValues(alpha: 0.06),
            padding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: _pad,
            ),
            child: _parentMetricsRow(
              context,
              leading: Row(
                children: <Widget>[
                  Transform.rotate(
                    angle: expanded ? 1.5708 : 0,
                    child: Icon(
                      Icons.play_arrow_rounded,
                      size: 18,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      group.activity,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              totals: group.totals,
              action: null,
            ),
          ),
        ),
        if (expanded)
          for (final DailyProgressSectionGroup section in group.sections)
            _sectionBlock(context, group.activity, section),
        Divider(
          height: 1,
          thickness: 0.6,
          color: cs.outlineVariant.withValues(alpha: 0.45),
        ),
      ],
    );
  }

  Widget _sectionBlock(
    BuildContext context,
    String activity,
    DailyProgressSectionGroup section,
  ) {
    final bool expanded = expandedSections.contains('$activity||${section.section}');
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InkWell(
          onTap: () => onToggleSection(activity, section.section),
          child: Container(
            color: cs.surface,
            padding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: _pad,
            ),
            child: _parentMetricsRow(
              context,
              leading: Padding(
                padding: const EdgeInsets.only(left: 18),
                child: Row(
                  children: <Widget>[
                    Transform.rotate(
                      angle: expanded ? 1.5708 : 0,
                      child: Icon(
                        Icons.play_arrow_rounded,
                        size: 16,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        section.section,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              totals: section.totals,
              action: TextButton(
                onPressed: () => onToggleSection(activity, section.section),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
                child: Text(expanded ? 'Hide' : 'View'),
              ),
            ),
          ),
        ),
        if (expanded) _structureTable(context, section.structures),
      ],
    );
  }

  Widget _parentMetricsRow(
    BuildContext context, {
    required Widget leading,
    required DailyProgressTotals totals,
    required Widget? action,
  }) {
    return Row(
      children: <Widget>[
        SizedBox(width: _activityW, child: leading),
        SizedBox(
          width: _unitW,
          child: Text(
            totals.unit,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        SizedBox(
          width: _structuresW,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                totals.structuresBadge,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: badgeFg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        _numCell(context, DailyProgressRow.formatQty(totals.scope), _numW),
        _numCell(
          context,
          DailyProgressRow.formatQty(totals.completedQty),
          _numW,
          highlight: completedBg,
        ),
        _numCell(context, DailyProgressRow.formatQty(totals.balance), _numW),
        _numCell(
          context,
          DailyProgressRow.formatQty(totals.askingRate),
          _numW,
        ),
        _numCell(
          context,
          DailyProgressRow.formatQty(totals.progressOnDate),
          _numW,
          highlight: progressBg,
        ),
        SizedBox(
          width: _tdcW,
          child: Text(
            totals.tdcLabel,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        SizedBox(
          width: _actionW,
          child: action == null ? const SizedBox.shrink() : Center(child: action),
        ),
      ],
    );
  }

  Widget _structureTable(
    BuildContext context,
    List<DailyProgressRow> structures,
  ) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      width: _structTableWidth,
      margin: const EdgeInsets.fromLTRB(
        _structMarginL,
        0,
        _structMarginR,
        8,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.7),
          width: _structBorderW,
        ),
        borderRadius: BorderRadius.circular(10),
        color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
      ),
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: _pad,
            ),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
            ),
            child: Row(
              children: <Widget>[
                _h(context, 'Structure', _structNameW, nested: true),
                _h(context, 'Unit', _structUnitW, nested: true),
                _h(
                  context,
                  'Scope',
                  _structNumW,
                  align: TextAlign.right,
                  nested: true,
                ),
                _h(
                  context,
                  'Planned Till Date',
                  _structNumW,
                  align: TextAlign.right,
                  nested: true,
                ),
                _h(
                  context,
                  'Actual Till Date',
                  _structNumW,
                  align: TextAlign.right,
                  nested: true,
                ),
                _h(
                  context,
                  'Asking Rate / Day',
                  _structNumW,
                  align: TextAlign.right,
                  nested: true,
                ),
                _h(
                  context,
                  'Actual For Day',
                  _structNumW,
                  align: TextAlign.right,
                  nested: true,
                ),
                _h(context, 'M&P', _structMpW, nested: true),
                _h(context, 'Manpower', _structMpW, nested: true),
                _h(context, 'TDC', _structTdcW, nested: true),
              ],
            ),
          ),
          for (int i = 0; i < structures.length; i++) ...<Widget>[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 0.5,
                color: cs.outlineVariant.withValues(alpha: 0.4),
              ),
            _structureRow(context, structures[i], striped: i.isOdd),
          ],
        ],
      ),
    );
  }

  Widget _structureRow(
    BuildContext context,
    DailyProgressRow row, {
    required bool striped,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return Container(
      color: striped
          ? cs.surfaceContainerHighest.withValues(alpha: 0.2)
          : cs.surface,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: _pad),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: _structNameW,
            child: Text(
              row.structure,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: _structUnitW,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeFg.withValues(alpha: 0.35)),
                  color: badgeBg.withValues(alpha: 0.5),
                ),
                child: Text(
                  row.unit,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: badgeFg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          _numCell(
            context,
            DailyProgressRow.formatQty(row.scope),
            _structNumW,
          ),
          _numCell(
            context,
            DailyProgressRow.formatQty(row.plannedTillDate),
            _structNumW,
          ),
          _numCell(
            context,
            DailyProgressRow.formatQty(row.actualTillDate),
            _structNumW,
            highlight: completedBg,
          ),
          _numCell(
            context,
            DailyProgressRow.formatQty(row.askingRatePerDay),
            _structNumW,
          ),
          _numCell(
            context,
            DailyProgressRow.formatQty(row.actualForDay),
            _structNumW,
            highlight: progressBg,
          ),
          SizedBox(
            width: _structMpW,
            child: Text(row.mpLabel, style: theme.textTheme.bodySmall),
          ),
          SizedBox(
            width: _structMpW,
            child: Text(row.manpowerLabel, style: theme.textTheme.bodySmall),
          ),
          SizedBox(
            width: _structTdcW,
            child: Text(row.tdcLabel, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  Widget _h(
    BuildContext context,
    String label,
    double width, {
    TextAlign align = TextAlign.left,
    bool nested = false,
  }) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: Text(
        label,
        textAlign: align,
        style: TextStyle(
          color: nested
              ? cs.onSurface
              : AppTheme.dataTableHeaderOnFill,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _numCell(
    BuildContext context,
    String text,
    double width, {
    Color? highlight,
  }) {
    final Widget child = Text(
      text,
      textAlign: TextAlign.right,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      ),
    );
    if (highlight == null) {
      return SizedBox(width: width, child: child);
    }
    return SizedBox(
      width: width,
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: highlight,
            borderRadius: BorderRadius.circular(6),
          ),
          child: child,
        ),
      ),
    );
  }
}
