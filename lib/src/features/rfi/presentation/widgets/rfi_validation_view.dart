import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_filter_option.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_list_item.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_validation_filter.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_validation_row.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_validation_actions.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/providers/rfi_validation_provider.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_clear_button.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_table.dart';

class RfiValidationView extends ConsumerStatefulWidget {
  const RfiValidationView({super.key, this.showTitle = true});

  final bool showTitle;

  @override
  ConsumerState<RfiValidationView> createState() => _RfiValidationViewState();
}

class _RfiValidationViewState extends ConsumerState<RfiValidationView> {
  final TextEditingController _search = TextEditingController();
  final Map<String, String> _remarks = <String, String>{};
  final Map<String, String> _comments = <String, String>{};
  int _draftGeneration = -1;
  bool _busy = false;
  String? _busyAction;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _syncDrafts(int generation, List<RfiValidationRow> rows) {
    if (_draftGeneration == generation) {
      return;
    }
    _draftGeneration = generation;
    _remarks.clear();
    _comments.clear();
    for (int i = 0; i < rows.length; i++) {
      final RfiValidationRow row = rows[i];
      final String rowKey = rfiValidationRowKey(row, i);
      _remarks[rowKey] = rfiValidationSelectedRemark(row.remarks);
      _comments[rowKey] = clampRfiValidationComment(row.comment);
    }
  }

  Future<void> _refresh() {
    return ref.read(rfiValidationControllerProvider.notifier).load();
  }

  Future<void> _reportLater(String title) {
    return AppDialog.show(
      context,
      variant: AppDialogVariant.info,
      title: title,
      message:
          'Preview and download will be added when the report is available.',
    );
  }

