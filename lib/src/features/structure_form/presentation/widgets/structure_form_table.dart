import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/widgets/paged_table_column.dart';
import 'package:swr_pmis_mobile/src/features/structure_form/domain/structure_form_list.dart';

class StructureFormTableColumn {
  const StructureFormTableColumn({
    required this.label,
    required this.minWidth,
    required this.read,
    this.buildCell,
  });

  final String label;
  final double minWidth;
  final String Function(StructureFormRow row) read;
  final Widget Function(BuildContext context, StructureFormRow row)? buildCell;
}

List<StructureFormTableColumn> structureFormTableColumns({
  required void Function(StructureFormRow row) onEdit,
}) {
  return <StructureFormTableColumn>[
    const StructureFormTableColumn(
      label: 'Project',
      minWidth: 80,
      read: _project,
    ),
    const StructureFormTableColumn(
      label: 'Structure Type',
      minWidth: 130,
      read: _structureType,
    ),
    const StructureFormTableColumn(
      label: 'Structure',
      minWidth: 180,
      read: _structure,
    ),
    const StructureFormTableColumn(
      label: 'Contract',
      minWidth: 180,
      read: _contract,
    ),
    const StructureFormTableColumn(
      label: 'Work Status',
      minWidth: 120,
      read: _workStatus,
    ),
    StructureFormTableColumn(
      label: 'Actions',
      minWidth: 88,
      read: _blank,
      buildCell: (BuildContext context, StructureFormRow row) {
        return _EditAction(onPressed: () => onEdit(row));
      },
    ),
  ];
}

String _project(StructureFormRow row) => row.projectIdFk;

String _structureType(StructureFormRow row) => row.structureTypeFk;

String _structure(StructureFormRow row) => row.structureDisplay;

String _contract(StructureFormRow row) => row.contractShortName;

String _workStatus(StructureFormRow row) => row.workStatusFk;

String _blank(StructureFormRow row) => '';

class StructureFormTable extends StatelessWidget {
  const StructureFormTable({
    super.key,
    required this.rows,
    required this.onEdit,
  });

  final List<StructureFormRow> rows;
  final void Function(StructureFormRow row) onEdit;

  @override
  Widget build(BuildContext context) {
    final List<StructureFormTableColumn> columns = structureFormTableColumns(
      onEdit: onEdit,
    );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewport = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 0;
        final _ColumnLayout layout = _ColumnLayout.fit(columns, viewport);
        return TableScrollFrame(
          width: math.max(layout.total, viewport),
          header: _TableHeaderRow(columns: columns, widths: layout.widths),
          itemCount: rows.length,
          itemBuilder: (BuildContext context, int index) {
            return _DataRow(
              row: rows[index],
              columns: columns,
              widths: layout.widths,
              index: index,
            );
          },
        );
      },
    );
  }
}

class _ColumnLayout {
  const _ColumnLayout({required this.widths, required this.total});

  final List<double> widths;
  final double total;

  factory _ColumnLayout.fit(
    List<StructureFormTableColumn> columns,
    double viewport,
  ) {
    final double sum = columns.fold<double>(
      0,
      (double total, StructureFormTableColumn column) => total + column.minWidth,
    );
    if (columns.isEmpty) {
      return const _ColumnLayout(widths: <double>[], total: 0);
    }
    if (!viewport.isFinite || viewport <= 0 || sum >= viewport) {
      return _ColumnLayout(
        widths: columns
            .map((StructureFormTableColumn column) => column.minWidth)
            .toList(growable: false),
        total: sum,
      );
    }
    final double extra = (viewport - sum) / columns.length;
    return _ColumnLayout(
      widths: columns
          .map(
            (StructureFormTableColumn column) => column.minWidth + extra,
          )
          .toList(growable: false),
      total: viewport,
    );
  }
}

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow({required this.columns, required this.widths})
    : assert(columns.length == widths.length);

  final List<StructureFormTableColumn> columns;
  final List<double> widths;

  static const double _height = 52;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.brandPrimary,
      child: Row(
        children: <Widget>[
          for (int i = 0; i < columns.length; i++)
            SizedBox(
              width: widths[i],
              height: _height,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    columns[i].label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.row,
    required this.columns,
    required this.widths,
    required this.index,
  });

  final StructureFormRow row;
  final List<StructureFormTableColumn> columns;
  final List<double> widths;
  final int index;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color background = index.isEven
        ? (dark ? const Color(0xFF122844) : AppTheme.surfaceLight)
        : (dark ? const Color(0xFF0E1F36) : AppTheme.scaffoldLight);
    final Color line = AppPalette.of(context).borderSubtle;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border(bottom: BorderSide(color: line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < columns.length; i++)
            SizedBox(
              width: widths[i],
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: _cell(context, columns[i], dark, i == 0),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cell(
    BuildContext context,
    StructureFormTableColumn column,
    bool dark,
    bool emphasize,
  ) {
    if (column.buildCell != null) {
      return column.buildCell!(context, row);
    }
    final String raw = column.read(row).trim();
    final TextStyle style =
        Theme.of(context).textTheme.bodySmall?.copyWith(
          color: emphasize
              ? (dark ? const Color(0xFF9DC0F0) : AppTheme.brandPrimary)
              : Theme.of(context).colorScheme.onSurface,
          fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
          height: 1.3,
        ) ??
        const TextStyle(fontSize: 12, height: 1.3);
    return Text(raw.isEmpty ? '—' : _softBreak(raw), style: style);
  }
}

String _softBreak(String text) {
  return text.replaceAllMapped(RegExp(r'[_/\-]'), (Match match) {
    return '${match[0]}\u200B';
  });
}

class _EditAction extends StatelessWidget {
  const _EditAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color color = dark
        ? const Color(0xFFF0C36A)
        : const Color(0xFF8A5A00);
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        tooltip: 'Edit',
        onPressed: onPressed,
        icon: Icon(Icons.edit_note_rounded, color: color),
      ),
    );
  }
}
