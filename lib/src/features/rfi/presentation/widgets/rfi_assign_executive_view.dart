import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_assign_executive.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/providers/rfi_assign_executive_provider.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_assign_executive_table.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';

class RfiAssignExecutiveView extends ConsumerWidget {
  const RfiAssignExecutiveView({super.key, this.showTitle = true});

  final bool showTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(rfiAssignFormControllerProvider);
    ref.watch(rfiAssignLogControllerProvider);
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (showTitle)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                'Assign Executive',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          TabBar(
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: AppPalette.of(context).mutedText,
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            tabs: const <Widget>[
              Tab(text: 'Assign'),
              Tab(text: 'Log'),
            ],
          ),
          const Expanded(
            child: TabBarView(children: <Widget>[_AssignTab(), _LogTab()]),
          ),
        ],
      ),
    );
  }
}

class _AssignTab extends ConsumerWidget {
  const _AssignTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RfiAssignFormState form = ref.watch(rfiAssignFormControllerProvider);
    final RfiAssignFormController controller = ref.read(
      rfiAssignFormControllerProvider.notifier,
    );
    if (form.projectError != null && form.projects.isEmpty) {
      return _MessagePane(
        message: _failureMessage(form.projectError!),
        onRefresh: controller.refresh,
        onRetry: controller.refresh,
      );
    }
    final RfiAssignProject? project = _project(form);
    final RfiAssignContract? contract = _contract(form);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RfiContentLoader(
          loading: form.loadingProjects || form.loadingContracts,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              children: <Widget>[
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    const double gap = 12;
                    final bool wide = constraints.maxWidth >= 560;
                    final double width = !wide || constraints.maxWidth <= gap
                        ? constraints.maxWidth
                        : (constraints.maxWidth - gap) / 2;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: <Widget>[
                        SizedBox(
                          width: width,
                          child: _PickerField(
                            label: 'Project',
                            value: project?.label,
                            enabled: !form.loadingProjects,
                            onTap: () =>
                                _pickProject(context, form, controller),
                            onClear: project == null
                                ? null
                                : () => controller.selectProject(null),
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: _PickerField(
                            label: 'Contract',
                            value: contract?.label,
                            enabled: project != null && !form.loadingContracts,
                            onTap: () =>
                                _pickContract(context, form, controller),
                            onClear: contract == null
                                ? null
                                : () => controller.selectContract(null),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (form.projectError != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    _failureMessage(form.projectError!),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.railwayRed),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _SmallButton(
                      label: 'Retry',
                      filled: false,
                      onPressed: controller.refresh,
                    ),
                  ),
                ],
                if (form.contractError != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    _failureMessage(form.contractError!),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.railwayRed),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _SmallButton(
                      label: 'Retry',
                      filled: false,
                      onPressed: () =>
                          controller.reloadContracts(keepSelection: true),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickProject(
    BuildContext context,
    RfiAssignFormState form,
    RfiAssignFormController controller,
  ) async {
    final String? id = await _pick(
      context,
      title: 'Project',
      emptyMessage: 'No projects',
      options: form.projects
          .map(
            (RfiAssignProject item) => (id: item.projectId, label: item.label),
          )
          .toList(growable: false),
      selectedId: form.projectId,
    );
    if (id == null) {
      return;
    }
    await controller.selectProject(id);
  }

  Future<void> _pickContract(
    BuildContext context,
    RfiAssignFormState form,
    RfiAssignFormController controller,
  ) async {
    final String? id = await _pick(
      context,
      title: 'Contract',
      emptyMessage: 'No contracts',
      options: form.contracts
          .map(
            (RfiAssignContract item) =>
                (id: item.contractIdFk, label: item.label),
          )
          .toList(growable: false),
      selectedId: form.contractId,
    );
    if (id == null) {
      return;
    }
    controller.selectContract(id);
  }
}

class _LogTab extends ConsumerStatefulWidget {
  const _LogTab();

  @override
  ConsumerState<_LogTab> createState() => _LogTabState();
}

class _LogTabState extends ConsumerState<_LogTab> {
  final TextEditingController _search = TextEditingController();
  int? _deletingId;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() {
    return ref.read(rfiAssignLogControllerProvider.notifier).load();
  }

  Future<void> _delete(RfiAssignExecutiveLog row) async {
    final int? id = row.id;
    if (id == null || _deletingId != null) {
      return;
    }
    final bool confirmed = await AppDialog.confirm(
      context,
      title: 'Delete assignment',
      message: 'Delete this assigned executive?',
      primaryLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    setState(() => _deletingId = id);
    try {
      await ref
          .read(rfiAssignLogControllerProvider.notifier)
          .deleteAssignment(id);
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.success,
        title: 'Deleted',
        message: 'The assignment was deleted.',
      );
      if (!mounted) {
        return;
      }
      await _refresh();
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Delete failed',
        message: _failureMessage(error),
      );
    } finally {
      if (mounted) {
        setState(() => _deletingId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final RfiAssignLogState log = ref.watch(rfiAssignLogControllerProvider);
    final List<RfiAssignExecutiveLog> visible = log.rows
        .where((RfiAssignExecutiveLog row) => _matches(row, _search.text))
        .toList(growable: false);
    final bool showSearch = log.error == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RfiContentLoader(loading: log.loading),
        if (showSearch)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  _countLabel(visible.length),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppPalette.of(context).mutedText,
                  ),
                ),
                const SizedBox(height: 8),
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
            ),
          ),
        Expanded(child: _body(log, visible)),
      ],
    );
  }

  Widget _body(RfiAssignLogState log, List<RfiAssignExecutiveLog> visible) {
    if (log.error != null) {
      return _MessagePane(
        message: _failureMessage(log.error!),
        onRefresh: _refresh,
        onRetry: _refresh,
      );
    }
    if (log.loading && log.rows.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: const _FillScroll(minHeight: 240, child: SizedBox.shrink()),
      );
    }
    if (visible.isEmpty) {
      return _MessagePane(
        message: log.rows.isEmpty
            ? 'No assignments found.'
            : 'No matching assignments.',
        onRefresh: _refresh,
        onRetry: log.rows.isEmpty ? _refresh : null,
      );
    }
    return RfiAssignExecutiveTable(
      rows: visible,
      onRefresh: _refresh,
      onDelete: _delete,
      deletingId: _deletingId,
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final String? value;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final bool chosen = value != null && value!.isNotEmpty;
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Material(
            color: dark ? const Color(0xFF122844) : AppTheme.surfaceLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: enabled ? onTap : null,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        chosen ? value! : 'Select...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: chosen ? null : palette.mutedText,
                          fontWeight: chosen
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
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
                        onPressed: enabled ? onClear : null,
                        icon: const Icon(Icons.close_rounded, size: 16),
                      ),
                    const Padding(
                      padding: EdgeInsets.only(top: 2, right: 4),
                      child: Icon(Icons.arrow_drop_down_rounded, size: 22),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.label,
    required this.onPressed,
    required this.filled,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    const ButtonStyle style = ButtonStyle(
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minimumSize: WidgetStatePropertyAll<Size>(Size(0, 32)),
      padding: WidgetStatePropertyAll<EdgeInsets>(
        EdgeInsets.symmetric(horizontal: 10),
      ),
      textStyle: WidgetStatePropertyAll<TextStyle>(
        TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
    if (!filled) {
      return OutlinedButton(
        style: style,
        onPressed: onPressed,
        child: Text(label),
      );
    }
    return FilledButton(style: style, onPressed: onPressed, child: Text(label));
  }
}

class _MessagePane extends StatelessWidget {
  const _MessagePane({
    required this.message,
    required this.onRefresh,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRefresh;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double minHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 0;
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: _FillScroll(
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
                      _SmallButton(
                        label: 'Retry',
                        filled: true,
                        onPressed: onRetry,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
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

Future<String?> _pick(
  BuildContext context, {
  required String title,
  required String emptyMessage,
  required List<({String id, String label})> options,
  required String? selectedId,
}) async {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      final double maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.6;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: options.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(emptyMessage),
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
                    for (final ({String id, String label}) option in options)
                      ListTile(
                        title: Text(option.label),
                        trailing: option.id == selectedId
                            ? const Icon(Icons.check_rounded)
                            : null,
                        onTap: () => Navigator.pop(sheetContext, option.id),
                      ),
                  ],
                ),
        ),
      );
    },
  );
}

RfiAssignProject? _project(RfiAssignFormState form) {
  final String? id = form.projectId;
  if (id == null) {
    return null;
  }
  for (final RfiAssignProject project in form.projects) {
    if (project.projectId == id) {
      return project;
    }
  }
  return null;
}

RfiAssignContract? _contract(RfiAssignFormState form) {
  final String? id = form.contractId;
  if (id == null) {
    return null;
  }
  for (final RfiAssignContract contract in form.contracts) {
    if (contract.contractIdFk == id) {
      return contract;
    }
  }
  return null;
}

bool _matches(RfiAssignExecutiveLog row, String query) {
  final String needle = query.trim().toLowerCase();
  if (needle.isEmpty) {
    return true;
  }
  final List<String> parts = <String>[
    row.contract,
    row.structureType,
    row.structure,
    row.assignedExecutive,
  ];
  return parts.any((String part) => part.toLowerCase().contains(needle));
}

String _countLabel(int count) {
  if (count == 1) {
    return '1 record total';
  }
  return '$count records total';
}

String _failureMessage(Object error) {
  if (error is DioException) {
    return userFriendlyErrorMessage(error);
  }
  return error.toString();
}
