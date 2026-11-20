import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/quality_control_summary_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/providers/quality_control_summary_report_provider.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/widgets/report_generating_dialog.dart';

class QualityControlSummaryReportPage extends ConsumerStatefulWidget {
  const QualityControlSummaryReportPage({
    super.key,
    this.title = 'Quality Control Summary Tests Report',
  });

  static const String routeName = 'quality-control-summary-report';
  static const String routePath = '/reports/quality-control-summary';

  final String title;

  @override
  ConsumerState<QualityControlSummaryReportPage> createState() =>
      _QualityControlSummaryReportPageState();
}

class _QualityControlSummaryReportPageState
    extends ConsumerState<QualityControlSummaryReportPage> {
  late final TextEditingController _contractorController;

  @override
  void initState() {
    super.initState();
    _contractorController = TextEditingController();
  }

  @override
  void dispose() {
    _contractorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final QualityControlSummaryReportState state = ref.watch(
      qualityControlSummaryReportControllerProvider,
    );
    final QualityControlSummaryReportController controller = ref.read(
      qualityControlSummaryReportControllerProvider.notifier,
    );
    ref.listen<QualityControlSummaryReportState>(
      qualityControlSummaryReportControllerProvider,
      (
        QualityControlSummaryReportState? previous,
        QualityControlSummaryReportState next,
      ) {
        if (next.generating || (previous?.generating ?? false)) {
          return;
        }
        syncReportBusyDialog(
          context: context,
          busy: next.loading,
          wasBusy: previous?.loading ?? false,
          title: 'Loading filters',
          message: 'Fetching project options…',
        );
      },
    );
    if (state.loading && !state.generating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }
        final QualityControlSummaryReportState latest = ref.read(
          qualityControlSummaryReportControllerProvider,
        );
        if (latest.loading && !latest.generating) {
          showReportBusyDialog(
            context,
            title: 'Loading filters',
            message: 'Fetching project options…',
          );
        }
      });
    }

    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String heading = widget.title.trim().isEmpty
        ? 'Quality Control Summary Tests Report'
        : widget.title.trim();
    final Object? error = state.error;
    final String? errorText = error == null
        ? null
        : error is DioException
        ? userFriendlyErrorMessage(error)
        : error.toString();
    final bool busy =
        state.loading || state.generating || state.loadingContracts;

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
                  _PickerField(
                    label: 'Project',
                    hint: 'Select Project',
                    value: state.selectedProject?.label,
                    enabled: !busy,
                    onTap: () => _pick(
                      context,
                      title: 'Select Project',
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
                    label: 'Contract',
                    hint: state.projectId.isEmpty
                        ? 'Select Project first'
                        : state.loadingContracts
                        ? 'Loading contracts…'
                        : 'Select Contract',
                    value: state.selectedContract?.label,
                    enabled:
                        !busy &&
                        state.projectId.isNotEmpty &&
                        !state.loadingContracts,
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
                  const SizedBox(height: 12),
                  _PickerField(
                    label: 'From',
                    hint: 'Select From Date',
                    value: state.fromDateLabel,
                    enabled: !busy,
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
                  const SizedBox(height: 12),
                  _PickerField(
                    label: 'To',
                    hint: 'Select To Date',
                    value: state.toDateLabel,
                    enabled: !busy,
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
                  const SizedBox(height: 12),
                  _TextField(
                    label: 'Contractor Name',
                    hint: 'Enter Contractor Name',
                    controller: _contractorController,
                    enabled: !busy,
                    onChanged: controller.setContractorName,
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
                              : () => _generate(context, ref),
                          child: const Text('Generate'),
                        ),
                        OutlinedButton(
                          onPressed: busy
                              ? null
                              : () async {
                                  _contractorController.clear();
                                  await controller.clear();
                                },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (state.generated) ...<Widget>[
            const SizedBox(height: 16),
            _ReportSection(report: state.report),
          ],
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
    final QualityControlSummaryReportState state = ref.read(
      qualityControlSummaryReportControllerProvider,
    );
    final List<String> missing = state.missingRequiredFilters;
    if (missing.isNotEmpty) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.warning,
        title: 'Required fields',
        message:
            'Please select ${missing.join(', ')} before generating the report.',
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
    final QualityControlSummaryReportController controller = ref.read(
      qualityControlSummaryReportControllerProvider.notifier,
    );
    try {
      await runWithReportGeneratingDialog(
        context: context,
        title: 'Generating report',
        message: 'Fetching Quality Control Tests Summary…',
        action: controller.generate,
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

class _TextField extends StatelessWidget {
  const _TextField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
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
        TextField(
          controller: controller,
          enabled: enabled,
          onChanged: onChanged,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: palette.fieldFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              borderSide: BorderSide(color: palette.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              borderSide: BorderSide(color: palette.borderSubtle),
            ),
          ),
        ),
      ],
    );
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
              constraints: const BoxConstraints(
                minHeight: AppTheme.fieldHeight,
              ),
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
                        color: hasValue ? colors.onSurface : palette.mutedText,
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

class _ReportSection extends StatelessWidget {
  const _ReportSection({required this.report});

  final QualityControlSummaryReport? report;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    if (report == null || report!.sections.isEmpty) {
      return Material(
        color: palette.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          side: BorderSide(color: palette.borderSubtle),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          child: Text(
            'No data available',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: palette.mutedText),
          ),
        ),
      );
    }

    final QualityControlSummaryReport data = report!;
    return Material(
      color: palette.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: palette.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _HeaderLine(label: 'Project Name', value: data.projectName),
            const SizedBox(height: 6),
            _HeaderLine(label: 'Contract Name', value: data.contractShortName),
            const SizedBox(height: 6),
            _HeaderLine(label: 'Contractor Name', value: data.contractorName),
            const SizedBox(height: 6),
            Text(
              data.periodLabel.isEmpty
                  ? 'Period: —'
                  : 'Summary of Quality Control Tests during ${data.periodLabel}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _TableHeader(colors: colors, palette: palette),
                    for (final QualitySummarySection section
                        in data.sections) ...<Widget>[
                      _SectionHeaderRow(section: section, palette: palette),
                      for (final QualitySummaryTestRow row
                          in section.rows)
                        _TestDataRow(row: row, colors: colors),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderLine extends StatelessWidget {
  const _HeaderLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: '$label: ',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          TextSpan(
            text: value.trim().isEmpty ? '—' : value.trim(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.colors, required this.palette});

  final ColorScheme colors;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final TextStyle? head = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w800,
      color: colors.onSurface,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.35),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              _cell('Sr No', 44, head, align: TextAlign.center),
              _cell('Material Description', 160, head),
              _cell('Unit', 48, head, align: TextAlign.center),
              _cell('Frequency', 110, head),
              _cell('Previous', 126, head, align: TextAlign.center),
              _cell('This Period', 126, head, align: TextAlign.center),
              _cell('Cumulative', 126, head, align: TextAlign.center),
            ],
          ),
          Divider(height: 1, thickness: 1, color: palette.borderSubtle),
          Row(
            children: <Widget>[
              _cell('', 44, head),
              _cell('', 160, head),
              _cell('', 48, head),
              _cell('', 110, head),
              ..._tripleHeads(head),
              ..._tripleHeads(head),
              ..._tripleHeads(head),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _tripleHeads(TextStyle? style) {
    return <Widget>[
      _cell('Perf', 42, style, align: TextAlign.center),
      _cell('Pass', 42, style, align: TextAlign.center),
      _cell('Fail', 42, style, align: TextAlign.center),
    ];
  }

  Widget _cell(
    String text,
    double width,
    TextStyle? style, {
    TextAlign align = TextAlign.left,
  }) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Text(text, textAlign: align, style: style),
      ),
    );
  }
}

class _SectionHeaderRow extends StatelessWidget {
  const _SectionHeaderRow({required this.section, required this.palette});

  final QualitySummarySection section;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w800,
    );
    // Match full table width used by header/data rows (44+160+48+110+126*3).
    const double restWidth = 160 + 48 + 110 + 126 + 126 + 126;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.fieldFill,
        border: Border(
          left: BorderSide(color: palette.borderSubtle),
          right: BorderSide(color: palette.borderSubtle),
          bottom: BorderSide(color: palette.borderSubtle),
        ),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                section.srNo,
                textAlign: TextAlign.center,
                style: style,
              ),
            ),
          ),
          SizedBox(
            width: restWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(section.title, style: style),
            ),
          ),
        ],
      ),
    );
  }
}

