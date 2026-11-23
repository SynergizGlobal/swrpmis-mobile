import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/paging/table_page.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_fullscreen_loader.dart';
import 'package:swr_pmis_mobile/src/core/widgets/table_pagination_footer.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/entities/site_photo_row.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/utils/site_photos_filters.dart';
import 'package:swr_pmis_mobile/src/features/works/presentation/pages/project_overview_page.dart';
import 'package:swr_pmis_mobile/src/features/works/presentation/providers/works_providers.dart';
import 'package:swr_pmis_mobile/src/features/works/presentation/widgets/site_photos_compare_dialog.dart';
import 'package:swr_pmis_mobile/src/features/works/presentation/widgets/site_photos_preview_dialog.dart';

class SiteImagesPage extends ConsumerStatefulWidget {
  const SiteImagesPage({
    super.key,
    required this.projectId,
    required this.fallbackName,
    this.embedded = false,
  });

  static const String routeName = 'works-site-images';
  static const String routePath = '/works/site-images/:projectId';

  final String projectId;
  final String fallbackName;

  /// When true, renders gallery content only (no Scaffold/AppBar) for hub embedding.
  final bool embedded;

  @override
  ConsumerState<SiteImagesPage> createState() => _SiteImagesPageState();
}

class _SiteImagesPageState extends ConsumerState<SiteImagesPage> {
  int _page = 1;
  int _pageSize = TablePage.defaultPageSize;
  SitePhotosFilterState _filters = SitePhotosFilterState.cleared;
  bool _compareMode = false;
  final List<SitePhotoRow> _selected = <SitePhotoRow>[];

  static const int _maxCompare = 2;

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

  void _clearFilters() {
    setState(() {
      _filters = SitePhotosFilterState.cleared;
      _page = 1;
    });
  }

  void _applyFilters(SitePhotosFilterState next) {
    setState(() {
      _filters = next;
      _page = 1;
    });
  }

  void _enterCompareMode() {
    setState(() {
      _compareMode = true;
      _selected.clear();
    });
  }

  void _cancelCompareMode() {
    setState(() {
      _compareMode = false;
      _selected.clear();
    });
  }

  void _toggleSelect(SitePhotoRow row) {
    setState(() {
      final int index = _selected.indexWhere(
        (SitePhotoRow item) => item.selectionKey == row.selectionKey,
      );
      if (index >= 0) {
        _selected.removeAt(index);
        return;
      }
      if (_selected.length >= _maxCompare) {
        return;
      }
      _selected.add(row);
    });
  }

  bool _isSelected(SitePhotoRow row) {
    return _selected.any(
      (SitePhotoRow item) => item.selectionKey == row.selectionKey,
    );
  }

  Future<void> _openCompare() async {
    if (_selected.length != _maxCompare) {
      return;
    }
    await showSitePhotosCompareDialog(
      context: context,
      left: _selected[0],
      right: _selected[1],
    );
  }

