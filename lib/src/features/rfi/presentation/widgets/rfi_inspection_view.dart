import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/auth/domain/entities/auth_session.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_filter_option.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_filter.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_row.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_list_item.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_inspection_actions.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_user_role.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/providers/rfi_inspection_provider.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_clear_button.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_table.dart';

class RfiInspectionView extends ConsumerStatefulWidget {
  const RfiInspectionView({super.key, this.showTitle = true});

  final bool showTitle;

  @override
  ConsumerState<RfiInspectionView> createState() => _RfiInspectionViewState();
}

class _RfiInspectionViewState extends ConsumerState<RfiInspectionView> {
  final TextEditingController _search = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() {
    return ref.read(rfiInspectionControllerProvider.notifier).load();
  }

  Future<void> _submitReady() async {
    if (_submitting) {
      return;
    }
    final bool confirmed = await AppDialog.confirm(
      context,
      title: 'Submit Next 15 Ready RFIs',
      message: 'Submit the next 15 ready RFIs?',
    );
    if (!confirmed || !mounted) {
      return;
    }
    setState(() => _submitting = true);
    try {
      final RfiBulkSubmitResult result = await ref
          .read(rfiInspectionControllerProvider.notifier)
          .submitReady();
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: result.allSucceeded
            ? AppDialogVariant.success
            : AppDialogVariant.warning,
        title: result.allSucceeded ? 'Submitted' : 'Submitted with failures',
        message: result.message,
      );
      if (!mounted) {
        return;
      }
      await ref.read(rfiInspectionControllerProvider.notifier).refreshDetails();
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Submit failed',
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : error.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final RfiInspectionState inspection = ref.watch(
      rfiInspectionControllerProvider,
    );
    final AuthSession? session = ref.watch(authControllerProvider).valueOrNull;
    final RfiUserRole role = RfiUserRoleResolver.fromFields(
      userTypeFk: session?.userTypeFk ?? '',
      userRoleNameFk: session?.userRoleNameFk ?? '',
    );
    final List<RfiInspectionRow> loaded = inspection.catalog.rows;
    final List<RfiInspectionRow> visible = loaded
        .where((RfiInspectionRow row) => _matches(row, _search.text))
        .toList(growable: false);
    final bool hasError = inspection.error != null;
    final bool showSearch = !hasError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RfiContentLoader(loading: inspection.loading),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (widget.showTitle)
                Text(
                  'Inspection',
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
                state: inspection,
                enabled: !inspection.loading && !_submitting,
                onClearFilters: () => ref
                    .read(rfiInspectionControllerProvider.notifier)
                    .clearFilters(),
                onSubmit: _submitReady,
                submitting: _submitting,
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
        Expanded(child: _body(context, inspection, visible, role)),
      ],
    );
  }

  Widget _body(
    BuildContext context,
    RfiInspectionState inspection,
    List<RfiInspectionRow> visible,
    RfiUserRole role,
  ) {
    if (inspection.error != null && inspection.catalog.rows.isEmpty) {
      return _scrollMessage(
        message: inspection.error is DioException
            ? userFriendlyErrorMessage(inspection.error! as DioException)
            : inspection.error.toString(),
        onRetry: _refresh,
      );
    }
    if (inspection.loading && inspection.catalog.rows.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: const _FillScroll(minHeight: 240, child: SizedBox.shrink()),
      );
    }
    if (inspection.error != null) {
      return _scrollMessage(
        message: inspection.error is DioException
            ? userFriendlyErrorMessage(inspection.error! as DioException)
            : inspection.error.toString(),
        onRetry: _refresh,
      );
    }
    if (visible.isEmpty) {
      return _scrollMessage(
        message: inspection.catalog.rows.isEmpty
            ? 'No inspections found.'
            : 'No matching RFIs.',
        onRetry: inspection.catalog.rows.isEmpty ? _refresh : null,
      );
    }
    final Map<RfiListItem, RfiInspectionRow> lookup =
        <RfiListItem, RfiInspectionRow>{};
    final List<RfiListItem> items = <RfiListItem>[];
    for (final RfiInspectionRow row in visible) {
      final RfiListItem item = row.toListItem();
      lookup[item] = row;
      items.add(item);
    }
    return RfiTable(
      columns: _columns(context, role, lookup),
      items: items,
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
    BuildContext context,
    RfiUserRole role,
    Map<RfiListItem, RfiInspectionRow> lookup,
  ) {
    return <RfiTableColumn>[
      const RfiTableColumn(
        label: 'RFI Category',
        minWidth: 120,
        read: _category,
      ),
      const RfiTableColumn(label: 'RFI ID', minWidth: 196, read: _rfiId),
      const RfiTableColumn(label: 'Raised Date', minWidth: 124, read: _raised),
      const RfiTableColumn(
        label: 'Scheduled On',
        minWidth: 148,
        read: _scheduled,
      ),
      const RfiTableColumn(
        label: 'Contractor Submitted on',
        minWidth: 176,
        read: _submitted,
      ),
      const RfiTableColumn(
        label: 'RFI Description',
        minWidth: 180,
        read: _description,
      ),
      const RfiTableColumn(
        label: 'Assigned Contractor',
        minWidth: 168,
        read: _contractor,
      ),
      const RfiTableColumn(
        label: "Assigned Employer's Engineer",
        minWidth: 200,
        read: _engineer,
      ),
      const RfiTableColumn(
        label: 'Measurement Type',
        minWidth: 140,
        read: _measurement,
      ),
      const RfiTableColumn(label: 'Inspection Qty', minWidth: 120, read: _qty),
      const RfiTableColumn(
        label: 'Inspection Status',
        minWidth: 160,
        read: _status,
        status: true,
      ),
      RfiTableColumn(
        label: 'Action',
        minWidth: 72,
        read: _blank,
        buildCell: (BuildContext context, RfiListItem item) {
          final RfiInspectionRow? row = lookup[item];
          if (row == null) {
            return const Text('—');
          }
          final List<RfiInspectionAction> actions = rfiInspectionActions(
            role: role,
            row: row,
          );
          if (actions.isEmpty) {
            return const Text('—');
          }
          return Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Actions',
              visualDensity: VisualDensity.compact,
              onPressed: () => _openActions(context, actions),
              icon: const Icon(Icons.more_horiz_rounded),
            ),
          );
        },
      ),
    ];
  }

  Future<void> _openActions(
    BuildContext context,
    List<RfiInspectionAction> actions,
  ) async {
    final RfiInspectionAction? picked =
        await showModalBottomSheet<RfiInspectionAction>(
          context: context,
          showDragHandle: true,
          builder: (BuildContext sheetContext) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (final RfiInspectionAction action in actions)
                    ListTile(
                      leading: Icon(_actionIcon(action)),
                      title: Text(action.menuLabel),
                      onTap: () => Navigator.pop(sheetContext, action),
                    ),
                ],
              ),
            );
          },
        );
    if (picked == null || !context.mounted) {
      return;
    }
    await AppDialog.show(
      context,
      variant: AppDialogVariant.info,
      title: picked.dialogTitle,
      message: '${picked.dialogTitle} will open here.',
    );
  }
}

