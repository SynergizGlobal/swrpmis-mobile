import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/bg_contractual_letters.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/providers/bg_contractual_letters_provider.dart';

class BgContractualLettersPage extends ConsumerWidget {
  const BgContractualLettersPage({
    super.key,
    this.title = 'List of Contracts Closer to BG Expiry Date',
  });

  static const String routeName = 'bg-contractual-letters';
  static const String routePath = '/reports/bg-contractual-letters';

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BgContractualLettersState state = ref.watch(
      bgContractualLettersControllerProvider,
    );
    final BgContractualLettersController controller = ref.read(
      bgContractualLettersControllerProvider.notifier,
    );
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String heading = title.trim().isEmpty
        ? 'List of Contracts Closer to BG Expiry Date'
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
                  if (errorText != null && !state.loading) ...<Widget>[
                    Text(
                      errorText,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: colors.error),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _DateField(
                    label: 'Start Date',
                    hint: 'dd/mm/yyyy',
                    value: state.startDateLabel,
                    enabled: !state.loading,
                    onTap: () => _pickDate(
                      context,
                      current: state.startDate,
                      onPicked: controller.setStartDate,
                    ),
                    onClear: state.startDate == null
                        ? null
                        : () => controller.setStartDate(null),
                  ),
                  const SizedBox(height: 12),
                  _DateField(
                    label: 'End Date',
                    hint: 'dd/mm/yyyy',
                    value: state.endDateLabel,
                    enabled: !state.loading,
                    onTap: () => _pickDate(
                      context,
                      current: state.endDate,
                      onPicked: controller.setEndDate,
                    ),
                    onClear: state.endDate == null
                        ? null
                        : () => controller.setEndDate(null),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: FilledButton(
                      onPressed: state.loading
                          ? null
                          : () => _search(context, ref),
                      child: state.loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Search'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (state.searched) _ResultsSection(rows: state.rows),
        ],
      ),
    );
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

  Future<void> _search(BuildContext context, WidgetRef ref) async {
    final BgContractualLettersState state = ref.read(
      bgContractualLettersControllerProvider,
    );
    if (state.startDate == null || state.endDate == null) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.warning,
        title: 'Dates required',
        message: 'Please select Start Date and End Date.',
      );
      return;
    }
    final BgContractualLettersController controller = ref.read(
      bgContractualLettersControllerProvider.notifier,
    );
    try {
      await controller.search();
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Search failed',
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : error.toString(),
      );
    }
  }
}

class _ResultsSection extends StatelessWidget {
  const _ResultsSection({required this.rows});

  final List<BgContractualLetterRow> rows;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;

    if (rows.isEmpty) {
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: palette.mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Material(
      color: palette.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: palette.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(
            colors.primary.withValues(alpha: 0.12),
          ),
          columns: const <DataColumn>[
            DataColumn(label: Text('Contract ID')),
            DataColumn(label: Text('Contract Short Name')),
            DataColumn(label: Text('Contractor Name')),
            DataColumn(label: Text('BG Type')),
            DataColumn(label: Text('Issuing Bank')),
            DataColumn(label: Text('BG Number')),
            DataColumn(label: Text('Amount (INR)')),
            DataColumn(label: Text('Expiry Date')),
            DataColumn(label: Text('Download Letter')),
            DataColumn(label: Text('Status')),
          ],
          rows: <DataRow>[
            for (final BgContractualLetterRow row in rows)
              DataRow(
                cells: <DataCell>[
                  DataCell(Text(row.contractId)),
                  DataCell(Text(row.contractShortName)),
                  DataCell(Text(row.contractorName)),
                  DataCell(Text(row.bgType)),
                  DataCell(Text(row.issuingBank)),
                  DataCell(Text(row.bgNumber)),
                  DataCell(Text(row.amount)),
                  DataCell(Text(row.expiryDate)),
                  const DataCell(
                    Tooltip(
                      message: 'Download not available yet',
                      child: Icon(Icons.download_outlined, size: 18),
                    ),
                  ),
                  DataCell(Text(row.status)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.hint,
    required this.value,
    required this.enabled,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final String hint;
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
                      hasValue ? value! : hint,
                      maxLines: 1,
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
                    Icon(
                      Icons.calendar_today_outlined,
                      color: palette.mutedText,
                      size: 20,
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
