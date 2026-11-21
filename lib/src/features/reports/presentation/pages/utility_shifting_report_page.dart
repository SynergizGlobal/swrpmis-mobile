import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/providers/utility_shifting_report_provider.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/widgets/report_generating_dialog.dart';

class UtilityShiftingReportPage extends ConsumerWidget {
  const UtilityShiftingReportPage({
    super.key,
    this.title = 'Utility Shifting Report',
  });

  static const String routeName = 'utility-shifting-report';
  static const String routePath = '/reports/utility-shifting';

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UtilityShiftingReportState state = ref.watch(
      utilityShiftingReportControllerProvider,
    );
    final UtilityShiftingReportController controller = ref.read(
      utilityShiftingReportControllerProvider.notifier,
    );
    ref.listen<UtilityShiftingReportState>(
      utilityShiftingReportControllerProvider,
      (UtilityShiftingReportState? previous, UtilityShiftingReportState next) {
        syncReportBusyDialog(
          context: context,
          busy: next.loading,
          wasBusy: previous?.loading ?? false,
          title: 'Loading filters',
          message:
              'Fetching project, agency, contract, and HOD options…',
        );
      },
    );
    if (state.loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }
        final UtilityShiftingReportState latest = ref.read(
          utilityShiftingReportControllerProvider,
        );
        if (latest.loading) {
          showReportBusyDialog(
            context,
            title: 'Loading filters',
            message:
                'Fetching project, agency, contract, and HOD options…',
          );
        }
      });
    }

    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String heading = title.trim().isEmpty
        ? 'Utility Shifting Report'
        : title.trim();
    final Object? error = state.error;
    final String? errorText = error == null
        ? null
        : error is DioException
        ? userFriendlyErrorMessage(error)
        : error.toString();
    final bool busy = state.loading;

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
                  if (errorText != null) ...<Widget>[
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
                          final Widget projectField = _PickerField(
                            label: 'Project',
                            value: state.selectedProject?.label,
                            enabled: !busy,
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
                          );
                          final Widget agencyField = _PickerField(
                            label: 'Execution Agency',
                            value: state.selectedExecutionAgency?.label,
                            enabled: !busy,
                            onTap: () => _pick(
                              context,
                              title: 'Select Execution Agency',
                              options: state.executionAgencies,
                              selectedId: state.executionAgencyId,
                              onPicked: controller.setExecutionAgency,
                            ),
                            onClear: state.executionAgencyId.isEmpty
                                ? null
                                : () => controller.setExecutionAgency(null),
                          );
                          final Widget contractField = _PickerField(
                            label: 'Impacted Contract',
                            value: state.selectedImpactedContract?.label,
                            enabled: !busy,
                            onTap: () => _pick(
                              context,
                              title: 'Select Impacted Contract',
                              options: state.impactedContracts,
                              selectedId: state.contractId,
                              onPicked: controller.setImpactedContract,
                            ),
                            onClear: state.contractId.isEmpty
                                ? null
                                : () => controller.setImpactedContract(null),
                          );
                          final Widget hodField = _PickerField(
                            label: 'HOD',
                            value: state.selectedHod?.label,
                            enabled: !busy,
                            onTap: () => _pick(
                              context,
                              title: 'Select HOD',
                              options: state.hods,
                              selectedId: state.hodId,
                              onPicked: controller.setHod,
                            ),
                            onClear: state.hodId.isEmpty
                                ? null
                                : () => controller.setHod(null),
                          );
                          if (!wide) {
                            return Column(
                              children: <Widget>[
                                projectField,
                                const SizedBox(height: 12),
                                agencyField,
                                const SizedBox(height: 12),
                                contractField,
                                const SizedBox(height: 12),
                                hodField,
                              ],
                            );
                          }
                          return Column(
                            children: <Widget>[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(child: projectField),
                                  const SizedBox(width: 12),
                                  Expanded(child: agencyField),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(child: contractField),
                                  const SizedBox(width: 12),
                                  Expanded(child: hodField),
                                ],
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
                          onPressed: busy
                              ? null
                              : () => _onGenerate(context),
                          child: const Text('Generate Report'),
                        ),
                        OutlinedButton(
                          onPressed: busy ? null : controller.reset,
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

  /// Filters are wired; download API is still pending from backend.
  ///
  /// TODO(utility-report): Replace this dialog with a real download call to
  /// [UtilityShiftingReportController.generateReport] once the endpoint exists.
  Future<void> _onGenerate(BuildContext context) async {
    await AppDialog.show(
      context,
      variant: AppDialogVariant.info,
      title: 'Download not available yet',
      message:
          'Filters are ready, but the Utility Shifting Report download '
          'endpoint is still pending from backend. Please contact backend '
          'for the generate API.',
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
