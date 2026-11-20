import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/reports/data/contract_detail_report_file.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/providers/contract_detail_report_provider.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/widgets/report_generating_dialog.dart';

class ContractDetailReportPage extends ConsumerWidget {
  const ContractDetailReportPage({
    super.key,
    this.title = 'Contract Detail Report',
  });

  static const String routeName = 'contract-detail-report';
  static const String routePath = '/reports/contract-detail';

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ContractDetailReportState state = ref.watch(
      contractDetailReportControllerProvider,
    );
    final ContractDetailReportController controller = ref.read(
      contractDetailReportControllerProvider.notifier,
    );
    ref.listen<ContractDetailReportState>(
      contractDetailReportControllerProvider,
      (ContractDetailReportState? previous, ContractDetailReportState next) {
        // Skip while generate dialog owns the busy UI.
        if (next.generating || (previous?.generating ?? false)) {
          return;
        }
        syncReportBusyDialog(
          context: context,
          busy: next.loading,
          wasBusy: previous?.loading ?? false,
          title: 'Loading filters',
          message: 'Fetching project, contract and status options…',
        );
      },
    );
    // If filters are already loading when this page opens, show the dialog
    // once (listen alone misses the already-true → false case safely, but
    // would also miss showing the spinner for a slow first load).
    if (state.loading && !state.generating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }
        final ContractDetailReportState latest = ref.read(
          contractDetailReportControllerProvider,
        );
        if (latest.loading && !latest.generating) {
          showReportBusyDialog(
            context,
            title: 'Loading filters',
            message: 'Fetching project, contract and status options…',
          );
        }
      });
    }
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String heading = title.trim().isEmpty
        ? 'Contract Detail Report'
        : title.trim();
    final Object? error = state.error;
    final String? errorText = error == null
        ? null
        : error is DioException
        ? userFriendlyErrorMessage(error)
        : error.toString();

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
          Material(
            color: palette.cardSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              side: BorderSide(color: palette.borderSubtle),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      heading,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (errorText != null && !state.generating) ...<Widget>[
                    Text(
                      errorText,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: colors.error),
                    ),
                    const SizedBox(height: 12),
                  ],
                  LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          final bool wide = constraints.maxWidth >= 560;
                          final List<Widget> left = <Widget>[
                            _PickerField(
                              label: 'Project',
                              requiredField: false,
                              value: state.selectedProject?.label,
                              enabled: !state.generating && !state.loading,
                              onTap: () => _pick(
                                context,
                                title: 'Select Project',
                                options: state.projects,
                                selectedId: state.projectId,
                                onPicked: controller.setProject,
                              ),
                              onClear: state.projectId.isEmpty
                                  ? null
                                  : () => controller.setProject(null),
                            ),
                            _PickerField(
                              label: 'Contractor',
                              requiredField: false,
                              value: state.selectedContractor?.label,
                              enabled: !state.generating && !state.loading,
                              onTap: () => _pick(
                                context,
                                title: 'Select Contractor',
                                options: state.contractors,
                                selectedId: state.contractorId,
                                onPicked: controller.setContractor,
                              ),
                              onClear: state.contractorId.isEmpty
                                  ? null
                                  : () => controller.setContractor(null),
                            ),
                            _PickerField(
                              label: 'HOD',
                              requiredField: false,
                              value: state.selectedHod?.label,
                              enabled: !state.generating && !state.loading,
                              onTap: () => _pick(
                                context,
                                title: 'Select HOD(s)',
                                options: state.hods,
                                selectedId: state.hodId,
                                onPicked: controller.setHod,
                              ),
                              onClear: state.hodId.isEmpty
                                  ? null
                                  : () => controller.setHod(null),
                            ),
                          ];
                          final List<Widget> right = <Widget>[
                            _PickerField(
                              label: 'Contract',
                              requiredField: true,
                              value: state.selectedContract?.label,
                              enabled: !state.generating && !state.loading,
                              onTap: () => _pick(
                                context,
                                title: 'Select Contract',
                                options: state.contracts,
                                selectedId: state.contractId,
                                onPicked: controller.setContract,
                              ),
                              onClear: state.contractId.isEmpty
                                  ? null
                                  : () => controller.setContract(null),
                            ),
                            _PickerField(
                              label: 'Status of Work',
                              requiredField: false,
                              value: state.selectedStatus?.label,
                              enabled: !state.generating && !state.loading,
                              onTap: () => _pick(
                                context,
                                title: 'Select Status of Work',
                                options: state.statuses,
                                selectedId: state.statusId,
                                onPicked: controller.setStatus,
                              ),
                              onClear: state.statusId.isEmpty
                                  ? null
                                  : () => controller.setStatus(null),
                            ),
                          ];
                          if (!wide) {
                            return Column(
                              children: <Widget>[
                                left[0],
                                const SizedBox(height: 12),
                                right[0],
                                const SizedBox(height: 12),
                                left[1],
                                const SizedBox(height: 12),
                                right[1],
                                const SizedBox(height: 12),
                                left[2],
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  children: <Widget>[
                                    left[0],
                                    const SizedBox(height: 12),
                                    left[1],
                                    const SizedBox(height: 12),
                                    left[2],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  children: <Widget>[
                                    right[0],
                                    const SizedBox(height: 12),
                                    right[1],
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: <Widget>[
                        FilledButton(
                          onPressed: state.generating
                              ? null
                              : () => _generate(context, ref),
                          child: const Text('Generate Report'),
                        ),
                        OutlinedButton(
                          onPressed: state.generating || state.loading
                              ? null
                              : () => controller.reset(),
                          child: const Text('Reset'),
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

  Future<void> _pick(
    BuildContext context, {
    required String title,
    required List<ContractDetailOption> options,
    required String selectedId,
    required ValueChanged<String?> onPicked,
  }) async {
    final String? picked = await showModalBottomSheet<String>(
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
                    style: Theme.of(sheetContext).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  child: options.isEmpty
                      ? const Center(child: Text('No options available.'))
                      : ListView.builder(
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final ContractDetailOption option = options[index];
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
    if (picked != null) {
      onPicked(picked);
    }
  }

  Future<void> _generate(BuildContext context, WidgetRef ref) async {
    final ContractDetailReportState state = ref.read(
      contractDetailReportControllerProvider,
    );
    if (state.contractId.trim().isEmpty) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.warning,
        title: 'Contract required',
        message: 'Please select a contract before generating the report.',
      );
      return;
    }
    final ContractDetailReportController controller = ref.read(
      contractDetailReportControllerProvider.notifier,
    );
    try {
      final ({Uint8List bytes, String fileName}) file =
          await runWithReportGeneratingDialog(
            context: context,
            title: 'Generating contract detail report',
            message: 'Please wait while the file is being prepared.',
            action: controller.generate,
          );
      if (!context.mounted) {
        return;
      }
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      final Rect? origin = box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size;
      await shareContractDetailReportFile(
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
        message: 'Contract Detail Report generated successfully.',
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

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.requiredField,
    required this.value,
    required this.enabled,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final bool requiredField;
  final String? value;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool hasValue = value != null && value!.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text.rich(
          TextSpan(
            children: <InlineSpan>[
              TextSpan(
                text: label,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (requiredField)
                TextSpan(
                  text: ' *',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: palette.fieldFill,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            child: Container(
              constraints: const BoxConstraints(minHeight: AppTheme.fieldHeight),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border(
                  bottom: BorderSide(color: palette.borderSubtle),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      hasValue ? value! : 'Select $label',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: hasValue
                            ? colors.onSurface
                            : palette.mutedText,
                      ),
                    ),
                  ),
                  if (hasValue && onClear != null)
                    IconButton(
                      tooltip: 'Clear',
                      visualDensity: VisualDensity.compact,
                      onPressed: enabled ? onClear : null,
                      icon: const Icon(Icons.close_rounded, size: 18),
                    )
                  else
                    Icon(Icons.expand_more_rounded, color: palette.mutedText),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