  Future<void> _decide(
    RfiValidationRow row,
    String rowKey,
    RfiValidationDecision decision,
  ) async {
    if (_busy) {
      return;
    }
    final String remarks =
        _remarks[rowKey] ?? rfiValidationSelectedRemark(row.remarks);
    final String comment =
        _comments[rowKey] ?? clampRfiValidationComment(row.comment);
    if (!rfiValidationRemarkChosen(remarks)) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.info,
        title: 'Remarks required',
        message: 'Select remarks before you continue.',
      );
      return;
    }
    final Map<String, String>? fields = rfiValidationFormFields(
      row: row,
      remarks: remarks,
      comment: comment,
      decision: decision,
    );
    if (fields == null || !mounted) {
      return;
    }
    final bool confirmed = await AppDialog.confirm(
      context,
      title: decision.label,
      message: switch (decision) {
        RfiValidationDecision.approve => 'Approve this RFI?',
        RfiValidationDecision.reject => 'Reject this RFI?',
        RfiValidationDecision.rectify =>
          'Send this RFI back for clarification?',
      },
      primaryLabel: decision.label,
      destructive: decision == RfiValidationDecision.reject,
    );
    if (!confirmed || !mounted) {
      return;
    }
    setState(() {
      _busy = true;
      _busyAction = '$rowKey|${decision.name}';
    });
    try {
      await ref.read(rfiValidationControllerProvider.notifier).submit(fields);
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.success,
        title: 'Saved',
        message: 'The RFI validation was updated.',
      );
      if (!mounted) {
        return;
      }
      await ref.read(rfiValidationControllerProvider.notifier).load();
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Validation failed',
        message: validationFailureMessage(error),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _busyAction = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final RfiValidationState validation = ref.watch(
      rfiValidationControllerProvider,
    );
    _syncDrafts(validation.generation, validation.catalog.rows);
    final List<RfiValidationRow> loaded = validation.catalog.rows;
    final List<_VisibleRow> visible = <_VisibleRow>[];
    for (int i = 0; i < loaded.length; i++) {
      final RfiValidationRow row = loaded[i];
      final String rowKey = rfiValidationRowKey(row, i);
      if (!_matches(row, rowKey, _search.text)) {
        continue;
      }
      visible.add(
        _VisibleRow(row: row, rowKey: rowKey, item: row.toListItem()),
      );
    }
    final bool hasError = validation.error != null;
    final bool showSearch = !hasError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RfiContentLoader(loading: validation.loading),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (widget.showTitle)
                Text(
                  'Validation',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              if (showSearch) ...<Widget>[
                if (widget.showTitle) const SizedBox(height: 2),
                Text(
                  _countLabel(visible.length),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppPalette.of(context).mutedText,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _FilterBar(
                state: validation,
                enabled: !validation.loading && !_busy,
                onClearFilters: () => ref
                    .read(rfiValidationControllerProvider.notifier)
                    .clearFilters(),
                onCategory: (String? value) => ref
                    .read(rfiValidationControllerProvider.notifier)
                    .selectCategory(value),
                onProject: (String? value) => ref
                    .read(rfiValidationControllerProvider.notifier)
                    .selectProject(value),
                onContract: (String? value) => ref
                    .read(rfiValidationControllerProvider.notifier)
                    .selectContract(value),
              ),
              if (showSearch) ...<Widget>[
                const SizedBox(height: 12),
                TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search...',
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
        Expanded(child: _body(context, validation, visible)),
      ],
    );
  }

  Widget _body(
    BuildContext context,
    RfiValidationState validation,
    List<_VisibleRow> visible,
  ) {
    if (validation.error != null && validation.catalog.rows.isEmpty) {
      return _scrollMessage(
        message: validationFailureMessage(validation.error!),
        onRetry: _refresh,
      );
    }
    if (validation.loading && validation.catalog.rows.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: const _FillScroll(minHeight: 240, child: SizedBox.shrink()),
      );
    }
    if (validation.error != null) {
      return _scrollMessage(
        message: validationFailureMessage(validation.error!),
        onRetry: _refresh,
      );
    }
    if (visible.isEmpty) {
      return _scrollMessage(
        message: validation.catalog.rows.isEmpty
            ? 'No validations found.'
            : 'No matching validations.',
        onRetry: validation.catalog.rows.isEmpty ? _refresh : null,
      );
    }
    final Map<RfiListItem, _VisibleRow> lookup = <RfiListItem, _VisibleRow>{
      for (final _VisibleRow entry in visible) entry.item: entry,
    };
    return RfiTable(
      columns: _columns(validation.generation, lookup),
      items: visible
          .map((_VisibleRow entry) => entry.item)
          .toList(growable: false),
      onRefresh: _refresh,
    );
  }

  Widget _scrollMessage({
    required String message,
    required VoidCallback? onRetry,
  }) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double minHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 0;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: _FillScroll(
            minHeight: minHeight,
            child: _StatusMessage(message: message, onRetry: onRetry),
          ),
        );
      },
    );
  }

  List<RfiTableColumn> _columns(
    int generation,
    Map<RfiListItem, _VisibleRow> lookup,
  ) {
    return <RfiTableColumn>[
      const RfiTableColumn(
        label: 'RFI Category',
        minWidth: 120,
        read: _category,
      ),
      const RfiTableColumn(label: 'RFI ID', minWidth: 168, read: _rfiId),
      RfiTableColumn(
        label: 'Preview',
        minWidth: 76,
        read: _blank,
        buildCell: (BuildContext context, RfiListItem item) {
          return _iconButton(
            tooltip: 'Preview',
            icon: Icons.visibility_outlined,
            color: const Color(0xFF2563EB),
            onPressed: () => _reportLater('Preview'),
          );
        },
      ),
      RfiTableColumn(
        label: 'Download',
        minWidth: 88,
        read: _blank,
        buildCell: (BuildContext context, RfiListItem item) {
          return _iconButton(
            tooltip: 'Download',
            icon: Icons.download_rounded,
            color: const Color(0xFF14B8A6),
            onPressed: () => _reportLater('Download'),
          );
        },
      ),
      RfiTableColumn(
        label: 'Remarks',
        minWidth: 148,
        read: _blank,
        buildCell: (BuildContext context, RfiListItem item) {
          final _VisibleRow? entry = lookup[item];
          if (entry == null) {
            return const Text('—');
          }
          final String selected =
              _remarks[entry.rowKey] ?? rfiValidationRemarkPlaceholder;
          final bool dark = Theme.of(context).brightness == Brightness.dark;
          return DecoratedBox(
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF122844) : AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppPalette.of(context).borderSubtle),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  isDense: true,
                  value: rfiValidationRemarkOptions.contains(selected)
                      ? selected
                      : rfiValidationRemarkPlaceholder,
                  items: <DropdownMenuItem<String>>[
                    for (final String option in rfiValidationRemarkOptions)
                      DropdownMenuItem<String>(
                        value: option,
                        child: Text(
                          option,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                  onChanged: _busy
                      ? null
                      : (String? value) {
                          if (value == null) {
                            return;
                          }
                          setState(() => _remarks[entry.rowKey] = value);
                        },
                ),
              ),
            ),
          );
        },
      ),
      RfiTableColumn(
        label: 'Comments',
        minWidth: 220,
        read: _blank,
        buildCell: (BuildContext context, RfiListItem item) {
          final _VisibleRow? entry = lookup[item];
          if (entry == null) {
            return const Text('—');
          }
          return _CommentBox(
            fieldKey: '$generation|${entry.rowKey}',
            initial: _comments[entry.rowKey] ?? '',
            onChanged: (String value) => _comments[entry.rowKey] = value,
          );
        },
      ),
      RfiTableColumn(
        label: 'Action',
        minWidth: 208,
        read: _blank,
        buildCell: (BuildContext context, RfiListItem item) {
          final _VisibleRow? entry = lookup[item];
          if (entry == null) {
            return const Text('—');
          }
          final String? statusText = rfiValidationStatusText(entry.row.status);
          if (statusText != null) {
            return Text(
              statusText,
              style: TextStyle(
                color: _outcomeColor(
                  context,
                  rfiValidationOutcome(entry.row.status),
                ),
                fontWeight: FontWeight.w800,
                fontSize: 12,
                height: 1.25,
              ),
            );
          }
          final bool enabled = !_busy;
          return Wrap(
            spacing: 4,
            runSpacing: 4,
            children: <Widget>[
              for (final RfiValidationDecision decision
                  in rfiValidationDecisions(entry.row.status))
                _ActionButton(
                  label: decision.label,
                  color: _decisionColor(context, decision),
                  busy: _busyAction == '${entry.rowKey}|${decision.name}',
                  onPressed: enabled
                      ? () => _decide(entry.row, entry.rowKey, decision)
                      : null,
                ),
            ],
          );
        },
      ),
    ];
  }

  bool _matches(RfiValidationRow row, String rowKey, String query) {
    final String needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return true;
    }
    final String remarks = _remarks[rowKey] ?? '';
    final String comment = _comments[rowKey] ?? row.comment ?? '';
    final List<String> parts = <String>[
      row.rfiCategory ?? '',
      row.stringRfiId ?? '',
      remarks == rfiValidationRemarkPlaceholder ? '' : remarks,
      comment,
      row.status ?? '',
      rfiValidationStatusText(row.status) ?? '',
    ];
    return parts.any((String part) => part.toLowerCase().contains(needle));
  }
}

