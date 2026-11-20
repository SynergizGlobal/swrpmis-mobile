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
import 'package:swr_pmis_mobile/src/features/reports/presentation/providers/bg_insurance_report_provider.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/widgets/report_generating_dialog.dart';

class BgInsuranceReportPage extends ConsumerWidget {
  const BgInsuranceReportPage({
    super.key,
    this.title = 'BG/Insurance Report',
  });

  static const String routeName = 'bg-insurance-report';
  static const String routePath = '/reports/bg-insurance';

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BgInsuranceReportState state = ref.watch(
      bgInsuranceReportControllerProvider,
    );
    final BgInsuranceReportController controller = ref.read(
      bgInsuranceReportControllerProvider.notifier,
    );
    ref.listen<BgInsuranceReportState>(
      bgInsuranceReportControllerProvider,
      (BgInsuranceReportState? previous, BgInsuranceReportState next) {
        if (next.generating || (previous?.generating ?? false)) {
          return;
        }
        syncReportBusyDialog(
          context: context,
          busy: next.loading,
          wasBusy: previous?.loading ?? false,
          title: 'Loading filters',
          message: 'Fetching project, contractor and status options…',
        );
      },
    );
    if (state.loading && !state.generating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }
        final BgInsuranceReportState latest = ref.read(
          bgInsuranceReportControllerProvider,
        );
        if (latest.loading && !latest.generating) {
          showReportBusyDialog(
            context,
            title: 'Loading filters',
            message: 'Fetching project, contractor and status options…',
          );
        }
      });
    }
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String heading = title.trim().isEmpty
        ? 'BG/Insurance Report'
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
                          final List<Widget> fields = <Widget>[
                            _PickerField(
                              label: 'Project',
                              hint: 'Select Project',
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
                              hint: 'Select Contractor',
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
                              label: 'Status of Work',
                              hint: 'Select Status of Work',
                              value: state.selectedContractStatus?.label,
                              enabled: !state.generating && !state.loading,
                              onTap: () => _pick(
                                context,
                                title: 'Select Status of Work',
                                options: state.contractStatuses,
                                selectedId: state.contractStatusId,
                                onPicked: controller.setContractStatus,
                              ),
                              onClear: state.contractStatusId.isEmpty
                                  ? null
                                  : () => controller.setContractStatus(null),
                            ),
                            _PickerField(
                              label: 'Validity Expiry From Date',
                              hint: 'Select From Date',
                              value: state.fromDateLabel,
                              enabled: !state.generating && !state.loading,
                              trailingIcon: Icons.calendar_today_outlined,
                              onTap: () => _pickDate(
                                context,
                                current: state.fromDate,
                                onPicked: controller.setFromDate,
                              ),
                              onClear: state.fromDate == null
                                  ? null
                                  : () => controller.setFromDate(null),
                            ),
                            _PickerField(
                              label: 'Validity Expiry To Date',
                              hint: 'Select To Date',
                              value: state.toDateLabel,
                              enabled: !state.generating && !state.loading,
                              trailingIcon: Icons.calendar_today_outlined,
                              onTap: () => _pickDate(
                                context,
                                current: state.toDate,
                                onPicked: controller.setToDate,
                              ),
                              onClear: state.toDate == null
                                  ? null
                                  : () => controller.setToDate(null),
                            ),
                          ];
                          if (!wide) {
                            return Column(
                              children: <Widget>[
                                for (int i = 0; i < fields.length; i++) ...<Widget>[
                                  if (i > 0) const SizedBox(height: 12),
                                  fields[i],
                                ],
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  children: <Widget>[
                                    fields[0],
                                    const SizedBox(height: 12),
                                    fields[2],
                                    const SizedBox(height: 12),
                                    fields[4],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  children: <Widget>[
                                    fields[1],
                                    const SizedBox(height: 12),
                                    fields[3],
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

  Future<void> _pickDate(
    BuildContext context, {
    required DateTime? current,
    required ValueChanged<DateTime?> onPicked,
  }) async {
    final DateTime now = DateTime.now();
    final DateTime initial = current ?? now;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  Future<void> _generate(BuildContext context, WidgetRef ref) async {
    final BgInsuranceReportState state = ref.read(
      bgInsuranceReportControllerProvider,
    );
    if (state.fromDate == null || state.toDate == null) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.warning,
        title: 'Dates required',
        message:
            'Please select Validity Expiry From Date and Validity Expiry To Date.',
      );
      return;
    }
    final BgInsuranceReportController controller = ref.read(
      bgInsuranceReportControllerProvider.notifier,
    );
    try {
      final ({Uint8List bytes, String fileName}) file =
          await runWithReportGeneratingDialog(
            context: context,
            title: 'Generating BG/Insurance report',
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
        message: 'BG/Insurance Report generated successfully.',
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
    required this.hint,
    required this.value,
    required this.enabled,
    required this.onTap,
    required this.onClear,
    this.trailingIcon = Icons.expand_more_rounded,
  });

  final String label;
  final String hint;
  final String? value;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
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
                      hasValue ? value! : hint,
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
                    Icon(trailingIcon, color: palette.mutedText, size: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
