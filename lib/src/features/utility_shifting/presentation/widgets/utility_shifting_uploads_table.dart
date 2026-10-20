import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/widgets/paged_table_column.dart';
import 'package:swr_pmis_mobile/src/features/utility_shifting/domain/utility_shifting_list.dart';

class UtilityShiftingUploadTableColumn {
  const UtilityShiftingUploadTableColumn({
    required this.label,
    required this.minWidth,
    required this.read,
    this.buildCell,
  });

  final String label;
  final double minWidth;
  final String Function(UtilityShiftingUploadRow row) read;
  final Widget Function(BuildContext context, UtilityShiftingUploadRow row)?
  buildCell;
}

List<UtilityShiftingUploadTableColumn> utilityShiftingUploadTableColumns({
  required void Function(UtilityShiftingUploadRow row) onOpenFile,
}) {
  return <UtilityShiftingUploadTableColumn>[
    UtilityShiftingUploadTableColumn(
      label: 'Uploaded File',
      minWidth: 220,
      read: _file,
      buildCell: (BuildContext context, UtilityShiftingUploadRow row) {
        final String name = row.uploadedFile.trim();
        if (name.isEmpty) {
          return const SizedBox.shrink();
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
    UtilityShiftingUploadTableColumn(
      label: 'Status',
      minWidth: 100,
      read: _status,
      buildCell: (BuildContext context, UtilityShiftingUploadRow row) {
        return _StatusText(status: row.status);
      },
    ),
    const UtilityShiftingUploadTableColumn(
      label: 'Remarks',
      minWidth: 220,
      read: _remarks,
    ),
    const UtilityShiftingUploadTableColumn(
      label: 'Uploaded by',
      minWidth: 130,
      read: _uploadedBy,
    ),
    const UtilityShiftingUploadTableColumn(
      label: 'Uploaded On',
      minWidth: 150,
      read: _uploadedOn,
    ),
  ];
}

String _file(UtilityShiftingUploadRow row) => row.uploadedFile;

String _status(UtilityShiftingUploadRow row) => row.status;

String _remarks(UtilityShiftingUploadRow row) => row.remarks;

String _uploadedBy(UtilityShiftingUploadRow row) => row.uploadedBy;

String _uploadedOn(UtilityShiftingUploadRow row) => row.uploadedOn;

class UtilityShiftingUploadsTable extends StatelessWidget {
  const UtilityShiftingUploadsTable({
    super.key,
    required this.rows,
    required this.onOpenFile,
  });

  final List<UtilityShiftingUploadRow> rows;
  final void Function(UtilityShiftingUploadRow row) onOpenFile;

  @override
  Widget build(BuildContext context) {
    final List<UtilityShiftingUploadTableColumn> columns =
        utilityShiftingUploadTableColumns(onOpenFile: onOpenFile);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewport = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 0;
        final _ColumnLayout layout = _ColumnLayout.fit(columns, viewport);
        return TableScrollFrame(
          width: math.max(layout.total, viewport),
          slivers: <Widget>[
            SliverPersistentHeader(
              pinned: true,
              delegate: _HeaderDelegate(
                columns: columns,
                widths: layout.widths,
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((
                BuildContext context,
                int index,
              ) {
                return _DataRow(
                  row: rows[index],
                  columns: columns,
                  widths: layout.widths,
                  index: index,
                );
              }, childCount: rows.length),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
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
    List<UtilityShiftingUploadTableColumn> columns,
    double viewport,
  ) {
    final double sum = columns.fold<double>(
      0,
      (double total, UtilityShiftingUploadTableColumn column) =>
          total + column.minWidth,
    );
    if (columns.isEmpty) {
      return const _ColumnLayout(widths: <double>[], total: 0);
    }
    if (!viewport.isFinite || viewport <= 0 || sum >= viewport) {
      return _ColumnLayout(
        widths: columns
            .map(
              (UtilityShiftingUploadTableColumn column) => column.minWidth,
            )
            .toList(growable: false),
        total: sum,
      );
    }
    final double extra = (viewport - sum) / columns.length;
    return _ColumnLayout(
      widths: columns
          .map(
            (UtilityShiftingUploadTableColumn column) =>
                column.minWidth + extra,
          )
          .toList(growable: false),
      total: viewport,
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate({required this.columns, required this.widths})
    : assert(columns.length == widths.length);

  final List<UtilityShiftingUploadTableColumn> columns;
  final List<double> widths;

  static const double _height = 52;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
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

  @override
  bool shouldRebuild(covariant _HeaderDelegate oldDelegate) {
    if (oldDelegate.columns.length != columns.length) {
      return true;
    }
    for (int i = 0; i < columns.length; i++) {
      if (oldDelegate.columns[i].label != columns[i].label ||
          oldDelegate.widths[i] != widths[i]) {
        return true;
      }
    }
    return false;
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.row,
    required this.columns,
    required this.widths,
    required this.index,
  });

  final UtilityShiftingUploadRow row;
  final List<UtilityShiftingUploadTableColumn> columns;
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
                child: _cell(context, columns[i]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, UtilityShiftingUploadTableColumn column) {
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

class _StatusText extends StatelessWidget {
  const _StatusText({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final String normalized = status.trim().toLowerCase();
    Color color = Theme.of(context).colorScheme.onSurface;
    if (normalized == 'pass' || normalized == 'success') {
      color = Colors.green.shade700;
    } else if (normalized == 'fail' ||
        normalized == 'failed' ||
        normalized == 'error') {
      color = AppTheme.railwayRed;
    }
    final String raw = status.trim();
    return Text(
      raw.isEmpty ? '—' : raw,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
    );
  }
}

String _softBreak(String text) {
  return text.replaceAllMapped(RegExp(r'[_/\-]'), (Match match) {
    return '${match[0]}\u200B';
  });
}