class _TestDataRow extends StatelessWidget {
  const _TestDataRow({required this.row, required this.colors});

  final QualitySummaryTestRow row;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.bodySmall;
    final Color border = colors.outlineVariant.withValues(alpha: 0.55);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: border),
          right: BorderSide(color: border),
          bottom: BorderSide(color: border),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _cell(row.label, 44, style, align: TextAlign.center),
          _cell(row.testName, 160, style),
          _cell(
            qualitySummaryDashOrText(row.unit),
            48,
            style,
            align: TextAlign.center,
          ),
          _cell(qualitySummaryDashOrText(row.frequency), 110, style),
          ..._counts(row.previous, style),
          ..._counts(row.current, style),
          ..._counts(row.cumulative, style),
        ],
      ),
    );
  }

  List<Widget> _counts(QualitySummaryCounts counts, TextStyle? style) {
    return <Widget>[
      _cell(
        qualitySummaryCountDisplay(counts.performed),
        42,
        style,
        align: TextAlign.center,
      ),
      _cell(
        qualitySummaryCountDisplay(counts.passed),
        42,
        style,
        align: TextAlign.center,
      ),
      _cell(
        qualitySummaryCountDisplay(counts.failed),
        42,
        style,
        align: TextAlign.center,
      ),
    ];
  }

  Widget _cell(
    String text,
    double width,
    TextStyle? style, {
    TextAlign align = TextAlign.left,
  }) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Text(text, textAlign: align, style: style),
      ),
    );
  }
}
