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
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/pending_issues_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/providers/pending_issues_report_provider.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/widgets/report_generating_dialog.dart';

class PendingIssuesReportPage extends ConsumerWidget {
  const PendingIssuesReportPage({
    super.key,
    this.title = 'Pending Issues Report',
  });

  static const String routeName = 'pending-issues-report';
  static const String routePath = '/reports/pending-issues';

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PendingIssuesReportState state = ref.watch(
      pendingIssuesReportControllerProvider,
    );
    final PendingIssuesReportController controller = ref.read(
      pendingIssuesReportControllerProvider.notifier,
    );
    ref.listen<PendingIssuesReportState>(
      pendingIssuesReportControllerProvider,
      (PendingIssuesReportState? previous, PendingIssuesReportState next) {
        if (next.generating || (previous?.generating ?? false)) {
          return;
        }
        syncReportBusyDialog(
          context: context,
          busy: next.loading,
          wasBusy: previous?.loading ?? false,
          title: 'Loading filters',
          message: 'Fetching HOD and contract options…',
        );
      },
    );
    if (state.loading && !state.generating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }
        final PendingIssuesReportState latest = ref.read(
          pendingIssuesReportControllerProvider,
        );
        if (latest.loading && !latest.generating) {
          showReportBusyDialog(
            context,
            title: 'Loading filters',
            message: 'Fetching HOD and contract options…',
          );
        }
      });
    }

    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String heading = title.trim().isEmpty
        ? 'Pending Issues Report'
        : title.trim();
    final Object? error = state.error;
    final String? errorText = error == null
        ? null
        : error is DioException
        ? userFriendlyErrorMessage(error)
        : error.toString();
    final bool busy = state.loading || state.generating;

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
                          final Widget hodField = _PickerField(
                            label: 'HOD',
                            value: state.selectedHod?.label,
                            enabled: !busy,
                            onTap: () => _pickHod(
                              context,
                              options: state.hods,
                              selectedId: state.hodSelectionId,
                              onPicked: controller.setHod,
                            ),
                            onClear: state.hodSelectionId.isEmpty
                                ? null
                                : () => controller.setHod(null),
                          );
                          final Widget contractField = _PickerField(
                            label: 'Contract',
                            value: state.selectedContract?.label,
                            enabled: !busy,
                            onTap: () => _pickContract(
                              context,
                              options: state.contracts,
                              selectedId: state.contractId,
                              onPicked: controller.setContract,
                            ),
                            onClear: state.contractId.isEmpty
                                ? null
                                : () => controller.setContract(null),
                          );
                          if (!wide) {
                            return Column(
                              children: <Widget>[
                                hodField,
                                const SizedBox(height: 12),
                                contractField,
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(child: hodField),
                              const SizedBox(width: 12),
                              Expanded(child: contractField),
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
                          onPressed: busy
                              ? null
                              : controller.clearFilters,
                          child: const Text('Clear Filters'),
                        ),
                        FilledButton(
                          onPressed: busy
                              ? null
                              : () => _generate(context, ref),
                          child: const Text('Generate Report'),
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

  Future<void> _pickHod(
    BuildContext context, {
    required List<PendingIssuesHodOption> options,
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
                    'Select HOD',
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
                            final PendingIssuesHodOption option =
                                options[index];
                            final bool selected =
                                option.selectionId == selectedId;
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
                              onTap: () => Navigator.pop(
                                sheetContext,
                                option.selectionId,
                              ),
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

  Future<void> _pickContract(
    BuildContext context, {
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
                    'Select Contract',
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
    final PendingIssuesReportController controller = ref.read(
      pendingIssuesReportControllerProvider.notifier,
    );
    final PendingIssuesReportState state = ref.read(
      pendingIssuesReportControllerProvider,
    );
    if (!state.canGenerate) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Missing filters',
        message: 'Select both HOD and Contract to generate the report.',
      );
      return;
    }
    try {
      final ({Uint8List bytes, String fileName}) file =
          await runWithReportGeneratingDialog(
            context: context,
            title: 'Generating pending issues report',
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
        message: 'Pending Issues Report generated successfully.',
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