  SitePhotosFilterState _normalizeFilters(
    List<SitePhotoRow> allRows,
    SitePhotosFilterState state,
  ) {
    final List<String> sections =
        SitePhotosFilters.sectionOptions(allRows, state);
    final List<String> structureTypes =
        SitePhotosFilters.structureTypeOptions(allRows, state);
    final List<String> structures =
        SitePhotosFilters.structureOptions(allRows, state);
    final List<String> components =
        SitePhotosFilters.structureComponentOptions(allRows, state);
    final List<String> componentIds =
        SitePhotosFilters.componentIdOptions(allRows, state);

    String section = SitePhotosFilters.sheetValue(sections, state.section);
    String structureType = SitePhotosFilters.sheetValue(
      structureTypes,
      state.structureType,
    );
    String structure =
        SitePhotosFilters.sheetValue(structures, state.structure);
    String structureComponent = SitePhotosFilters.sheetValue(
      components,
      state.structureComponent,
    );
    String componentId = SitePhotosFilters.sheetValue(
      componentIds,
      state.componentId,
    );

    if (structureType == SitePhotosFilters.all) {
      structure = SitePhotosFilters.all;
      structureComponent = SitePhotosFilters.all;
      componentId = SitePhotosFilters.all;
    } else if (structure == SitePhotosFilters.all) {
      structureComponent = SitePhotosFilters.all;
      componentId = SitePhotosFilters.all;
    } else if (structureComponent == SitePhotosFilters.all) {
      componentId = SitePhotosFilters.all;
    }

    final ({DateTime? earliest, DateTime? latest}) bounds =
        SitePhotosFilters.availableDateBounds(allRows);
    final DateTime? fromDate = SitePhotosFilters.clampToAvailable(
      state.fromDate,
      earliest: bounds.earliest,
      latest: bounds.latest,
    );
    final DateTime? toDate = SitePhotosFilters.clampToAvailable(
      state.toDate,
      earliest: bounds.earliest,
      latest: bounds.latest,
    );

    return state.copyWith(
      section: section,
      structureType: structureType,
      structure: structure,
      structureComponent: structureComponent,
      componentId: componentId,
      fromDate: fromDate,
      toDate: toDate,
      clearFromDate: state.fromDate != null && fromDate == null,
      clearToDate: state.toDate != null && toDate == null,
    );
  }

