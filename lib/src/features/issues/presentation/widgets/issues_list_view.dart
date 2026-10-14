import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/paging/table_page.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/core/widgets/paged_table_column.dart';
import 'package:swr_pmis_mobile/src/core/widgets/table_pagination_footer.dart';
import 'package:swr_pmis_mobile/src/features/issues/data/issue_export_file.dart';
import 'package:swr_pmis_mobile/src/features/issues/domain/issue_list.dart';
import 'package:swr_pmis_mobile/src/features/issues/presentation/pages/add_issue_form_page.dart';
import 'package:swr_pmis_mobile/src/features/issues/presentation/providers/issues_provider.dart';
import 'package:swr_pmis_mobile/src/features/issues/presentation/widgets/issues_table.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_filter_option.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_clear_button.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_field.dart';

class IssuesListView extends ConsumerStatefulWidget {
  const IssuesListView({super.key});

  @override
  ConsumerState<IssuesListView> createState() => _IssuesListViewState();
}

class _IssuesListViewState extends ConsumerState<IssuesListView> {
  final TextEditingController _search = TextEditingController();
  int _pageSize = TablePage.defaultPageSize;
  int _page = 1;
  bool _exporting = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _resetPage() {
    setState(() => _page = 1);
  }

  void _selectContract(String? value) {
    _resetPage();
    ref.read(issuesControllerProvider.notifier).selectContract(value ?? '');
  }

  void _selectHod(String? value) {
    _resetPage();
    ref.read(issuesControllerProvider.notifier).selectHod(value ?? '');
  }

  void _selectDepartment(String? value) {
    _resetPage();
    ref.read(issuesControllerProvider.notifier).selectDepartment(value ?? '');
  }

  void _selectCategory(String? value) {
    _resetPage();
    ref.read(issuesControllerProvider.notifier).selectCategory(value ?? '');
  }

  void _selectStatus(String? value) {
    _resetPage();
    ref.read(issuesControllerProvider.notifier).selectStatus(value ?? '');
  }

  void _clearFilters() {
    _resetPage();
    ref.read(issuesControllerProvider.notifier).clearFilters();
  }

  Future<void> _retry() {
    _resetPage();
    return ref.read(issuesControllerProvider.notifier).load();
  }

  Future<void> _onAdd() async {
    final Object? saved = await context.push<Object?>(
      AddIssueFormPage.routePath,
    );
    if (!mounted || saved != true) {
      return;
    }
    await _retry();
  }

  Future<void> _onEdit(IssueRow _) async {
    await AppDialog.show(
      context,
      variant: AppDialogVariant.info,
      title: 'Edit',
      message: 'Edit will be added next.',
    );
  }

