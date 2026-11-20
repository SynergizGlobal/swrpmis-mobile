import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/reports/data/activities_export_file.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/providers/rfi_summary_report_provider.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/widgets/report_generating_dialog.dart';

class RfiSummaryReportPage extends ConsumerWidget {
  const RfiSummaryReportPage({super.key, this.title = 'RFI Summary Report'});

  static const String routeName = 'rfi-summary-report';
  static const String routePath = '/reports/rfi-summary';

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RfiSummaryReportState state = ref.watch(
      rfiSummaryReportControllerProvider,
    );
    final RfiSummaryReportController controller = ref.read(
      rfiSummaryReportControllerProvider.notifier,
    );
    ref.listen<RfiSummaryReportState>(
      rfiSummaryReportControllerProvider,
      (RfiSummaryReportState? previous, RfiSummaryReportState next) {
        if (next.downloading || (previous?.downloading ?? false)) {
          return;
        }
        final bool busy =
            next.loading ||
            next.loadingContracts ||
            next.loadingCategories ||
            next.loadingDateRange;
        final bool wasBusy =
            (previous?.loading ?? false) ||
            (previous?.loadingContracts ?? false) ||
            (previous?.loadingCategories ?? false) ||
            (previous?.loadingDateRange ?? false);
        syncReportBusyDialog(
          context: context,
          busy: busy,
          wasBusy: wasBusy,
          title: 'Loading filters',
          message: 'Fetching RFI Summary options…',
        );
      },
    );
    final bool initialBusy =
        state.loading ||
        state.loadingContracts ||
        state.loadingCategories ||
        state.loadingDateRange;
    if (initialBusy && !state.downloading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }
        final RfiSummaryReportState latest = ref.read(
          rfiSummaryReportControllerProvider,
        );
        final bool stillBusy =
            latest.loading ||
            latest.loadingContracts ||
            latest.loadingCategories ||
            latest.loadingDateRange;
        if (stillBusy && !latest.downloading) {
          showReportBusyDialog(
            context,
            title: 'Loading filters',
            message: 'Fetching RFI Summary options…',
          );
        }
      });
    }

    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String heading = title.trim().isEmpty
        ? 'RFI Summary Report'
        : title.trim();
    final Object? error = state.error;
    final String? errorText = error == null
        ? null
        : error is DioException
        ? userFriendlyErrorMessage(error)
        : error.toString();
    final bool busy =
        state.loading ||
        state.loadingContracts ||
        state.loadingCategories ||
        state.loadingDateRange ||
        state.downloading;
    final bool showDates = state.categoryId.isNotEmpty;

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
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    heading,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select a project, contract, and available RFI category to download the Excel report.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: palette.mutedText,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (errorText != null && !state.downloading) ...<Widget>[
                    Text(
                      errorText,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: colors.error),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _PickerField(
                    label: state.projects.isEmpty
                        ? 'Project'
                        : 'Project (${state.projects.length} available)',
                    hint: 'Select project',
                    value: state.selectedProject?.label,
                    enabled: !busy,
                    onTap: () => _pick(
                      context,
                      title: 'Select project',
                      options: state.projects,
                      selectedId: state.projectId,
                      onPicked: (String? id) => controller.setProject(id),
                    ),
                    onClear: state.projectId.isEmpty
                        ? null
                        : () => controller.setProject(null),
                  ),
                  const SizedBox(height: 12),
                  _PickerField(
                    label: state.projectId.isEmpty || state.contracts.isEmpty
                        ? 'Contract'
                        : 'Contract (${state.contracts.length} available)',
                    hint: state.projectId.isEmpty
                        ? 'Select a project first'
                        : state.loadingContracts
                        ? 'Loading contracts…'
                        : 'Select contract',
                    value: state.selectedContract?.label,
                    enabled:
                        !busy &&
                        state.projectId.isNotEmpty &&
                        !state.loadingContracts,
                    onTap: () => _pick(
                      context,
                      title: 'Select contract',
                      options: state.contracts,
                      selectedId: state.contractId,
                      onPicked: (String? id) => controller.setContract(id),
                    ),
                    onClear: state.contractId.isEmpty
                        ? null
                        : () => controller.setContract(null),
                  ),
                  const SizedBox(height: 12),
                  _PickerField(
                    label: state.contractId.isEmpty || state.categories.isEmpty
                        ? 'RFI Category'
                        : 'RFI Category (${state.categories.length} available)',
                    hint: state.projectId.isEmpty || state.contractId.isEmpty
                        ? 'Select a project and contract first'
                        : state.loadingCategories
                        ? 'Loading categories…'
                        : 'Select category',
                    value: state.selectedCategory?.label,
                    enabled:
                        !busy &&
                        state.projectId.isNotEmpty &&
                        state.contractId.isNotEmpty &&
                        !state.loadingCategories,
                    onTap: () => _pick(
                      context,
                      title: 'Select RFI category',
                      options: state.categories,
                      selectedId: state.categoryId,
                      onPicked: (String? id) => controller.setCategory(id),
                    ),
                    onClear: state.categoryId.isEmpty
                        ? null
                        : () => controller.setCategory(null),
                  ),
                  if (state.showSingleCategoryNote) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      'Only one category is available, so All Categories is not needed.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.mutedText,
                      ),
                    ),
                  ],
                  if (showDates) ...<Widget>[
                    const SizedBox(height: 16),
                    _PickerField(
                      label: 'Date Of Submission From',
                      hint: 'dd/mm/yyyy',
                      value: state.fromDateLabel,
                      enabled: !busy,
                      trailingIcon: Icons.calendar_today_outlined,
                      onTap: () => _pickDate(
                        context,
                        current: state.fromDate,
                        min: state.dateRange?.minDate,
                        max: state.dateRange?.maxDate,
                        onPicked: controller.setFromDate,
                      ),
                      onClear: state.fromDate == null
                          ? null
                          : () => controller.setFromDate(null),
                    ),
                    const SizedBox(height: 12),
                    _PickerField(
                      label: 'Date Of Submission To',
                      hint: 'dd/mm/yyyy',
                      value: state.toDateLabel,
                      enabled: !busy,
                      trailingIcon: Icons.calendar_today_outlined,
                      onTap: () => _pickDate(
                        context,
                        current: state.toDate,
                        min: state.dateRange?.minDate,
                        max: state.dateRange?.maxDate,
                        onPicked: controller.setToDate,
                      ),
                      onClear: state.toDate == null
                          ? null
                          : () => controller.setToDate(null),
                    ),
                    if (state.dateRangeHint.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        state.dateRangeHint,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.mutedText,
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 24),
                  Center(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: <Widget>[
                        OutlinedButton(
                          onPressed: busy ? null : () => controller.reset(),
                          child: const Text('Reset'),
                        ),
                        FilledButton(
                          onPressed: busy || !state.canDownload
                              ? null
                              : () => _download(context, ref),
                          child: const Text('Download Excel'),
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
    required DateTime? min,
    required DateTime? max,
    required ValueChanged<DateTime?> onPicked,
  }) async {
    final DateTime now = DateTime.now();
    final DateTime first = min ?? DateTime(2000);
    final DateTime last = max ?? DateTime(now.year + 20);
    DateTime initial = current ?? now;
    if (initial.isBefore(first)) {
      initial = first;
    }
    if (initial.isAfter(last)) {
      initial = last;
    }
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  Future<void> _download(BuildContext context, WidgetRef ref) async {
    final RfiSummaryReportState state = ref.read(
      rfiSummaryReportControllerProvider,
    );
    if (!state.canDownload) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.warning,
        title: 'Required fields',
        message:
            'Please select Project, Contract, and RFI Category before downloading.',
      );
      return;
    }
    final String? rangeError = state.dateRangeError;
    if (rangeError != null) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.warning,
        title: 'Invalid date range',
        message: rangeError,
      );
      return;
    }
    final RfiSummaryReportController controller = ref.read(
      rfiSummaryReportControllerProvider.notifier,
    );
    try {
      final ({Uint8List bytes, String fileName}) file =
          await runWithReportGeneratingDialog(
            context: context,
            title: 'Generating report',
            message: 'Please wait while the Excel file is being prepared.',
            action: controller.downloadExcel,
          );
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
        message: 'RFI Summary Excel report generated and shared successfully.',
      );
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Download failed',
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
        Opacity(
          opacity: enabled ? 1 : 0.55,
          child: Material(
            color: palette.fieldFill,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            child: InkWell(
              onTap: enabled ? onTap : null,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: AppTheme.fieldHeight,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border: Border.all(color: palette.borderSubtle),
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
        ),
      ],
    );
  }
}
