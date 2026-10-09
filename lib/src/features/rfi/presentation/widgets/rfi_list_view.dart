import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_list_item.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_list_kind.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/providers/rfi_providers.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_table.dart';

class RfiListView extends ConsumerStatefulWidget {
  const RfiListView({super.key, required this.kind});

  final RfiListKind kind;

  @override
  ConsumerState<RfiListView> createState() => _RfiListViewState();
}

class _RfiListViewState extends ConsumerState<RfiListView> {
  final TextEditingController _search = TextEditingController();

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
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(rfiListProvider(widget.kind));
    try {
      await ref.read(rfiListProvider(widget.kind).future);
    } on Object {
      return;
    }
  }

  void _onAdd() {
    AppDialog.show(
      context,
      variant: AppDialogVariant.info,
      title: 'Create',
      message: 'Create will be added next.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<RfiListItem>> asyncList = ref.watch(
      rfiListProvider(widget.kind),
    );
    final List<RfiListItem>? loaded = asyncList.hasValue && !asyncList.hasError
        ? asyncList.requireValue
        : null;
    final List<RfiListItem> visible = loaded == null
        ? const <RfiListItem>[]
        : loaded
              .where((RfiListItem item) => _matches(item, _search.text))
              .toList(growable: false);
    final bool showSearch = loaded != null || asyncList.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RfiContentLoader(loading: asyncList.isLoading),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _ListHeader(
                title: widget.kind.title,
                countLabel: showSearch ? _countLabel(visible.length) : null,
                onAdd: _onAdd,
              ),
              if (showSearch) ...<Widget>[
                const SizedBox(height: 12),
                TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search RFI...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear',
                            onPressed: () {
                              _search.clear();
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
        Expanded(
          child: asyncList.when(
            skipLoadingOnReload: true,
            loading: () => RefreshIndicator(
              onRefresh: _refresh,
              child: const _FillScroll(
                minHeight: 240,
                child: SizedBox.shrink(),
              ),
            ),
            error: (Object error, StackTrace stackTrace) {
              return LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double minHeight = constraints.hasBoundedHeight
                      ? constraints.maxHeight
                      : 0;
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: _FillScroll(
                      minHeight: minHeight,
                      child: _StatusMessage(
                        message: error is DioException
                            ? userFriendlyErrorMessage(error)
                            : error.toString(),
                        onRetry: () =>
                            ref.invalidate(rfiListProvider(widget.kind)),
                      ),
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
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: _FillScroll(
                        minHeight: minHeight,
                        child: _StatusMessage(
                          message: items.isEmpty
                              ? widget.kind.emptyMessage
                              : 'No matching RFIs.',
                          onRetry: items.isEmpty
                              ? () =>
                                    ref.invalidate(rfiListProvider(widget.kind))
                              : null,
                        ),
                      ),
                    );
                  },
                );
              }
              return RfiTable(
                columns: rfiTableColumns(widget.kind),
                items: visible,
                onRefresh: _refresh,
              );
            },
          ),
        ),
      ],
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

class _ListHeader extends StatelessWidget {
  const _ListHeader({
    required this.title,
    required this.countLabel,
    required this.onAdd,
  });

  final String title;
  final String? countLabel;
  final VoidCallback onAdd;

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
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(height: math.max(height, minHeight), child: child),
        );
      },
    );
  }
}
