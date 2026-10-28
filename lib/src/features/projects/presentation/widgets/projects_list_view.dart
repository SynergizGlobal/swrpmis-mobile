import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/paging/table_page.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_filter_section.dart';
import 'package:swr_pmis_mobile/src/core/widgets/paged_table_column.dart';
import 'package:swr_pmis_mobile/src/core/widgets/table_pagination_footer.dart';
import 'package:swr_pmis_mobile/src/features/projects/data/datasources/project_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/projects/data/project_export_file.dart';
import 'package:swr_pmis_mobile/src/features/projects/domain/project_list.dart';
import 'package:swr_pmis_mobile/src/features/projects/presentation/pages/add_project_form_page.dart';
import 'package:swr_pmis_mobile/src/features/projects/presentation/providers/projects_provider.dart';
import 'package:swr_pmis_mobile/src/features/projects/presentation/widgets/projects_table.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_filter_option.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_clear_button.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_field.dart';

class ProjectsListView extends ConsumerStatefulWidget {
  const ProjectsListView({super.key});

  @override
  ConsumerState<ProjectsListView> createState() => _ProjectsListViewState();
}

class _ProjectsListViewState extends ConsumerState<ProjectsListView> {
  final TextEditingController _search = TextEditingController();
  Timer? _searchDebounce;
  int _pageSize = TablePage.defaultPageSize;
  int _page = 1;
  bool _exportingExcel = false;
  bool _exportingPdf = false;

