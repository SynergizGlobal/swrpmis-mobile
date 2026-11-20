import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/reports/data/activities_export_file.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/activities_export_option.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/providers/activities_export_provider.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/widgets/activities_export_filter_dialog.dart';

class ActivitiesExportPage extends ConsumerWidget {
  const ActivitiesExportPage({super.key, this.title = 'Activities Export Report'});

  static const String routeName = 'activities-export-report';
  static const String routePath = '/reports/activities-export';

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ActivitiesExportState state = ref.watch(
      activitiesExportControllerProvider,
    );
    final ActivitiesExportController controller = ref.read(
      activitiesExportControllerProvider.notifier,
    );
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String heading = title.trim().isEmpty
        ? 'Activities Export Report'
        : title.trim();
    final Object? filterError = state.error;
    final String? filterErrorText = filterError == null
        ? null
        : filterError is DioException
        ? userFriendlyErrorMessage(filterError)
        : filterError.toString();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/reports');
            }
          },
        ),
        title: Text(heading),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: <Widget>[
          if (state.generating) ...<Widget>[
            _GeneratingBanner(),
            const SizedBox(height: 12),
          ],
          Material(
            color: palette.cardSurface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              side: BorderSide(color: palette.borderSubtle),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Use Generate Report to choose Project, then Contract. Filters are applied step by step before download.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: palette.mutedText,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (filterErrorText != null && !state.generating) ...<Widget>[
                    Text(
                      filterErrorText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      final bool wide = constraints.maxWidth >= 560;
                      final List<Widget> fields = <Widget>[
                        _PickerField(
                          label:
                              'Project (${state.projects.length} available)',
                          value: state.selectedProject?.label,
                          enabled: !state.generating,
                          loading: state.loadingFilters,
                          onTap: () => _pickProject(context, ref),
                          onClear: state.projectId.isEmpty
                              ? null
                              : () => controller.selectProject(null),
                        ),
                        _PickerField(
                          label:
                              'Contract (${state.contracts.length} available)',
                          value: state.selectedContract?.label,
                          enabled: !state.generating,
                          loading: state.loadingFilters,
                          onTap: () => _pickContract(context, ref),
                          onClear: state.contractId.isEmpty
                              ? null
                              : () => controller.selectContract(null),
                        ),
                      ];
                      if (!wide) {
                        return Column(
                          children: <Widget>[
                            fields[0],
                            const SizedBox(height: 12),
                            fields[1],
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(child: fields[0]),
                          const SizedBox(width: 12),
                          Expanded(child: fields[1]),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        OutlinedButton(
                          onPressed: state.generating || state.loadingFilters
                              ? null
                              : () => controller.reset(),
                          child: const Text('Reset'),
                        ),
                        FilledButton(
                          onPressed: state.generating
                              ? null
                              : () => _generate(context, ref),
                          child: state.generating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Generate Report'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickProject(BuildContext context, WidgetRef ref) async {
    final ActivitiesExportState state = ref.read(
      activitiesExportControllerProvider,
    );
    final String? picked = await _showOptionSheet(
      context,
      title: 'Select project',
      options: <({String id, String label})>[
        for (final ActivitiesExportProject item in state.projects)
          (id: item.projectId, label: item.label),
      ],
      selectedId: state.projectId,
    );
    if (picked == null) {
      return;
    }
    await ref
        .read(activitiesExportControllerProvider.notifier)
        .selectProject(picked);
  }

  Future<void> _pickContract(BuildContext context, WidgetRef ref) async {
    final ActivitiesExportState state = ref.read(
      activitiesExportControllerProvider,
    );
    final String? picked = await _showOptionSheet(
      context,
      title: 'Select contract',
      options: <({String id, String label})>[
        for (final ActivitiesExportContract item in state.contracts)
          (id: item.contractId, label: item.label),
      ],
      selectedId: state.contractId,
    );
    if (picked == null) {
      return;
    }
    await ref
        .read(activitiesExportControllerProvider.notifier)
        .selectContract(picked);
  }

  Future<void> _generate(BuildContext context, WidgetRef ref) async {
    final ActivitiesExportState state = ref.read(
      activitiesExportControllerProvider,
    );
    if (state.projects.isEmpty) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.warning,
        title: 'No projects',
        message: 'Projects are still loading or unavailable. Please try again.',
      );
      return;
    }

    final ({String projectId, String contractId})? filters =
        await showActivitiesExportFilterDialog(
          context,
          projects: state.projects,
          initialProjectId: state.projectId,
          initialContractId: state.contractId,
        );
    if (filters == null || !context.mounted) {
      return;
    }

    final ActivitiesExportController controller = ref.read(
      activitiesExportControllerProvider.notifier,
    );
    try {
      await controller.applyFilters(
        projectId: filters.projectId,
        contractId: filters.contractId,
      );
      if (!context.mounted) {
        return;
      }
      final ({Uint8List bytes, String fileName}) file = await controller
          .generate();
      if (!context.mounted) {
        return;
      }
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      final Rect? origin = box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size;
      await shareActivitiesExportFile(
        bytes: file.bytes,
        fileName: file.fileName,
        sharePositionOrigin: origin,
      );
      if (!context.mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.success,
        title: 'Report ready',
        message:
            'Activities Excel report generated and downloaded successfully.',
      );
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Generate failed',
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : error.toString(),
      );
    }
  }
}

Future<String?> _showOptionSheet(
  BuildContext context, {
  required String title,
  required List<({String id, String label})> options,
  required String selectedId,
}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      return SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  title,
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: options.isEmpty
                    ? const Center(child: Text('No options available.'))
                    : ListView.builder(
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final ({String id, String label}) option =
                              options[index];
                          final bool selected = option.id == selectedId;
                          return ListTile(
                            title: Text(option.label),
                            trailing: selected
                                ? Icon(
                                    Icons.check_rounded,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  )
                                : null,
                            onTap: () =>
                                Navigator.pop(sheetContext, option.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _GeneratingBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.primaryContainer.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Generating activities report...',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Please wait while the Excel file is being prepared. Do not close this page.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
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

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.loading,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final String? value;
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool hasValue = value != null && value!.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Material(
          color: palette.fieldFill,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          child: InkWell(
            onTap: enabled && !loading ? onTap : null,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            child: Container(
              constraints: const BoxConstraints(minHeight: AppTheme.fieldHeight),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: palette.borderSubtle),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      hasValue ? value! : 'Select',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: hasValue
                            ? Theme.of(context).colorScheme.onSurface
                            : palette.mutedText,
                      ),
                    ),
                  ),
                  if (loading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (hasValue && onClear != null)
                    IconButton(
                      tooltip: 'Clear',
                      visualDensity: VisualDensity.compact,
                      onPressed: enabled ? onClear : null,
                      icon: const Icon(Icons.close_rounded, size: 18),
                    )
                  else
                    Icon(
                      Icons.expand_more_rounded,
                      color: palette.mutedText,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
