import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/core/widgets/paged_table_column.dart';
import 'package:swr_pmis_mobile/src/core/widgets/table_pagination_footer.dart';
import 'package:swr_pmis_mobile/src/features/rdso/data/datasources/rdso_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/rdso/data/rdso_file_actions.dart';
import 'package:swr_pmis_mobile/src/features/rdso/domain/rdso_list.dart';
import 'package:swr_pmis_mobile/src/features/rdso/presentation/providers/rdso_revision_provider.dart';
import 'package:swr_pmis_mobile/src/features/rdso/presentation/widgets/rdso_revision_table.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_filter_option.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_stored_file.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_field.dart';

class RdsoRevisionListView extends ConsumerStatefulWidget {
  const RdsoRevisionListView({super.key});

  @override
  ConsumerState<RdsoRevisionListView> createState() =>
      _RdsoRevisionListViewState();
}

class _RdsoRevisionListViewState extends ConsumerState<RdsoRevisionListView> {
  final TextEditingController _search = TextEditingController();
  RdsoDrawingRow? _busyRow;
  static final DateFormat _apiDate = DateFormat('yyyy-MM-dd');
  static final DateFormat _displayDate = DateFormat('dd/MM/yyyy');

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _retry() {
    return ref
        .read(rdsoRevisionControllerProvider.notifier)
        .load(reloadCategories: true);
  }

