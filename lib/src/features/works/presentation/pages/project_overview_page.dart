import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/features/works/presentation/pages/daily_progress_page.dart';
import 'package:swr_pmis_mobile/src/features/works/presentation/pages/exception_report_page.dart';
import 'package:swr_pmis_mobile/src/features/works/presentation/pages/site_images_page.dart';
import 'package:swr_pmis_mobile/src/features/works/presentation/providers/works_providers.dart';
import 'package:swr_pmis_mobile/src/features/works/presentation/widgets/project_progress_panel.dart';

enum ProjectOverviewSection {
  projectOverview,
  executionStripChart,
  progressTable,
  dailyProgress,
  exceptionReport,
  siteImages,
}

enum StripChartChild {
  track,
  station,
}

class ProjectOverviewPage extends ConsumerStatefulWidget {
  const ProjectOverviewPage({
    super.key,
    required this.projectId,
    required this.fallbackName,
    this.initialSection = ProjectOverviewSection.projectOverview,
  });

  static const String routeName = 'works-overview';
  static const String routePath = '/works/overview/:projectId';

  final String projectId;
  final String fallbackName;
  final ProjectOverviewSection initialSection;

  @override
  ConsumerState<ProjectOverviewPage> createState() =>
      _ProjectOverviewPageState();
}

class _ProjectOverviewPageState extends ConsumerState<ProjectOverviewPage> {
  late ProjectOverviewSection _selected;
  StripChartChild _stripChild = StripChartChild.track;

  static const List<({ProjectOverviewSection section, String label})>
  _mainChips = <({ProjectOverviewSection section, String label})>[
    (section: ProjectOverviewSection.projectOverview, label: 'Project Overview'),
    (
      section: ProjectOverviewSection.executionStripChart,
      label: 'Execution Strip Chart',
    ),
    (section: ProjectOverviewSection.progressTable, label: 'Progress Table'),
    (section: ProjectOverviewSection.dailyProgress, label: 'Daily Progress'),
    // Chip label; body embeds existing Exception Report.
    (section: ProjectOverviewSection.exceptionReport, label: 'Execution Report'),
    (section: ProjectOverviewSection.siteImages, label: 'Site Images'),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSection;
    if (widget.initialSection == ProjectOverviewSection.executionStripChart) {
      _stripChild = StripChartChild.track;
    }
  }

  String get _title {
    final String name = widget.fallbackName.trim();
    if (name.isEmpty) {
      return widget.projectId;
    }
    return name;
  }

  bool get _showStripChildren =>
      _selected == ProjectOverviewSection.executionStripChart;

  void _select(ProjectOverviewSection section) {
    setState(() {
      _selected = section;
      if (section == ProjectOverviewSection.executionStripChart) {
        _stripChild = StripChartChild.track;
      }
    });
  }

  void _selectStripChild(StripChartChild child) {
    setState(() {
      _selected = ProjectOverviewSection.executionStripChart;
      _stripChild = child;
    });
  }

  Future<void> _refreshProgress() async {
    ref.invalidate(executionProgressProvider(widget.projectId));
    await ref.read(executionProgressProvider(widget.projectId).future);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/works');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Project Overview'),
            Text(
              _title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: _HubChipRow(
              children: _mainChips.map((
                ({ProjectOverviewSection section, String label}) item,
              ) {
                return _HubChoiceChip(
                  label: item.label,
                  selected: _selected == item.section,
                  onSelected: () => _select(item.section),
                );
              }).toList(growable: false),
            ),
          ),
          if (_showStripChildren)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: _HubChipRow(
                children: <Widget>[
                  _HubChoiceChip(
                    label: 'Track Strip Chart',
                    selected: _stripChild == StripChartChild.track,
                    onSelected: () =>
                        _selectStripChild(StripChartChild.track),
                  ),
                  _HubChoiceChip(
                    label: 'Station Strip Chart',
                    selected: _stripChild == StripChartChild.station,
                    onSelected: () =>
                        _selectStripChild(StripChartChild.station),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(child: _sectionBody(context)),
        ],
      ),
    );
  }

  Widget _sectionBody(BuildContext context) {
    switch (_selected) {
      case ProjectOverviewSection.projectOverview:
        return _ScrollablePanel(
          onRefresh: _refreshProgress,
          child: _OverviewCard(
            projectId: widget.projectId,
            child: ProjectProgressPanel(
              projectId: widget.projectId,
              fallbackName: widget.fallbackName,
            ),
          ),
        );
      case ProjectOverviewSection.executionStripChart:
        if (_stripChild == StripChartChild.track) {
          return _ScrollablePanel(
            onRefresh: _refreshProgress,
            child: _OverviewCard(
              projectId: widget.projectId,
              child: ProjectProgressPanel(
                projectId: widget.projectId,
                fallbackName: widget.fallbackName,
              ),
            ),
          );
        }
        return _PlaceholderPanel(
          projectId: widget.projectId,
          message:
              'Station Strip Chart will appear here once the API is available.',
        );
      case ProjectOverviewSection.progressTable:
        return _PlaceholderPanel(
          projectId: widget.projectId,
          message:
              'Progress table will appear here once the API is available.',
        );
      case ProjectOverviewSection.dailyProgress:
        return DailyProgressPage(
          projectId: widget.projectId,
          fallbackName: widget.fallbackName,
          embedded: true,
        );
      case ProjectOverviewSection.exceptionReport:
        return ExceptionReportPage(
          projectId: widget.projectId,
          fallbackName: widget.fallbackName,
          embedded: true,
        );
      case ProjectOverviewSection.siteImages:
        return SiteImagesPage(
          projectId: widget.projectId,
          fallbackName: widget.fallbackName,
          embedded: true,
        );
    }
  }
}

class _HubChipRow extends StatelessWidget {
  const _HubChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: children.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) => children[index],
      ),
    );
  }
}

class _HubChoiceChip extends StatelessWidget {
  const _HubChoiceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    // Brand navy + white (not ColorScheme.primary): dark primary is light blue
    // and can wash out selected chip labels depending on ChipTheme defaults.
    const Color selectedFill = AppTheme.dataTableHeaderFill;
    const Color selectedFg = AppTheme.dataTableHeaderOnFill;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onSelected(),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 12,
        color: selected ? selectedFg : colors.onSurface,
      ),
      selectedColor: selectedFill,
      backgroundColor: AppPalette.of(context).fieldFill,
      side: BorderSide(
        color: selected
            ? selectedFill
            : colors.outlineVariant.withValues(alpha: 0.75),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _ScrollablePanel extends StatelessWidget {
  const _ScrollablePanel({required this.child, required this.onRefresh});

  final Widget child;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: <Widget>[child],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.projectId, required this.child});

  final String projectId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      color: AppPalette.of(context).cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Project ID: $projectId',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _PlaceholderPanel extends StatelessWidget {
  const _PlaceholderPanel({required this.projectId, required this.message});

  final String projectId;
  final String message;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: <Widget>[
        Material(
          color: AppPalette.of(context).cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            side: BorderSide(color: colors.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Project ID: $projectId',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