class _VisibleRow {
  const _VisibleRow({
    required this.row,
    required this.rowKey,
    required this.item,
  });

  final RfiValidationRow row;
  final String rowKey;
  final RfiListItem item;
}

class _CommentBox extends StatefulWidget {
  const _CommentBox({
    required this.fieldKey,
    required this.initial,
    required this.onChanged,
  });

  final String fieldKey;
  final String initial;
  final ValueChanged<String> onChanged;

  @override
  State<_CommentBox> createState() => _CommentBoxState();
}

class _CommentBoxState extends State<_CommentBox> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void didUpdateWidget(covariant _CommentBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fieldKey != oldWidget.fieldKey &&
        _controller.text != widget.initial) {
      _controller.value = TextEditingValue(
        text: widget.initial,
        selection: TextSelection.collapsed(offset: widget.initial.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      minLines: 2,
      maxLines: 4,
      maxLength: rfiValidationCommentMaxLength,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: 'Enter your comment',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        counterStyle: TextStyle(
          fontSize: 10,
          color: AppPalette.of(context).mutedText,
        ),
      ),
      buildCounter:
          (
            BuildContext context, {
            required int currentLength,
            required bool isFocused,
            required int? maxLength,
          }) {
            return Text(
              '$currentLength/${maxLength ?? rfiValidationCommentMaxLength}',
              style: TextStyle(
                fontSize: 10,
                color: AppPalette.of(context).mutedText,
              ),
            );
          },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
    required this.busy,
  });

  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: color.withValues(alpha: 0.4),
        disabledForegroundColor: Colors.white,
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: const Size(0, 28),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      onPressed: onPressed,
      child: busy
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(label),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.state,
    required this.enabled,
    required this.onClearFilters,
    required this.onCategory,
    required this.onProject,
    required this.onContract,
  });

  final RfiValidationState state;
  final bool enabled;
  final VoidCallback onClearFilters;
  final ValueChanged<String?> onCategory;
  final ValueChanged<String?> onProject;
  final ValueChanged<String?> onContract;

  @override
  Widget build(BuildContext context) {
    final RfiValidationFilter filter = state.filter;
    final List<Widget> chips = <Widget>[
      _chip(
        context,
        label: 'RFI Category',
        emptyLabel: 'Select RFI Category',
        value: _label(state.catalog.categories, filter.rfiCategory),
        options: state.catalog.categories,
        selectedId: _selected(filter.rfiCategory),
        onClear: filter.rfiCategory.isEmpty ? null : () => onCategory(null),
        onPick: (RfiFilterOption option) => onCategory(option.id),
      ),
      _chip(
        context,
        label: 'Project',
        emptyLabel: 'Select Project',
        value: _label(state.catalog.projects, filter.projectId),
        options: state.catalog.projects,
        selectedId: _selected(filter.projectId),
        onClear: filter.projectId.isEmpty ? null : () => onProject(null),
        onPick: (RfiFilterOption option) => onProject(option.id),
      ),
      _chip(
        context,
        label: 'Contract',
        emptyLabel: 'Select Contract',
        value: _label(state.catalog.contracts, filter.contractId),
        options: state.catalog.contracts,
        selectedId: _selected(filter.contractId),
        onClear: filter.contractId.isEmpty ? null : () => onContract(null),
        onPick: (RfiFilterOption option) => onContract(option.id),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        IgnorePointer(
          ignoring: !enabled,
          child: Opacity(
            opacity: enabled ? 1 : 0.6,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                const double gap = 8;
                final double cell = constraints.maxWidth <= gap
                    ? constraints.maxWidth
                    : (constraints.maxWidth - gap) / 2;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: <Widget>[
                    for (final Widget chip in chips)
                      SizedBox(width: cell, child: chip),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: RfiFilterClearButton(
            onPressed: enabled ? onClearFilters : null,
          ),
        ),
      ],
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required String emptyLabel,
    required String? value,
    required List<RfiFilterOption> options,
    required String? selectedId,
    required VoidCallback? onClear,
    required ValueChanged<RfiFilterOption> onPick,
  }) {
    final AppPalette palette = AppPalette.of(context);
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: dark ? const Color(0xFF122844) : AppTheme.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: palette.borderSubtle),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _pick(context, label, options, selectedId, onPick),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 2, 6),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: palette.mutedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      value ?? emptyLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (onClear != null)
                IconButton(
                  tooltip: 'Clear $label',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 28,
                    height: 28,
                  ),
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded, size: 16),
                ),
              const Icon(Icons.arrow_drop_down_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pick(
    BuildContext context,
    String title,
    List<RfiFilterOption> options,
    String? selectedId,
    ValueChanged<RfiFilterOption> onPick,
  ) async {
    final RfiFilterOption? picked = await showModalBottomSheet<RfiFilterOption>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final double maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.6;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: options.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No options'),
                  )
                : ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Text(
                          title,
                          style: Theme.of(sheetContext).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      for (final RfiFilterOption option in options)
                        ListTile(
                          title: Text(option.label),
                          trailing: option.id == selectedId
                              ? const Icon(Icons.check_rounded)
                              : null,
                          onTap: () => Navigator.pop(sheetContext, option),
                        ),
                    ],
                  ),
          ),
        );
      },
    );
    if (picked != null) {
      onPick(picked);
    }
  }
}

