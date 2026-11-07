import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/widgets/paged_table_column.dart';
import 'package:swr_pmis_mobile/src/features/p6_updates/domain/p6_list.dart';

class P6HistoryTableColumn {
  const P6HistoryTableColumn({
    required this.label,
    required this.minWidth,
    required this.read,
    this.buildCell,
  });

  final String label;
  final double minWidth;
  final String Function(P6HistoryRow row) read;
  final Widget Function(BuildContext context, P6HistoryRow row)? buildCell;
}

List<P6HistoryTableColumn> p6HistoryTableColumns({
  required void Function(P6HistoryRow row) onOpenFile,
}) {
  return <P6HistoryTableColumn>[
    const P6HistoryTableColumn(
      label: 'Contract ID',
      minWidth: 110,
      read: _contractId,
    ),
    const P6HistoryTableColumn(
      label: 'Data Type',
      minWidth: 120,
      read: _dataType,
    ),
    const P6HistoryTableColumn(
      label: 'Data Date',
      minWidth: 110,
      read: _dataDate,
    ),
    const P6HistoryTableColumn(label: 'Status', minWidth: 90, read: _status),
    P6HistoryTableColumn(
      label: 'Uploaded File',
      minWidth: 200,
      read: _file,
      buildCell: (BuildContext context, P6HistoryRow row) {
        final String name = row.uploadedFile.trim();
        if (name.isEmpty) {
          return const Text('—');
        }
        final Color linkColor = Theme.of(context).colorScheme.primary;
        return InkWell(
          onTap: () => onOpenFile(row),
          child: Text(
            _softBreak(name),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: linkColor,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: linkColor,
              height: 1.3,
            ),
          ),
        );
      },
    ),
    const P6HistoryTableColumn(
      label: 'Uploaded By',
      minWidth: 130,
      read: _uploadedBy,
    ),
    const P6HistoryTableColumn(
      label: 'Uploaded Date',
      minWidth: 160,
      read: _uploadedDate,
    ),
  ];
}

String _contractId(P6HistoryRow row) => row.contractId;

String _dataType(P6HistoryRow row) => row.dataType;

String _dataDate(P6HistoryRow row) => row.dataDate;

String _status(P6HistoryRow row) => row.status;

String _file(P6HistoryRow row) => row.uploadedFile;

String _uploadedBy(P6HistoryRow row) => row.uploadedBy;

String _uploadedDate(P6HistoryRow row) => row.uploadedDate;

class P6HistoryTable extends StatelessWidget {
  const P6HistoryTable({
    super.key,
    required this.rows,
    required this.onOpenFile,
  });

  final List<P6HistoryRow> rows;
  final void Function(P6HistoryRow row) onOpenFile;

  @override
  Widget build(BuildContext context) {
    final List<P6HistoryTableColumn> columns = p6HistoryTableColumns(
      onOpenFile: onOpenFile,
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
    List<P6HistoryTableColumn> columns,
    double viewport,
  ) {
    final double sum = columns.fold<double>(
      0,
      (double total, P6HistoryTableColumn column) => total + column.minWidth,
    );
    if (columns.isEmpty) {
      return const _ColumnLayout(widths: <double>[], total: 0);
    }
    if (!viewport.isFinite || viewport <= 0 || sum >= viewport) {
      return _ColumnLayout(
        widths: columns
            .map((P6HistoryTableColumn column) => column.minWidth)
            .toList(growable: false),
        total: sum,
      );
    }
    final double extra = (viewport - sum) / columns.length;
    return _ColumnLayout(
      widths: columns
          .map((P6HistoryTableColumn column) => column.minWidth + extra)
          .toList(growable: false),
      total: viewport,
    );
  }
}

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow({required this.columns, required this.widths})
    : assert(columns.length == widths.length);

  final List<P6HistoryTableColumn> columns;
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

  final P6HistoryRow row;
  final List<P6HistoryTableColumn> columns;
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
                  vertical: 10,
                ),
                child: _cell(context, columns[i]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, P6HistoryTableColumn column) {
    if (column.buildCell != null) {
      return column.buildCell!(context, row);
    }
    final String raw = column.read(row).trim();
    final TextStyle style =
        Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
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