  Future<void> _pickDate() async {
    final RdsoRevisionState state = ref.read(rdsoRevisionControllerProvider);
    final DateTime now = DateTime.now();
    DateTime initial = now;
    final String raw = state.draft.date.trim();
    if (raw.isNotEmpty) {
      final DateTime? parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        initial = parsed;
      }
    }
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null || !mounted) {
      return;
    }
    ref
        .read(rdsoRevisionControllerProvider.notifier)
        .setDraftDate(_apiDate.format(picked));
  }

  Future<void> _onPreview(RdsoDrawingRow row) async {
    await _openFile(row, preview: true);
  }

  Future<void> _onDownload(RdsoDrawingRow row) async {
    final Rect origin = _shareOrigin(context);
    await _openFile(row, preview: false, shareOrigin: origin);
  }

  Future<void> _openFile(
    RdsoDrawingRow row, {
    required bool preview,
    Rect? shareOrigin,
  }) async {
    if (!row.hasFile || _busyRow != null) {
      return;
    }
    setState(() => _busyRow = row);
    try {
      final String fallback = row.drawingKey.trim().isEmpty
          ? 'rdso-drawing.pdf'
          : '${row.drawingKey.trim()}.pdf';
      final ({Uint8List bytes, String fileName}) file = await ref
          .read(rdsoRemoteDataSourceProvider)
          .downloadFile(
            fileId: row.fileId!,
            preview: preview,
            fallbackName: fallback,
          );
      if (!mounted) {
        return;
      }
      if (preview) {
        if (RfiStoredFile.looksLikeImage(file.bytes)) {
          await showDialog<void>(
            context: context,
            builder: (BuildContext dialogContext) {
              return Dialog(
                child: InteractiveViewer(
                  child: Image.memory(file.bytes),
                ),
              );
            },
          );
          return;
        }
        await presentRdsoPreview(bytes: file.bytes, fileName: file.fileName);
        return;
      }
      await shareRdsoFile(
        bytes: file.bytes,
        fileName: file.fileName,
        sharePositionOrigin: shareOrigin,
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: preview ? 'Preview' : 'Download',
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : error is StateError
            ? error.message
            : preview
            ? 'Unable to preview this file.'
            : 'Unable to download this file.',
      );
    } finally {
      if (mounted) {
        setState(() => _busyRow = null);
      }
    }
  }

  Rect _shareOrigin(BuildContext origin) {
    final RenderObject? box = origin.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      final Offset topLeft = box.localToGlobal(Offset.zero);
      return topLeft & box.size;
    }
    final Size size = MediaQuery.sizeOf(origin);
    return Rect.fromLTWH(0, 0, size.width, size.height / 2);
  }

  @override
  Widget build(BuildContext context) {
    final RdsoRevisionState state = ref.watch(rdsoRevisionControllerProvider);
    if (state.draft.q.isEmpty && _search.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            ref.read(rdsoRevisionControllerProvider).draft.q.isEmpty &&
            _search.text.isNotEmpty) {
          _search.clear();
        }
      });
    }

    final bool failed = state.error != null;
    final List<RdsoDrawingRow> rows = failed
        ? const <RdsoDrawingRow>[]
        : state.snapshot.items;
    final int total = failed ? 0 : state.snapshot.total;
    final int pageSize = state.query.size < 1
        ? RdsoRevisionQuery.defaultSize
        : state.query.size;
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
    final bool filtersEnabled = !state.loading && _busyRow == null;

    return PagedTableColumn(
      header: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          RfiContentLoader(loading: state.loading || _busyRow != null),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (!failed) ...<Widget>[
                  _SummaryCards(
                    currentFiles: state.snapshot.currentFiles,
                    archivedFiles: state.snapshot.archivedFiles,
                  ),
                  const SizedBox(height: 12),
                ],
                _FilterBar(
                  state: state,
                  search: _search,
                  enabled: filtersEnabled,
                  displayDate: _displayDate,
                  onSearchChanged: (String value) {
                    ref
                        .read(rdsoRevisionControllerProvider.notifier)
                        .setDraftSearch(value);
                    setState(() {});
                  },
                  onCategory: (String? value) {
                    ref
                        .read(rdsoRevisionControllerProvider.notifier)
                        .setDraftCategory(value ?? '');
                  },
                  onStatus: (String? value) {
                    ref
                        .read(rdsoRevisionControllerProvider.notifier)
                        .setDraftStatus(value ?? '');
                  },
                  onPickDate: _pickDate,
                  onClearDate: () {
                    ref
                        .read(rdsoRevisionControllerProvider.notifier)
                        .setDraftDate('');
                  },
                  onSearch: () {
                    ref
                        .read(rdsoRevisionControllerProvider.notifier)
                        .applySearch();
                  },
                  onReset: () {
                    _search.clear();
                    ref
                        .read(rdsoRevisionControllerProvider.notifier)
                        .resetFilters();
                    setState(() {});
                  },
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
              message: 'No drawings match these filters.',
              onRetry: _retry,
            )
          : RdsoRevisionTable(
              rows: rows,
              busyRow: _busyRow,
              onPreview: _onPreview,
              onDownload: _onDownload,
            ),
      footer: showFooter
          ? TablePaginationFooter(
              label: label,
              total: total,
              page: page,
              pageCount: pageCount,
              pageSize: pageSize,
              onPageChanged: (int next) {
                ref.read(rdsoRevisionControllerProvider.notifier).setPage(next);
              },
              onPageSizeChanged: (int size) {
                ref
                    .read(rdsoRevisionControllerProvider.notifier)
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

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({
    required this.currentFiles,
    required this.archivedFiles,
  });

  final int currentFiles;
  final int archivedFiles;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: _SummaryCard(
            icon: Icons.description_outlined,
            label: 'Current Files',
            value: currentFiles,
            accent: AppPalette.of(context).success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            icon: Icons.inventory_2_outlined,
            label: 'Archived / Superseded Files',
            value: archivedFiles,
            accent: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      color: palette.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: palette.mutedText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value.toLocaleString(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on int {
  String toLocaleString() {
    final String raw = toString();
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      final int fromEnd = raw.length - i;
      out.write(raw[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) {
        out.write(',');
      }
    }
    return out.toString();
  }
}

class _RevisionFilterTwoColumnRow extends StatelessWidget {
  const _RevisionFilterTwoColumnRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    assert(children.length == 2);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: SizedBox(
            height: AppTheme.fieldHeight,
            width: double.infinity,
            child: children[0],
          ),
        ),
        const SizedBox(width: _FilterBar._controlGap),
        Expanded(
          child: SizedBox(
            height: AppTheme.fieldHeight,
            width: double.infinity,
            child: children[1],
          ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.state,
    required this.search,
    required this.enabled,
    required this.displayDate,
    required this.onSearchChanged,
    required this.onCategory,
    required this.onStatus,
    required this.onPickDate,
    required this.onClearDate,
    required this.onSearch,
    required this.onReset,
  });

  final RdsoRevisionState state;
  final TextEditingController search;
  final bool enabled;
  final DateFormat displayDate;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onCategory;
  final ValueChanged<String?> onStatus;
  final VoidCallback onPickDate;
  final VoidCallback onClearDate;
  final VoidCallback onSearch;
  final VoidCallback onReset;

  static const double _controlGap = 8;

  static ButtonStyle _filledControlStyle() {
    return FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(AppTheme.fieldHeight),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  static ButtonStyle _outlinedControlStyle() {
    return OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(AppTheme.fieldHeight),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final RdsoRevisionQuery draft = state.draft;
    final List<RfiFilterOption> categories = state.snapshot.categories
        .map(
          (RdsoCategory c) => RfiFilterOption(id: c.id, label: c.name),
        )
        .toList(growable: false);
    final List<RfiFilterOption> statuses = const <RfiFilterOption>[
      RfiFilterOption(id: 'Current', label: 'Current'),
      RfiFilterOption(id: 'Archived', label: 'Archived'),
    ];
    final String? dateLabel = draft.date.trim().isEmpty
        ? null
        : () {
            final DateTime? parsed = DateTime.tryParse(draft.date);
            return parsed == null ? draft.date : displayDate.format(parsed);
          }();

    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: SizedBox(
                    height: AppTheme.fieldHeight,
                    child: TextField(
                      controller: search,
                      textInputAction: TextInputAction.search,
                      onChanged: onSearchChanged,
                      onSubmitted: (_) => onSearch(),
                      decoration: InputDecoration(
                        hintText: 'Search drawing no., title, keyword...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: search.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear',
                                onPressed: () {
                                  search.clear();
                                  onSearchChanged('');
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: _controlGap),
                FilledButton(
                  style: _filledControlStyle().copyWith(
                    minimumSize: WidgetStateProperty.all(
                      const Size(96, AppTheme.fieldHeight),
                    ),
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                  onPressed: enabled ? onSearch : null,
                  child: const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: _controlGap),
            _RevisionFilterTwoColumnRow(
              children: <Widget>[
                RfiFilterField(
                  label: 'Category',
                  emptyLabel: rdsoFilterEmptyLabel,
                  value: _selectedLabel(categories, draft.categoryId),
                  options: categories,
                  selectedId: draft.categoryId.isEmpty
                      ? null
                      : draft.categoryId,
                  onClear: draft.categoryId.isEmpty
                      ? null
                      : () => onCategory(''),
                  onPick: (RfiFilterOption option) => onCategory(option.id),
                ),
                IgnorePointer(
                  child: Opacity(
                    opacity: 0.55,
                    child: RfiFilterField(
                      label: 'Department',
                      emptyLabel: rdsoFilterEmptyLabel,
                      value: null,
                      options: const <RfiFilterOption>[],
                      selectedId: null,
                      onClear: null,
                      onPick: (_) {},
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: _controlGap),
            _RevisionFilterTwoColumnRow(
              children: <Widget>[
                RfiFilterField(
                  label: 'Status',
                  emptyLabel: rdsoFilterEmptyLabel,
                  value: _selectedLabel(statuses, draft.status),
                  options: statuses,
                  selectedId: draft.status.isEmpty ? null : draft.status,
                  onClear: draft.status.isEmpty ? null : () => onStatus(''),
                  onPick: (RfiFilterOption option) => onStatus(option.id),
                ),
                OutlinedButton(
                  style: _outlinedControlStyle(),
                  onPressed: enabled ? onReset : null,
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: _controlGap),
            SizedBox(
              height: AppTheme.fieldHeight,
              width: double.infinity,
              child: _DateField(
                label: dateLabel,
                onPick: onPickDate,
                onClear: dateLabel == null ? null : onClearDate,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _selectedLabel(List<RfiFilterOption> options, String id) {
    if (id.trim().isEmpty) {
      return null;
    }
    for (final RfiFilterOption option in options) {
      if (option.id == id) {
        return option.label;
      }
    }
    return id;
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.onPick,
    required this.onClear,
  });

  final String? label;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final BorderRadius radius = BorderRadius.circular(AppTheme.cardRadius);
    return Material(
      color: palette.fieldFill,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onPick,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label ?? 'Date (dd/mm/yyyy)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: label == null
                        ? palette.mutedText
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onClear != null)
                IconButton(
                  tooltip: 'Clear',
                  visualDensity: VisualDensity.compact,
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded, size: 18),
                )
              else
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: palette.mutedText,
                ),
            ],
          ),
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