  bool get _exporting => _exportingExcel || _exportingPdf;

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
      ref.read(projectsControllerProvider.notifier).setSearch(value);
    });
  }

  Future<void> _retry() {
    _resetPage();
    return ref.read(projectsControllerProvider.notifier).load();
  }

  Future<void> _onAdd() async {
    final Object? saved = await context.push<Object?>(
      AddProjectFormPage.routePath,
    );
    if (!mounted || saved != true) {
      return;
    }
    await _retry();
  }

  Future<void> _onEdit(ProjectRow row) async {
    final String id = row.projectId.trim();
    if (id.isEmpty) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.warning,
        title: 'Edit Project',
        message: 'This row has no project id to edit.',
      );
      return;
    }
    final Object? saved = await context.push<Object?>(
      AddProjectFormPage.location(projectId: id),
      extra: row,
    );
    if (!mounted || saved != true) {
      return;
    }
    await _retry();
  }

  Future<void> _onDelete(ProjectRow row) async {
    final String id = row.projectId.trim();
    if (id.isEmpty) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.warning,
        title: 'Delete Project',
        message: 'This row has no project id to delete.',
      );
      return;
    }
    final String label = row.projectName.trim().isEmpty
        ? id
        : row.projectName.trim();
    final bool confirmed = await AppDialog.confirm(
      context,
      title: 'Delete Project',
      message: 'Are you sure you want to delete $label?',
      primaryLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    try {
      final String message = await ref
          .read(projectRemoteDataSourceProvider)
          .deleteProject(id);
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.success,
        title: 'Delete Project',
        message: message,
      );
      if (!mounted) {
        return;
      }
      await _retry();
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Delete Project',
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : error is StateError
            ? error.message
            : error.toString(),
      );
    }
  }

  Future<void> _onExportExcel(BuildContext origin) async {
    await _export(
      origin: origin,
      excel: true,
      setBusy: (bool value) => _exportingExcel = value,
      share: shareProjectXlsx,
    );
  }

  Future<void> _onExportPdf(BuildContext origin) async {
    await _export(
      origin: origin,
      excel: false,
      setBusy: (bool value) => _exportingPdf = value,
      share: shareProjectPdf,
    );
  }

  Future<void> _export({
    required BuildContext origin,
    required bool excel,
    required void Function(bool value) setBusy,
    required Future<void> Function({
      required List<ProjectRow> rows,
      Rect? sharePositionOrigin,
    })
    share,
  }) async {
    if (_exporting || !mounted) {
      return;
    }
    final ProjectsState current = ref.read(projectsControllerProvider);
    if (current.loading || current.error != null) {
      return;
    }
    final List<ProjectRow> rows = current.snapshot.rows
        .where((ProjectRow row) => projectRowMatches(row, current.query))
        .toList(growable: false);
    if (rows.isEmpty) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.info,
        title: excel ? 'Excel' : 'PDF',
        message: 'There are no records to export.',
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
      await share(rows: rows, sharePositionOrigin: originRect);
    } on Object {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: excel ? 'Excel' : 'PDF',
        message: excel
            ? 'Unable to export projects to Excel.'
            : 'Unable to export projects to PDF.',
      );
    } finally {
      if (mounted) {
        setState(() => setBusy(false));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ProjectsState state = ref.watch(projectsControllerProvider);
    final bool failed = state.error != null;
    final List<ProjectRow> loaded = failed
        ? const <ProjectRow>[]
        : state.snapshot.rows;
    final List<ProjectRow> visible = loaded
        .where((ProjectRow row) => projectRowMatches(row, state.query))
        .toList(growable: false);
    final TablePage<ProjectRow> tablePage = TablePage.slice(
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
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      _ToolbarButton(
                        label: 'Add',
                        icon: Icons.add_rounded,
                        filled: true,
                        busy: false,
                        onPressed: _exporting ? null : _onAdd,
                      ),
                      _ToolbarButton(
                        label: 'Excel',
                        icon: Icons.cloud_download_rounded,
                        filled: false,
                        busy: _exportingExcel,
                        onPressed: state.loading || failed || _exporting
                            ? null
                            : () => _onExportExcel(context),
                      ),
                      _ToolbarButton(
                        label: 'PDF',
                        icon: Icons.cloud_download_rounded,
                        filled: false,
                        busy: _exportingPdf,
                        onPressed: state.loading || failed || _exporting
                            ? null
                            : () => _onExportPdf(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppFilterSection(
                  activeCount: AppFilterSection.countActive(<String?>[
                    state.query.projectStatus,
                    state.query.projectTypeId,
                  ]),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _FilterBar(
                        state: state,
                        enabled: !state.loading && !_exporting,
                        onStatus: (String? value) {
                          _resetPage();
                          ref
                              .read(projectsControllerProvider.notifier)
                              .selectStatus(value ?? '');
                        },
                        onType: (String? value) {
                          _resetPage();
                          ref
                              .read(projectsControllerProvider.notifier)
                              .selectType(value ?? '');
                        },
                        onClear: () {
                          _resetPage();
                          ref
                              .read(projectsControllerProvider.notifier)
                              .clearFilters();
                        },
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
          : state.loading && loaded.isEmpty
          ? const SizedBox.shrink()
          : tablePage.items.isEmpty
          ? _message(message: 'No projects found.', onRetry: _retry)
          : ProjectsTable(
              rows: tablePage.items,
              onEdit: _onEdit,
              onDelete: _onDelete,
            ),
      footer: showFooter
          ? TablePaginationFooter(
              label: tablePage.label,
              total: tablePage.total,
              page: tablePage.page,
              pageCount: tablePage.pageCount,
              pageSize: tablePage.pageSize,
              onPageChanged: (int next) {
                setState(() => _page = next);
              },
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
    required this.onStatus,
    required this.onType,
    required this.onClear,
  });

  final ProjectsState state;
  final bool enabled;
  final ValueChanged<String?> onStatus;
  final ValueChanged<String?> onType;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final ProjectListQuery query = state.query;
    final ProjectListSnapshot snapshot = state.snapshot;
    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: RfiFilterGrid(
          children: <Widget>[
            _field(
              label: 'Project Status',
              emptyLabel: 'Select Project Status',
              options: projectStatusOptions,
              selected: query.projectStatus,
              onChanged: onStatus,
            ),
            _field(
              label: 'Project Type',
              emptyLabel: 'Select Project Type',
              options: snapshot.projectTypes,
              selected: query.projectTypeId,
              onChanged: onType,
            ),
            RfiFilterClearButton(
              label: 'Clear Filter',
              onPressed: enabled ? onClear : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required String emptyLabel,
    required List<ProjectOption> options,
    required String selected,
    required ValueChanged<String?> onChanged,
  }) {
    final String? selectedId = selected.isEmpty ? null : selected;
    return RfiFilterField(
      label: label,
      value: _label(options, selectedId),
      emptyLabel: emptyLabel,
      options: <RfiFilterOption>[
        for (final ProjectOption option in options)
          RfiFilterOption(id: option.value, label: option.label),
      ],
      selectedId: selectedId,
      onClear: selectedId == null ? null : () => onChanged(null),
      onPick: (RfiFilterOption option) => onChanged(option.id),
    );
  }
}

String? _label(List<ProjectOption> options, String? id) {
  if (id == null || id.isEmpty) {
    return null;
  }
  for (final ProjectOption option in options) {
    if (option.value == id) {
      return option.label;
    }
  }
  return id;
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    final Widget iconWidget = busy
        ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: accent),
          )
        : Icon(icon, size: 18);
    if (filled) {
      return FilledButton.icon(
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: const Size(0, AppTheme.fieldHeight),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(AppTheme.cardRadius),
            ),
          ),
        ),
        onPressed: onPressed,
        icon: iconWidget,
        label: Text(label),
      );
    }
    return OutlinedButton.icon(
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: const WidgetStatePropertyAll<Size>(
          Size(0, AppTheme.fieldHeight),
        ),
        padding: const WidgetStatePropertyAll<EdgeInsets>(
          EdgeInsets.symmetric(horizontal: 12),
        ),
        foregroundColor: WidgetStateProperty.resolveWith<Color>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.disabled)) {
            return accent.withValues(alpha: 0.45);
          }
          return accent;
        }),
        backgroundColor: WidgetStateProperty.resolveWith<Color>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.disabled)) {
            return accent.withValues(alpha: 0.06);
          }
          return accent.withValues(alpha: 0.14);
        }),
        side: WidgetStateProperty.resolveWith<BorderSide>((
          Set<WidgetState> states,
        ) {
          final Color color = states.contains(WidgetState.disabled)
              ? accent.withValues(alpha: 0.45)
              : accent;
          return BorderSide(color: color, width: 1.5);
        }),
        textStyle: const WidgetStatePropertyAll<TextStyle>(
          TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        shape: const WidgetStatePropertyAll<OutlinedBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(AppTheme.cardRadius),
            ),
          ),
        ),
      ),
      onPressed: busy || onPressed == null ? null : onPressed,
      icon: iconWidget,
      label: Text(label),
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