String? _selected(String value) {
  if (value.isEmpty) {
    return null;
  }
  return value;
}

String? _label(List<RfiFilterOption> options, String id) {
  if (id.isEmpty) {
    return null;
  }
  for (final RfiFilterOption option in options) {
    if (option.id == id) {
      return option.label;
    }
  }
  return id;
}

String _category(RfiListItem item) => item.rfiCategory;

String _rfiId(RfiListItem item) => item.rfiId;

String _blank(RfiListItem item) => '';

Widget _iconButton({
  required String tooltip,
  required IconData icon,
  required Color color,
  required VoidCallback onPressed,
}) {
  return Align(
    alignment: Alignment.centerLeft,
    child: IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      onPressed: onPressed,
      icon: Icon(icon, color: color, size: 22),
    ),
  );
}

Color _outcomeColor(BuildContext context, RfiValidationOutcome outcome) {
  final bool dark = Theme.of(context).brightness == Brightness.dark;
  final AppPalette palette = AppPalette.of(context);
  return switch (outcome) {
    RfiValidationOutcome.approved => palette.success,
    RfiValidationOutcome.rejected =>
      dark ? const Color(0xFFFF8A93) : AppTheme.railwayRed,
    RfiValidationOutcome.returned =>
      dark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
    RfiValidationOutcome.open => palette.mutedText,
  };
}

Color _decisionColor(BuildContext context, RfiValidationDecision decision) {
  final bool dark = Theme.of(context).brightness == Brightness.dark;
  return switch (decision) {
    RfiValidationDecision.approve => AppPalette.of(context).success,
    RfiValidationDecision.reject =>
      dark ? const Color(0xFFFF8A93) : AppTheme.railwayRed,
    RfiValidationDecision.rectify =>
      dark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8),
  };
}

String _countLabel(int count) {
  if (count == 1) {
    return '1 record total';
  }
  return '$count records total';
}

String validationFailureMessage(Object error) {
  if (error is DioException) {
    final String? server = _serverText(error.response?.data);
    if (server != null) {
      return server;
    }
    return userFriendlyErrorMessage(error);
  }
  return error.toString();
}

String? _serverText(dynamic data) {
  if (data is String) {
    final String text = data.trim();
    if (text.isEmpty || text.startsWith('<')) {
      return null;
    }
    return text;
  }
  if (data is Map) {
    for (final String key in const <String>[
      'message',
      'error',
      'msg',
      'errorMessage',
      'detail',
    ]) {
      final Object? value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
  }
  return null;
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
