import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_filter_section.dart';
import 'package:swr_pmis_mobile/src/core/widgets/paged_table_column.dart';
import 'package:swr_pmis_mobile/src/core/widgets/table_pagination_footer.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_filter_option.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_clear_button.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_field.dart';
import 'package:swr_pmis_mobile/src/features/utility_shifting/data/datasources/utility_shifting_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/utility_shifting/data/utility_shifting_export_file.dart';
import 'package:swr_pmis_mobile/src/features/utility_shifting/domain/utility_shifting_list.dart';
import 'package:swr_pmis_mobile/src/features/utility_shifting/presentation/providers/utility_shifting_provider.dart';
import 'package:swr_pmis_mobile/src/features/utility_shifting/presentation/widgets/utility_shifting_table.dart';

class UtilityShiftingListView extends ConsumerStatefulWidget {
  const UtilityShiftingListView({super.key});

  @override
  ConsumerState<UtilityShiftingListView> createState() =>
      _UtilityShiftingListViewState();
}

class _UtilityShiftingListViewState
    extends ConsumerState<UtilityShiftingListView> {
  final TextEditingController _search = TextEditingController();
  Timer? _searchDebounce;
  bool _exporting = false;
  bool _downloadingTemplate = false;
  bool _uploading = false;

  bool get _toolbarBusy =>
      _exporting || _downloadingTemplate || _uploading;

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
      ref.read(utilityShiftingControllerProvider.notifier).setSearch(value);
    });
  }

  Future<void> _retry() {
    return ref.read(utilityShiftingControllerProvider.notifier).load();
  }

  Future<void> _onAdd() async {
    await AppDialog.show(
      context,
      title: 'Add Utility Shifting',
      message: 'Add utility shifting will be available later.',
    );
  }

  Future<void> _onEdit(UtilityShiftingRow row) async {
    await AppDialog.show(
      context,
      title: 'Edit Utility Shifting',
      message: row.utilityShiftingId.isEmpty
          ? 'Edit utility shifting will be available later.'
          : 'Edit utility shifting ${row.utilityShiftingId} will be available later.',
    );
  }

  Future<void> _onUpload() async {
    if (_toolbarBusy || !mounted) {
      return;
    }
    final FilePickerResult? picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['xlsx', 'xls'],
      withData: false,
    );
    final String? path = picked?.files.single.path;
    if (path == null || path.isEmpty) {
      return;
    }
    final String lower = path.toLowerCase();
    if (!lower.endsWith('.xlsx') && !lower.endsWith('.xls')) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.warning,
        title: 'Upload',
        message:
            'Please select an Excel utility shifting template (.xlsx or .xls).',
      );
      return;
    }
    setState(() => _uploading = true);
    try {
      final String message = await ref
          .read(utilityShiftingRemoteDataSourceProvider)
          .uploadUtilityShifting(filePath: path);
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.success,
        title: 'Upload',
        message: message,
      );
      await Future.wait<void>(<Future<void>>[
        ref.read(utilityShiftingControllerProvider.notifier).load(),
        ref.read(utilityShiftingUploadsControllerProvider.notifier).load(),
      ]);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Upload',
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : error is StateError
            ? error.message
            : error.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  Future<void> _onDownloadTemplate(BuildContext origin) async {
    if (_toolbarBusy || !mounted) {
      return;
    }
    final Rect originRect = _shareOrigin(origin);
    setState(() => _downloadingTemplate = true);
    try {
      final ({Uint8List bytes, String fileName}) file = await ref
          .read(utilityShiftingRemoteDataSourceProvider)
          .downloadTemplate();
      if (!mounted) {
        return;
      }
      final String safeName = file.fileName
          .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')
          .trim();
      final String name = safeName.isEmpty
          ? 'utility-shifting-template.xlsx'
          : safeName;
      final Directory directory = await getTemporaryDirectory();
      final File local = File('${directory.path}/$name');
      await local.writeAsBytes(file.bytes, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[
            XFile(
              local.path,
              name: name,
              mimeType:
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            ),
          ],
          sharePositionOrigin: originRect,
        ),
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Download',
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : 'Unable to download the utility shifting template.',
      );
    } finally {
      if (mounted) {
        setState(() => _downloadingTemplate = false);
      }
    }
  }

  Future<void> _onExport(BuildContext origin) async {
    if (_toolbarBusy || !mounted) {
      return;
    }
    final UtilityShiftingState current = ref.read(
      utilityShiftingControllerProvider,
    );
    if (current.loading || current.error != null) {
      return;
    }
    final List<UtilityShiftingRow> rows = current.snapshot.rows;
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
      await shareUtilityShiftingXlsx(
        rows: rows,
        sharePositionOrigin: originRect,
      );
    } on Object {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Export',
        message: 'Unable to export utility shifting records.',
      );
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final UtilityShiftingState state = ref.watch(
      utilityShiftingControllerProvider,
    );
    final bool failed = state.error != null;
    final List<UtilityShiftingRow> rows = failed
        ? const <UtilityShiftingRow>[]
        : state.snapshot.rows;
    final int total = failed ? 0 : state.snapshot.total;
    final int pageSize = state.query.pageSize < 1
        ? 10
        : state.query.pageSize;
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
          RfiContentLoader(loading: state.loading || _toolbarBusy),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    alignment: WrapAlignment.end,
                    children: <Widget>[
                      _ToolbarIcon(
                        tooltip: 'Download template',
                        icon: Icons.download_rounded,
                        busy: _downloadingTemplate,
                        onPressed: _toolbarBusy
                            ? null
                            : () => _onDownloadTemplate(context),
                      ),
                      _ToolbarIcon(
                        tooltip: 'Upload',
                        icon: Icons.upload_rounded,
                        busy: _uploading,
                        onPressed: _toolbarBusy ? null : _onUpload,
                      ),
                      _ToolbarIcon(
                        tooltip: 'Add',
                        icon: Icons.add_rounded,
                        onPressed: _toolbarBusy ? null : _onAdd,
                      ),
                      _ToolbarIcon(
                        tooltip: 'Export',
                        icon: Icons.table_view_rounded,
                        busy: _exporting,
                        onPressed: state.loading || failed || _toolbarBusy
                            ? null
                            : () => _onExport(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppFilterSection(
                  activeCount: AppFilterSection.countActive(<String?>[
                    state.query.locationName,
                    state.query.utilityCategory,
                    state.query.utilityType,
                    state.query.status,
                  ]),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _FilterBar(
                        state: state,
                        enabled: !state.loading && !_toolbarBusy,
                        onLocation: (String? value) {
                          ref
                              .read(utilityShiftingControllerProvider.notifier)
                              .selectLocation(value ?? '');
                        },
                        onCategory: (String? value) {
                          ref
                              .read(utilityShiftingControllerProvider.notifier)
                              .selectCategory(value ?? '');
                        },
                        onUtilityType: (String? value) {
                          ref
                              .read(utilityShiftingControllerProvider.notifier)
                              .selectUtilityType(value ?? '');
                        },
                        onStatus: (String? value) {
                          ref
                              .read(utilityShiftingControllerProvider.notifier)
                              .selectStatus(value ?? '');
                        },
                        onClear: () {
                          ref
                              .read(utilityShiftingControllerProvider.notifier)
                              .clearFilters();
                        },
                      ),
                      if (showSearch) ...<Widget>[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _search,
                          textInputAction: TextInputAction.search,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Search',
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
              message: 'No utility shifting records found.',
              onRetry: _retry,
            )
          : UtilityShiftingTable(rows: rows, onEdit: _onEdit),
      footer: showFooter
          ? TablePaginationFooter(
              label: label,
              total: total,
              page: page,
              pageCount: pageCount,
              pageSize: pageSize,
              onPageChanged: (int next) {
                ref
                    .read(utilityShiftingControllerProvider.notifier)
                    .setPage(next);
              },
              onPageSizeChanged: (int size) {
                ref
                    .read(utilityShiftingControllerProvider.notifier)
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
    required this.onLocation,
    required this.onCategory,
    required this.onUtilityType,
    required this.onStatus,
    required this.onClear,
  });

  final UtilityShiftingState state;
  final bool enabled;
  final ValueChanged<String?> onLocation;
  final ValueChanged<String?> onCategory;
  final ValueChanged<String?> onUtilityType;
  final ValueChanged<String?> onStatus;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final UtilityShiftingListQuery query = state.query;
    final UtilityShiftingListSnapshot snapshot = state.snapshot;
    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: RfiFilterGrid(
          children: <Widget>[
            _field(
              label: 'Location',
              options: snapshot.locations,
              selected: query.locationName,
              onChanged: onLocation,
            ),
            _field(
              label: 'Utility Category',
              options: snapshot.categories,
              selected: query.utilityCategory,
              onChanged: onCategory,
            ),
            _field(
              label: 'Utility Type',
              options: snapshot.utilityTypes,
              selected: query.utilityType,
              onChanged: onUtilityType,
            ),
            _field(
              label: 'Status',
              options: snapshot.statuses,
              selected: query.status,
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
    required List<UtilityShiftingOption> options,
    required String selected,
    required ValueChanged<String?> onChanged,
  }) {
    final String? selectedId = selected.isEmpty ? null : selected;
    return RfiFilterField(
      label: label,
      value: _label(options, selectedId),
      options: <RfiFilterOption>[
        for (final UtilityShiftingOption option in options)
          RfiFilterOption(id: option.value, label: option.label),
      ],
      selectedId: selectedId,
      onClear: selectedId == null ? null : () => onChanged(null),
      onPick: (RfiFilterOption option) => onChanged(option.id),
    );
  }
}

String? _label(List<UtilityShiftingOption> options, String? id) {
  if (id == null) {
    return null;
  }
  for (final UtilityShiftingOption option in options) {
    if (option.value == id) {
      return option.label;
    }
  }
  return id;
}

class _ToolbarIcon extends StatelessWidget {
  const _ToolbarIcon({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.busy = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    return IconButton(
      tooltip: tooltip,
      onPressed: busy ? null : onPressed,
      style: IconButton.styleFrom(
        foregroundColor: accent,
        backgroundColor: accent.withValues(alpha: 0.12),
        disabledForegroundColor: accent.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          side: BorderSide(color: accent.withValues(alpha: 0.55)),
        ),
      ),
      icon: busy
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: accent),
            )
          : Icon(icon, size: 20),
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
