import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/widgets/paged_table_column.dart';
import 'package:swr_pmis_mobile/src/features/utility_shifting/domain/utility_shifting_list.dart';

class UtilityShiftingTableColumn {
  const UtilityShiftingTableColumn({
    required this.label,
    required this.minWidth,
    required this.read,
    this.buildCell,
  });

  final String label;
  final double minWidth;
  final String Function(UtilityShiftingRow row) read;
  final Widget Function(BuildContext context, UtilityShiftingRow row)?
  buildCell;
}

List<UtilityShiftingTableColumn> utilityShiftingTableColumns({
  required void Function(UtilityShiftingRow row) onEdit,
}) {
  return <UtilityShiftingTableColumn>[
    const UtilityShiftingTableColumn(label: 'ID', minWidth: 72, read: _id),
    const UtilityShiftingTableColumn(
      label: 'Description',
      minWidth: 180,
      read: _description,
    ),
    const UtilityShiftingTableColumn(
      label: 'Utility Type',
      minWidth: 130,
      read: _utilityType,
    ),
    const UtilityShiftingTableColumn(
      label: 'Custodian',
      minWidth: 120,
      read: _custodian,
    ),
    const UtilityShiftingTableColumn(label: 'HOD', minWidth: 120, read: _hod),
    const UtilityShiftingTableColumn(
      label: 'Execution Agency',
      minWidth: 140,
      read: _agency,
    ),
    const UtilityShiftingTableColumn(
      label: 'Status',
      minWidth: 110,
      read: _status,
    ),
    const UtilityShiftingTableColumn(
      label: 'Last Update',
      minWidth: 110,
      read: _updated,
    ),
    UtilityShiftingTableColumn(
      label: 'Actions',
      minWidth: 88,
      read: _blank,
      buildCell: (BuildContext context, UtilityShiftingRow row) {
        return _EditAction(onPressed: () => onEdit(row));
      },
    ),
  ];
}

String _id(UtilityShiftingRow row) => row.utilityShiftingId;

String _description(UtilityShiftingRow row) => row.description;

String _utilityType(UtilityShiftingRow row) => row.utilityType;

String _custodian(UtilityShiftingRow row) => row.custodian;

String _hod(UtilityShiftingRow row) => row.hod;

String _agency(UtilityShiftingRow row) => row.executionAgency;

String _status(UtilityShiftingRow row) => row.status;

String _updated(UtilityShiftingRow row) => row.lastUpdate;

String _blank(UtilityShiftingRow row) => '';

class UtilityShiftingTable extends StatelessWidget {
  const UtilityShiftingTable({
    super.key,
    required this.rows,
    required this.onEdit,
  });

  final List<UtilityShiftingRow> rows;
  final void Function(UtilityShiftingRow row) onEdit;

  @override
  Widget build(BuildContext context) {
    final List<UtilityShiftingTableColumn> columns =
        utilityShiftingTableColumns(onEdit: onEdit);
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
    List<UtilityShiftingTableColumn> columns,
    double viewport,
  ) {
    final double sum = columns.fold<double>(
      0,
      (double total, UtilityShiftingTableColumn column) =>
          total + column.minWidth,
    );
    if (columns.isEmpty) {
      return const _ColumnLayout(widths: <double>[], total: 0);
    }
    if (!viewport.isFinite || viewport <= 0 || sum >= viewport) {
      return _ColumnLayout(
        widths: columns
            .map((UtilityShiftingTableColumn column) => column.minWidth)
            .toList(growable: false),
        total: sum,
      );
    }
    final double extra = (viewport - sum) / columns.length;
    return _ColumnLayout(
      widths: columns
          .map(
            (UtilityShiftingTableColumn column) => column.minWidth + extra,
          )
          .toList(growable: false),
      total: viewport,
    );
  }
}

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow({required this.columns, required this.widths})
    : assert(columns.length == widths.length);

  final List<UtilityShiftingTableColumn> columns;
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

  final UtilityShiftingRow row;
  final List<UtilityShiftingTableColumn> columns;
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
    UtilityShiftingTableColumn column,
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
      child: OutlinedButton(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: const WidgetStatePropertyAll<Size>(Size(64, 32)),
          padding: const WidgetStatePropertyAll<EdgeInsets>(
            EdgeInsets.symmetric(horizontal: 10),
          ),
          foregroundColor: WidgetStatePropertyAll<Color>(color),
          side: WidgetStatePropertyAll<BorderSide>(BorderSide(color: color)),
          textStyle: const WidgetStatePropertyAll<TextStyle>(
            TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        onPressed: onPressed,
        child: const Text('Edit'),
      ),
    );
  }
}