bool _matches(RfiInspectionRow row, String query) {
  final String needle = query.trim().toLowerCase();
  if (needle.isEmpty) {
    return true;
  }
  final List<String> parts = <String>[
    row.id?.toString() ?? '',
    row.rfiId,
    row.projectName,
    row.description,
    row.contractor,
    row.status,
    row.statusLabel,
  ];
  return parts.any((String part) => part.toLowerCase().contains(needle));
}

String _countLabel(int count) {
  if (count == 1) {
    return '1 record total';
  }
  return '$count records total';
}

String _category(RfiListItem item) => item.rfiCategory;

String _rfiId(RfiListItem item) => item.rfiId;

String _raised(RfiListItem item) => item.dateOfSubmission;

String _scheduled(RfiListItem item) => item.scheduledText;

String _submitted(RfiListItem item) => item.contractorSubmittedOn;

String _description(RfiListItem item) => item.rfiDescription;

String _contractor(RfiListItem item) => item.nameOfRepresentative;

String _engineer(RfiListItem item) => item.assignedPersonClient;

String _measurement(RfiListItem item) => item.measurementType;

String _qty(RfiListItem item) => item.inspectionQty;

String _status(RfiListItem item) => item.statusLabel;

String _blank(RfiListItem item) => '';

IconData _actionIcon(RfiInspectionAction action) {
  return switch (action) {
    RfiInspectionAction.startOnline => Icons.online_prediction,
    RfiInspectionAction.startOffline => Icons.offline_pin_outlined,
    RfiInspectionAction.viewDetails => Icons.visibility_outlined,
    RfiInspectionAction.uploadAttachments => Icons.attach_file_rounded,
    RfiInspectionAction.uploadTestResults => Icons.biotech_rounded,
    RfiInspectionAction.submit => Icons.check_circle_outline_rounded,
    RfiInspectionAction.sendForValidation => Icons.send_rounded,
    RfiInspectionAction.closeRfi => Icons.lock_outline_rounded,
    RfiInspectionAction.deleteRfi => Icons.delete_outline,
    RfiInspectionAction.changeExecutive => Icons.person_search_outlined,
  };
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.state,
    required this.enabled,
    required this.onClearFilters,
    required this.onSubmit,
    required this.submitting,
  });

  final RfiInspectionState state;
  final bool enabled;
  final VoidCallback onClearFilters;
  final VoidCallback onSubmit;
  final bool submitting;

  @override
  Widget build(BuildContext context) {
    final RfiInspectionFilter filter = state.filter;
    final bool categoryChosen =
        filter.rfiCategory != null && filter.rfiCategory!.trim().isNotEmpty;
    final List<Widget> chips = <Widget>[
      _chip(
        context,
        label: 'RFI Category',
        value: _label(state.catalog.categories, filter.rfiCategory),
        options: state.catalog.categories,
        selectedId: filter.rfiCategory,
        onClear: filter.rfiCategory == null
            ? null
            : () => _notifier(context).selectCategory(null),
        onPick: (RfiFilterOption option) =>
            _notifier(context).selectCategory(option.id),
      ),
      _chip(
        context,
        label: 'Project',
        value: _label(state.catalog.projects, filter.projectId),
        options: state.catalog.projects,
        selectedId: filter.projectId,
        onClear: filter.projectId == null
            ? null
            : () => _notifier(context).selectProject(null),
        onPick: (RfiFilterOption option) =>
            _notifier(context).selectProject(option.id),
      ),
      _chip(
        context,
        label: 'Contract',
        value: _label(state.catalog.contracts, filter.contractId),
        options: state.catalog.contracts,
        selectedId: filter.contractId,
        onClear: filter.contractId == null
            ? null
            : () => _notifier(context).selectContract(null),
        onPick: (RfiFilterOption option) =>
            _notifier(context).selectContract(option.id),
      ),
      if (categoryChosen && state.catalog.structureTypes.isNotEmpty)
        _chip(
          context,
          label: 'Structure Type',
          value: _label(state.catalog.structureTypes, filter.structureType),
          options: state.catalog.structureTypes,
          selectedId: filter.structureType,
          onClear: filter.structureType == null
              ? null
              : () => _notifier(context).selectStructureType(null),
          onPick: (RfiFilterOption option) =>
              _notifier(context).selectStructureType(option.id),
        ),
      if (categoryChosen && state.catalog.structures.isNotEmpty)
        _chip(
          context,
          label: 'Structure',
          value: _label(
            state.catalog.structures,
            filter.structureId?.toString(),
          ),
          options: state.catalog.structures,
          selectedId: filter.structureId?.toString(),
          onClear: filter.structureId == null
              ? null
              : () => _notifier(context).selectStructure(null),
          onPick: (RfiFilterOption option) =>
              _notifier(context).selectStructure(option.numberId),
        ),
      if (categoryChosen && state.catalog.items.isNotEmpty)
        _chip(
          context,
          label: 'Item',
          value: _label(state.catalog.items, filter.itemId?.toString()),
          options: state.catalog.items,
          selectedId: filter.itemId?.toString(),
          onClear: filter.itemId == null
              ? null
              : () => _notifier(context).selectItem(null),
          onPick: (RfiFilterOption option) =>
              _notifier(context).selectItem(option.numberId),
        ),
      if (categoryChosen && state.catalog.materials.isNotEmpty)
        _chip(
          context,
          label: 'Material',
          value: _label(state.catalog.materials, filter.materialId?.toString()),
          options: state.catalog.materials,
          selectedId: filter.materialId?.toString(),
          onClear: filter.materialId == null
              ? null
              : () => _notifier(context).selectMaterial(null),
          onPick: (RfiFilterOption option) =>
              _notifier(context).selectMaterial(option.numberId),
        ),
      if (categoryChosen && state.catalog.qualitySafety.isNotEmpty)
        _chip(
          context,
          label: 'Quality/Safety',
          value: _label(
            state.catalog.qualitySafety,
            filter.qualityOrSafetyId?.toString(),
          ),
          options: state.catalog.qualitySafety,
          selectedId: filter.qualityOrSafetyId?.toString(),
          onClear: filter.qualityOrSafetyId == null
              ? null
              : () => _notifier(context).selectQuality(null),
          onPick: (RfiFilterOption option) =>
              _notifier(context).selectQuality(option.numberId),
        ),
    ];
    final ButtonStyle buttonStyle = ButtonStyle(
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minimumSize: const WidgetStatePropertyAll<Size>(Size(0, 32)),
      padding: const WidgetStatePropertyAll<EdgeInsets>(
        EdgeInsets.symmetric(horizontal: 8),
      ),
      textStyle: const WidgetStatePropertyAll<TextStyle>(
        TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );

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
        Row(
          children: <Widget>[
            Expanded(
              child: RfiFilterClearButton(
                onPressed: enabled ? onClearFilters : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                style: buttonStyle,
                onPressed: submitting ? null : onSubmit,
                child: Text(submitting ? 'Sending' : 'Submit 15'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
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
                      value ?? 'Select',
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

String? _label(List<RfiFilterOption> options, String? id) {
  if (id == null) {
    return null;
  }
  for (final RfiFilterOption option in options) {
    if (option.id == id) {
      return option.label;
    }
  }
  return id;
}

RfiInspectionController _notifier(BuildContext context) {
  return ProviderScope.containerOf(
    context,
  ).read(rfiInspectionControllerProvider.notifier);
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
