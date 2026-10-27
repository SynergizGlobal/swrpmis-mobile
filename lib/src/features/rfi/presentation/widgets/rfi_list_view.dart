import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/paging/table_page.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/core/widgets/paged_table_column.dart';
import 'package:swr_pmis_mobile/src/core/widgets/table_pagination_footer.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/work_rfi_export_file.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_list_item.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_list_kind.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_permissions.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/providers/rfi_providers.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_table.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/work_rfi_form_page.dart';

class RfiListView extends ConsumerStatefulWidget {
  const RfiListView({super.key, required this.kind});

  final RfiListKind kind;

  @override
  ConsumerState<RfiListView> createState() => _RfiListViewState();
}

class _RfiListViewState extends ConsumerState<RfiListView> {
  final TextEditingController _search = TextEditingController();
  int _pageSize = TablePage.defaultPageSize;
  int _page = 1;
  bool _exporting = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(RfiListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) {
      _search.clear();
      _page = 1;
    }
  }

  Future<void> _onAdd() async {
    final bool canCreate = RfiPermissions.fromSession(
      ref.read(authControllerProvider).valueOrNull,
    ).canCreate;
    if (!canCreate || widget.kind != RfiListKind.work) {
      return;
    }
    await _openWorkForm(null);
  }

  Future<void> _onEdit(RfiListItem item) async {
    final int? id = item.id;
    if (id == null) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Edit',
        message: 'This RFI cannot be edited.',
      );
      return;
    }
    await _openWorkForm(id);
  }

  Future<void> _openWorkForm(int? id) async {
    final bool? saved = await Navigator.of(context, rootNavigator: true)
        .push<bool>(
          MaterialPageRoute<bool>(
            builder: (BuildContext context) => WorkRfiFormPage(rfiId: id),
          ),
        );
    if (saved != true || !mounted) {
      return;
    }
    await AppDialog.show(
      context,
      variant: AppDialogVariant.success,
      title: id == null ? 'Created' : 'Updated',
      message: id == null ? 'Work RFI created.' : 'Work RFI updated.',
    );
    if (!mounted) {
      return;
    }
    ref.invalidate(rfiListProvider(RfiListKind.work));
  }

  Future<void> _onExport(BuildContext origin) async {
    if (_exporting || widget.kind != RfiListKind.work || !mounted) {
      return;
    }
    final AsyncValue<List<RfiListItem>> asyncList = ref.read(
      rfiListProvider(widget.kind),
    );
    final List<RfiListItem> loaded = asyncList.hasValue && !asyncList.hasError
        ? asyncList.requireValue
        : const <RfiListItem>[];
    final List<RfiListItem> rows = loaded
        .where((RfiListItem item) => _matches(item, _search.text))
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
      await shareWorkRfiXlsx(items: rows, sharePositionOrigin: originRect);
    } on Object {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Export',
        message: 'Unable to export Work RFI.',
      );
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  Future<void> _onDelete(RfiListItem item) async {
    final bool confirmed = await AppDialog.confirm(
      context,
      title: 'Delete RFI',
      message: 'Delete ${item.rfiId.isEmpty ? 'this RFI' : item.rfiId}?',
      primaryLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<RfiListItem>> asyncList = ref.watch(
      rfiListProvider(widget.kind),
    );
    final bool canCreate = RfiPermissions.fromSession(
      ref.watch(authControllerProvider).valueOrNull,
    ).canCreate;
    final List<RfiListItem>? loaded = asyncList.hasValue && !asyncList.hasError
        ? asyncList.requireValue
        : null;
    final List<RfiListItem> visible = loaded == null
        ? const <RfiListItem>[]
        : loaded
              .where((RfiListItem item) => _matches(item, _search.text))
              .toList(growable: false);
    final bool showSearch = loaded != null || asyncList.isLoading;
    final TablePage<RfiListItem> tablePage = TablePage.slice(
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

    return PagedTableColumn(
      header: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          RfiContentLoader(loading: asyncList.isLoading || _exporting),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _ListHeader(
                  title: widget.kind.title,
                  countLabel: showSearch ? _countLabel(visible.length) : null,
                  onAdd: canCreate ? _onAdd : null,
                ),
                if (showSearch) ...<Widget>[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _search,
                          textInputAction: TextInputAction.search,
                          onChanged: (_) => setState(() => _page = 1),
                          decoration: InputDecoration(
                            hintText: 'Search RFI...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _search.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear',
                                    onPressed: () {
                                      _search.clear();
                                      setState(() => _page = 1);
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                            isDense: true,
                          ),
                        ),
                      ),
                      if (widget.kind == RfiListKind.work) ...<Widget>[
                        const SizedBox(width: 8),
                        _WorkRfiExportButton(
                          busy: _exporting,
                          onPressed: loaded == null ? null : _onExport,
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      body: asyncList.when(
        skipLoadingOnReload: true,
        loading: () =>
            const _FillScroll(minHeight: 240, child: SizedBox.shrink()),
        error: (Object error, StackTrace stackTrace) {
          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double minHeight = constraints.hasBoundedHeight
                  ? constraints.maxHeight
                  : 0;
              return _FillScroll(
                minHeight: minHeight,
                child: _StatusMessage(
                  message: error is DioException
                      ? userFriendlyErrorMessage(error)
                      : error.toString(),
                  onRetry: () => ref.invalidate(rfiListProvider(widget.kind)),
                ),
              );
            },
          );
        },
        data: (List<RfiListItem> items) {
          if (visible.isEmpty) {
            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double minHeight = constraints.hasBoundedHeight
                    ? constraints.maxHeight
                    : 0;
                return _FillScroll(
                  minHeight: minHeight,
                  child: _StatusMessage(
                    message: items.isEmpty
                        ? widget.kind.emptyMessage
                        : 'No matching RFIs.',
                    onRetry: items.isEmpty
                        ? () => ref.invalidate(rfiListProvider(widget.kind))
                        : null,
                  ),
                );
              },
            );
          }
          return RfiTable(
            columns: rfiTableColumns(
              widget.kind,
              onEdit: widget.kind == RfiListKind.work ? _onEdit : null,
              onDelete: widget.kind == RfiListKind.work ? _onDelete : null,
            ),
            items: tablePage.items,
          );
        },
      ),
      footer: loaded != null && !asyncList.hasError
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

  bool _matches(RfiListItem item, String query) {
    final String needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return true;
    }
    final List<String> parts = <String>[
      item.rfiId,
      item.projectName,
      item.rfiStatus,
      item.statusLabel,
      ...switch (widget.kind) {
        RfiListKind.material => <String>[
          item.item,
          item.material,
          item.batchLotNo,
          item.location,
          item.nameOfRepresentative,
          item.dateOfSubmission,
          item.scheduledText,
          item.contractorSubmittedOn,
        ],
        RfiListKind.work => <String>[
          item.structure,
          item.element,
          item.nameOfRepresentative,
          item.assignedPersonClient,
          item.dateOfSubmission,
          item.scheduledText,
          item.contractorSubmittedOn,
        ],
        RfiListKind.quality => <String>[
          item.rfiCategory,
          item.structureType,
          item.dateOfSubmission,
          item.scheduledText,
        ],
      },
    ];
    return parts.any((String part) => part.toLowerCase().contains(needle));
  }
}

String _countLabel(int count) {
  if (count == 1) {
    return '1 record total';
  }
  return '$count records total';
}

class _WorkRfiExportButton extends StatelessWidget {
  const _WorkRfiExportButton({required this.busy, required this.onPressed});

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

class _ListHeader extends StatelessWidget {
  const _ListHeader({
    required this.title,
    required this.countLabel,
    required this.onAdd,
  });

  final String title;
  final String? countLabel;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (countLabel != null) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  countLabel!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: palette.mutedText),
                ),
              ],
            ],
          ),
        ),
        if (onAdd != null)
          IconButton.filled(
            tooltip: 'Add',
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.railwayRed,
              foregroundColor: Colors.white,
            ),
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
          ),
      ],
    );
  }
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