  Future<void> _pickDate({
    required bool from,
    required List<SitePhotoRow> allRows,
  }) async {
    final ({DateTime? earliest, DateTime? latest}) bounds =
        SitePhotosFilters.availableDateBounds(allRows);
    final DateTime? earliest = bounds.earliest;
    final DateTime? latest = bounds.latest;
    if (earliest == null || latest == null) {
      return;
    }
    final DateTime first = DateUtils.dateOnly(earliest);
    final DateTime last = DateUtils.dateOnly(latest);
    DateTime initial = from
        ? (_filters.fromDate ?? first)
        : (_filters.toDate ?? _filters.fromDate ?? last);
    initial = DateUtils.dateOnly(initial);
    if (initial.isBefore(first)) {
      initial = first;
    }
    if (initial.isAfter(last)) {
      initial = last;
    }
    // Material DatePicker disables "Today" when today is outside [first, last].
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked == null) {
      return;
    }
    final DateTime day = DateUtils.dateOnly(picked);
    _applyFilters(
      from
          ? _filters.copyWith(fromDate: day)
          : _filters.copyWith(toDate: day),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<SitePhotoRow>> photosAsync = ref.watch(
      sitePhotosProvider(widget.projectId),
    );

    final Widget body = photosAsync.when(
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
                    ref.invalidate(sitePhotosProvider(widget.projectId)),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (List<SitePhotoRow> rows) => _content(context, rows),
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => _goBack(context)),
        title: const Text('Site Photos'),
      ),
      body: body,
    );
  }

  Widget _content(BuildContext context, List<SitePhotoRow> allRows) {
    final SitePhotosFilterState activeFilters =
        _normalizeFilters(allRows, _filters);
    if (activeFilters.section != _filters.section ||
        activeFilters.structureType != _filters.structureType ||
        activeFilters.structure != _filters.structure ||
        activeFilters.structureComponent != _filters.structureComponent ||
        activeFilters.componentId != _filters.componentId ||
        activeFilters.fromDate != _filters.fromDate ||
        activeFilters.toDate != _filters.toDate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() => _filters = activeFilters);
      });
    }

    final List<SitePhotoRow> filtered =
        SitePhotosFilters.apply(allRows, activeFilters);
    final TablePage<SitePhotoRow> page = TablePage.slice(
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

    final String emptyMessage = allRows.isEmpty
        ? 'No site photos available for this project.'
        : 'No site photos match the selected filters.';

    // Parent (Scaffold body / hub Expanded) must give a finite height.
    // Non-flex Column children still see maxHeight: Infinity — header must be
    // intrinsic only (no Expanded / vertical viewport / horizontal viewport).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: _header(context, allRows: allRows),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text(emptyMessage))
              : Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  child: _tableArea(
                    context,
                    allRows: allRows,
                    pageRows: page.items,
                    filters: activeFilters,
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

  Widget _header(
    BuildContext context, {
    required List<SitePhotoRow> allRows,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final bool hasActiveFilters = _filters.hasActiveFilters;
    final int selectedCount = _selected.length;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Site Photos',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                children: <TextSpan>[
                  const TextSpan(text: 'Project ID : '),
                  TextSpan(
                    text: widget.projectId,
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (_compareMode) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                '$selectedCount / $_maxCompare selected',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
            ],
            const SizedBox(height: 10),
            // Wrap (not horizontal SingleChildScrollView): header is a non-flex
            // Column child and receives maxHeight: Infinity — a horizontal
            // viewport cannot size its cross-axis there (Card Material hasSize).
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                if (!_compareMode)
                  FilledButton.icon(
                    onPressed: allRows.isEmpty ? null : _enterCompareMode,
                    icon: const Icon(Icons.compare_arrows_rounded, size: 18),
                    label: const Text('Compare Photos'),
                  )
                else ...<Widget>[
                  FilledButton.icon(
                    onPressed:
                        selectedCount == _maxCompare ? _openCompare : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: selectedCount == _maxCompare
                          ? const Color(0xFF2E7D32)
                          : null,
                    ),
                    icon: const Icon(Icons.compare_rounded, size: 18),
                    label: const Text('Compare Selected'),
                  ),
                  OutlinedButton(
                    onPressed: _cancelCompareMode,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.error,
                      side: BorderSide(color: cs.error),
                    ),
                    child: const Text('Cancel Compare'),
                  ),
                ],
                OutlinedButton.icon(
                  onPressed: hasActiveFilters ? _clearFilters : null,
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                  label: const Text('Clear Filters'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableArea(
    BuildContext context, {
    required List<SitePhotoRow> allRows,
    required List<SitePhotoRow> pageRows,
    required SitePhotosFilterState filters,
  }) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double selectWidth = _compareMode ? _Col.select : 0;
    final double totalWidth = _Col.totalWidth + selectWidth;

    final List<String> sections =
        SitePhotosFilters.sectionOptions(allRows, filters);
    final List<String> structureTypes =
        SitePhotosFilters.structureTypeOptions(allRows, filters);
    final List<String> structures =
        SitePhotosFilters.structureOptions(allRows, filters);
    final List<String> components =
        SitePhotosFilters.structureComponentOptions(allRows, filters);
    final List<String> componentIds =
        SitePhotosFilters.componentIdOptions(allRows, filters);

    final bool structureEnabled =
        filters.structureType != SitePhotosFilters.all;
    final bool componentEnabled =
        structureEnabled && filters.structure != SitePhotosFilters.all;
    final bool componentIdEnabled = componentEnabled &&
        filters.structureComponent != SitePhotosFilters.all;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // Expanded parent → finite height. Pin that height on the wide child so
          // horizontal scroll + vertical ListView both get bounded constraints.
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: totalWidth,
              height: constraints.maxHeight,
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  _tableHeader(context, selectWidth: selectWidth),
                  _filterRow(
                    context,
                    allRows: allRows,
                    selectWidth: selectWidth,
                    sections: sections,
                    structureTypes: structureTypes,
                    structures: structures,
                    components: components,
                    componentIds: componentIds,
                    filters: filters,
                    structureEnabled: structureEnabled,
                    componentEnabled: componentEnabled,
                    componentIdEnabled: componentIdEnabled,
                  ),
                  for (int index = 0; index < pageRows.length; index++) ...<Widget>[
                    Divider(
                      height: 1,
                      thickness: 0.6,
                      color: cs.outlineVariant.withValues(alpha: 0.45),
                    ),
                    _tableRow(
                      context,
                      pageRows[index],
                      selectWidth: selectWidth,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tableHeader(BuildContext context, {required double selectWidth}) {
    return Container(
      color: AppTheme.dataTableHeaderFill,
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: _Col.horizontalPadding / 2,
      ),
      child: Row(
        children: <Widget>[
          if (selectWidth > 0)
            _headerCell('SELECT', selectWidth, centered: true),
          _headerCell('SECTION', _Col.section),
          _headerCell('DATE RANGE', _Col.date),
          _headerCell('STRUCTURE TYPE', _Col.structureType),
          _headerCell('STRUCTURE', _Col.structure),
          _headerCell('STRUCTURE COMPONENT', _Col.structureComponent),
          _headerCell('COMPONENT ID', _Col.componentId),
          _headerCell('PHOTOS COUNT', _Col.photosCount, centered: true),
          _headerCell('VIEW', _Col.view, centered: true),
        ],
      ),
    );
  }

  Widget _headerCell(String label, double width, {bool centered = false}) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        textAlign: centered ? TextAlign.center : TextAlign.left,
        style: const TextStyle(
          color: AppTheme.dataTableHeaderOnFill,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _filterRow(
    BuildContext context, {
    required List<SitePhotoRow> allRows,
    required double selectWidth,
    required List<String> sections,
    required List<String> structureTypes,
    required List<String> structures,
    required List<String> components,
    required List<String> componentIds,
    required SitePhotosFilterState filters,
    required bool structureEnabled,
    required bool componentEnabled,
    required bool componentIdEnabled,
  }) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String fromLabel = filters.fromDate == null
        ? 'dd/mm/yyyy'
        : DateFormat('dd/MM/yyyy').format(filters.fromDate!);
    final String toLabel = filters.toDate == null
        ? 'dd/mm/yyyy'
        : DateFormat('dd/MM/yyyy').format(filters.toDate!);

    return Container(
      color: cs.primaryContainer.withValues(alpha: 0.35),
      padding: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: _Col.horizontalPadding / 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (selectWidth > 0) SizedBox(width: selectWidth),
          SizedBox(
            width: _Col.section,
            child: _InlineDropdown(
              value: SitePhotosFilters.sheetValue(sections, filters.section),
              options: sections,
              onChanged: (String value) =>
                  _applyFilters(filters.copyWith(section: value)),
            ),
          ),
          SizedBox(
            width: _Col.date,
            child: Column(
              children: <Widget>[
                _DateChip(
                  label: fromLabel,
                  onTap: () => _pickDate(from: true, allRows: allRows),
                  onClear: filters.fromDate == null
                      ? null
                      : () => _applyFilters(filters.copyWith(clearFromDate: true)),
                ),
                const SizedBox(height: 4),
                _DateChip(
                  label: toLabel,
                  onTap: () => _pickDate(from: false, allRows: allRows),
                  onClear: filters.toDate == null
                      ? null
                      : () => _applyFilters(filters.copyWith(clearToDate: true)),
                ),
              ],
            ),
          ),
          SizedBox(
            width: _Col.structureType,
            child: _InlineDropdown(
              value: SitePhotosFilters.sheetValue(
                structureTypes,
                filters.structureType,
              ),
              options: structureTypes,
              onChanged: (String value) => _applyFilters(
                filters.copyWith(
                  structureType: value,
                  structure: SitePhotosFilters.all,
                  structureComponent: SitePhotosFilters.all,
                  componentId: SitePhotosFilters.all,
                ),
              ),
            ),
          ),
          SizedBox(
            width: _Col.structure,
            child: _InlineDropdown(
              value: SitePhotosFilters.sheetValue(
                structures,
                filters.structure,
              ),
              options: structures,
              enabled: structureEnabled,
              onChanged: (String value) => _applyFilters(
                filters.copyWith(
                  structure: value,
                  structureComponent: SitePhotosFilters.all,
                  componentId: SitePhotosFilters.all,
                ),
              ),
            ),
          ),
          SizedBox(
            width: _Col.structureComponent,
            child: _InlineDropdown(
              value: SitePhotosFilters.sheetValue(
                components,
                filters.structureComponent,
              ),
              options: components,
              enabled: componentEnabled,
              onChanged: (String value) => _applyFilters(
                filters.copyWith(
                  structureComponent: value,
                  componentId: SitePhotosFilters.all,
                ),
              ),
            ),
          ),
          SizedBox(
            width: _Col.componentId,
            child: _InlineDropdown(
              value: SitePhotosFilters.sheetValue(
                componentIds,
                filters.componentId,
              ),
              options: componentIds,
              enabled: componentIdEnabled,
              onChanged: (String value) =>
                  _applyFilters(filters.copyWith(componentId: value)),
            ),
          ),
          SizedBox(width: _Col.photosCount),
          SizedBox(width: _Col.view),
        ],
      ),
    );
  }

  Widget _tableRow(
    BuildContext context,
    SitePhotoRow row, {
    required double selectWidth,
  }) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool selected = _isSelected(row);
    final bool selectionDisabled =
        _compareMode && !selected && _selected.length >= _maxCompare;

    return Material(
      color: selected
          ? cs.primaryContainer.withValues(alpha: 0.28)
          : cs.surfaceContainerHighest.withValues(alpha: 0.18),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: _Col.horizontalPadding / 2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            if (selectWidth > 0)
              SizedBox(
                width: selectWidth,
                child: Center(
                  child: Checkbox(
                    value: selected,
                    onChanged: selectionDisabled
                        ? null
                        : (_) => _toggleSelect(row),
                  ),
                ),
              ),
            _textCell(row.section, width: _Col.section),
            _textCell(row.displayDate, width: _Col.date),
            _textCell(row.structureType, width: _Col.structureType),
            _textCell(
              row.structure,
              width: _Col.structure,
              weight: FontWeight.w600,
            ),
            _textCell(
              row.structureComponent,
              width: _Col.structureComponent,
            ),
            _textCell(row.componentId, width: _Col.componentId),
            SizedBox(
              width: _Col.photosCount,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.75),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${row.photosCount}',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: _Col.view,
              child: Center(
                child: FilledButton(
                  onPressed: row.hasPhotos
                      ? () => showSitePhotosPreviewDialog(
                            context: context,
                            row: row,
                          )
                      : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(92, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text(
                    'View Photos',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textCell(
    String value, {
    required double width,
    FontWeight weight = FontWeight.w500,
  }) {
    return SizedBox(
      width: width,
      child: Text(
        value,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, fontWeight: weight, height: 1.25),
      ),
    );
  }
}

class _InlineDropdown extends StatelessWidget {
  const _InlineDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
    this.enabled = true,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InputDecorator(
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          border: OutlineInputBorder(),
          filled: true,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            isDense: true,
            value: options.contains(value) ? value : SitePhotosFilters.all,
            items: options
                .map(
                  (String option) => DropdownMenuItem<String>(
                    value: option,
                    child: Text(
                      option,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                )
                .toList(),
            onChanged: enabled
                ? (String? next) {
                    if (next != null) {
                      onChanged(next);
                    }
                  }
                : null,
          ),
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              children: <Widget>[
                const Icon(Icons.calendar_today_rounded, size: 12),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                if (onClear != null)
                  InkWell(
                    onTap: onClear,
                    child: const Icon(Icons.close_rounded, size: 14),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Col {
  static const double select = 56;
  static const double section = 128;
  static const double date = 118;
  static const double structureType = 120;
  static const double structure = 200;
  static const double structureComponent = 140;
  static const double componentId = 128;
  static const double photosCount = 88;
  static const double view = 112;
  static const double horizontalPadding = 20;

  static double get totalWidth =>
      section +
      date +
      structureType +
      structure +
      structureComponent +
      componentId +
      photosCount +
      view +
      horizontalPadding;
}
