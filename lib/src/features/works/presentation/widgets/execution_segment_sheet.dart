import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/entities/execution_progress_segment.dart';

Future<void> showExecutionSegmentSheet({
  required BuildContext context,
  required ExecutionProgressSegment segment,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (BuildContext sheetContext) {
      final ThemeData theme = Theme.of(sheetContext);
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            Text(
              segment.structureTypeLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Contract Short Name',
              value: segment.contractShortLabel,
            ),
            _DetailRow(label: 'Contractor', value: segment.contractorLabel),
            _DetailRow(
              label: 'Structure Type',
              value: segment.structureTypeLabel,
            ),
            _DetailRow(label: 'Structure', value: segment.structureLabel),
            _DetailRow(label: 'Chainage (KM)', value: segment.chainageLabel),
            _DetailRow(label: 'Status', value: segment.statusLabel),
            _DetailRow(label: 'Progress', value: segment.progressLabel),
          ],
        ),
      );
    },
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