  Future<void> _onExport(BuildContext origin) async {
    if (_exporting || !mounted) {
      return;
    }
    final IssuesState current = ref.read(issuesControllerProvider);
    if (current.loading || current.error != null) {
      return;
    }
    final List<IssueRow> rows = current.snapshot.issues
        .where((IssueRow row) => _matches(row, _search.text))
        .toList(growable: false);
    if (rows.isEmpty) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.info,
        title: 'Export',
        message: 'There are no records to export.',
      );
      return;
    }
    final Rect originRect = _shareOrigin(origin);
    setState(() => _exporting = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) {
        return;
      }
      await shareIssueXlsx(rows: rows, sharePositionOrigin: originRect);
    } on Object {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Export',
        message: 'Unable to export issues.',
      );
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final IssuesState state = ref.watch(issuesControllerProvider);
    final bool failed = state.error != null;
    final List<IssueRow> loaded = failed
        ? const <IssueRow>[]
        : state.snapshot.issues;
    final List<IssueRow> visible = loaded
        .where((IssueRow row) => _matches(row, _search.text))
        .toList(growable: false);
    final TablePage<IssueRow> tablePage = TablePage.slice(
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
          RfiContentLoader(loading: state.loading || _exporting),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
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
                      _AddButton(onPressed: _exporting ? null : _onAdd),
                      _ExportButton(
                        busy: _exporting,
                        onPressed: state.loading || failed ? null : _onExport,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _FilterBar(
                  state: state,
                  enabled: !state.loading && !_exporting,
                  onContract: _selectContract,
                  onHod: _selectHod,
                  onDepartment: _selectDepartment,
                  onCategory: _selectCategory,
                  onStatus: _selectStatus,
                  onClear: _clearFilters,
                ),
                if (showSearch) ...<Widget>[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    onChanged: (_) => _resetPage(),
                    decoration: InputDecoration(
                      hintText: 'Search',
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
          : state.loading && loaded.isEmpty
          ? const SizedBox.shrink()
          : visible.isEmpty
          ? _message(
              message: loaded.isEmpty
                  ? 'No issues found.'
                  : 'No matching issues.',
              onRetry: loaded.isEmpty ? _retry : null,
            )
          : IssuesTable(rows: tablePage.items, onEdit: _onEdit),
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

  Widget _message({required String message, required VoidCallback? onRetry}) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double minHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 0;
        return _FillScroll(
          minHeight: minHeight,
          child: _StatusMessage(message: message, onRetry: onRetry),
        );
      },
    );
  }

  bool _matches(IssueRow row, String query) {
    final String needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return true;
    }
    return issueExportCells(
      row,
    ).any((String part) => part.toLowerCase().contains(needle));
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.state,
    required this.enabled,
    required this.onContract,
    required this.onHod,
    required this.onDepartment,
    required this.onCategory,
    required this.onStatus,
    required this.onClear,
  });

  final IssuesState state;
  final bool enabled;
  final ValueChanged<String?> onContract;
  final ValueChanged<String?> onHod;
  final ValueChanged<String?> onDepartment;
  final ValueChanged<String?> onCategory;
  final ValueChanged<String?> onStatus;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final IssueListQuery query = state.query;
    final IssueListSnapshot snapshot = state.snapshot;
    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: RfiFilterGrid(
          children: <Widget>[
            _field(
              label: 'Select Contract',
              options: snapshot.contracts,
              selected: query.contractId,
              onChanged: onContract,
            ),
            _field(
              label: 'Select HOD',
              options: snapshot.hods,
              selected: query.hodId,
              onChanged: onHod,
            ),
            _field(
              label: 'Select Department',
              options: snapshot.departments,
              selected: query.departmentId,
              onChanged: onDepartment,
            ),
            _field(
              label: 'Select Category',
              options: snapshot.categories,
              selected: query.categoryId,
              onChanged: onCategory,
            ),
            _field(
              label: 'Select Status',
              options: snapshot.statuses,
              selected: query.statusId,
              onChanged: onStatus,
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
    required List<IssueOption> options,
    required String selected,
    required ValueChanged<String?> onChanged,
  }) {
    final String? selectedId = selected.isEmpty ? null : selected;
    return RfiFilterField(
      label: label,
      emptyLabel: label,
      showLabel: false,
      value: _label(options, selectedId),
      options: <RfiFilterOption>[
        for (final IssueOption option in options)
          RfiFilterOption(id: option.value, label: option.label),
      ],
      selectedId: selectedId,
      onClear: selectedId == null ? null : () => onChanged(null),
      onPick: (RfiFilterOption option) => onChanged(option.id),
    );
  }
}

String? _label(List<IssueOption> options, String? id) {
  if (id == null) {
    return null;
  }
  for (final IssueOption option in options) {
    if (option.value == id) {
      return option.label;
    }
  }
  return id;
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: const Size(0, AppTheme.fieldHeight),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppTheme.cardRadius)),
        ),
      ),
      onPressed: onPressed,
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text('Add'),
    );
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({required this.busy, required this.onPressed});

  final bool busy;
  final void Function(BuildContext context)? onPressed;

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
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
      onPressed: busy || onPressed == null ? null : () => onPressed!(context),
      icon: busy
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: accent),
            )
          : const Icon(Icons.download_rounded, size: 18),
      label: const Text('Export'),
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

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
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
