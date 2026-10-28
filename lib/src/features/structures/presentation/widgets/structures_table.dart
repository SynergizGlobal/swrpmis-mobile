import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/widgets/paged_table_column.dart';
import 'package:swr_pmis_mobile/src/features/structures/domain/structure_list.dart';

class StructuresTable extends StatelessWidget {
  const StructuresTable({
    super.key,
    required this.rows,
    required this.onEdit,
  });

  final List<StructureSummaryRow> rows;
  final void Function(StructureSummaryRow row) onEdit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewport = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 0;
        const double projectWidth = 100;
        const double actionWidth = 72;
        final double structuresWidth = math.max(
          220,
          viewport - projectWidth - actionWidth,
        );
        final double total = projectWidth + structuresWidth + actionWidth;
        return TableScrollFrame(
          width: math.max(total, viewport),
          header: _HeaderRow(
            projectWidth: projectWidth,
            structuresWidth: structuresWidth,
            actionWidth: actionWidth,
          ),
          itemCount: rows.length,
          itemBuilder: (BuildContext context, int index) {
            return _DataRow(
              row: rows[index],
              index: index,
              projectWidth: projectWidth,
              structuresWidth: structuresWidth,
              actionWidth: actionWidth,
              onEdit: () => onEdit(rows[index]),
            );
          },
        );
      },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.projectWidth,
    required this.structuresWidth,
    required this.actionWidth,
  });

  final double projectWidth;
  final double structuresWidth;
  final double actionWidth;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
    );
    return Container(
      color: AppTheme.brandPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: projectWidth,
            child: Text('Project', style: style),
          ),
          SizedBox(
            width: structuresWidth,
            child: Text('Structures', style: style),
          ),
          SizedBox(
            width: actionWidth,
            child: Text('Action', style: style, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.row,
    required this.index,
    required this.projectWidth,
    required this.structuresWidth,
    required this.actionWidth,
    required this.onEdit,
  });

  final StructureSummaryRow row;
  final int index;
  final double projectWidth;
  final double structuresWidth;
  final double actionWidth;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool alt = index.isOdd;
    final Color background = alt
        ? AppTheme.brandPrimary.withValues(alpha: 0.04)
        : palette.cardSurface;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border(
          bottom: BorderSide(color: palette.borderSubtle),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: projectWidth,
              child: Text(
                row.projectId,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(
              width: structuresWidth,
              child: row.structureTypes.isEmpty
                  ? Text(
                      '—',
                      style: TextStyle(color: palette.mutedText),
                    )
                  : Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        for (final StructureTypeCount item in row.structureTypes)
                          _StructureChip(label: item.displayLabel),
                      ],
                    ),
            ),
            SizedBox(
              width: actionWidth,
              child: Center(
                child: IconButton(
                  tooltip: 'Edit',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_square, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StructureChip extends StatelessWidget {
  const _StructureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.brandPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
