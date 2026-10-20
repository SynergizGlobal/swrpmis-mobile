import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/widgets/paged_table_column.dart';
import 'package:swr_pmis_mobile/src/features/rdso/domain/rdso_list.dart';
import 'package:swr_pmis_mobile/src/features/rdso/domain/rdso_parse.dart';

class RdsoRevisionTableColumn {
  const RdsoRevisionTableColumn({
    required this.label,
    required this.minWidth,
    required this.read,
    this.buildCell,
  });

  final String label;
  final double minWidth;
  final String Function(RdsoDrawingRow row) read;
  final Widget Function(BuildContext context, RdsoDrawingRow row)? buildCell;
}

List<RdsoRevisionTableColumn> rdsoLibraryTableColumns({
  required void Function(RdsoDrawingRow row) onOpen,
}) {
  return <RdsoRevisionTableColumn>[
    const RdsoRevisionTableColumn(
      label: 'Drawing No.',
      minWidth: 140,
      read: _drawingNo,
    ),
    const RdsoRevisionTableColumn(label: 'Title', minWidth: 180, read: _title),
    const RdsoRevisionTableColumn(
      label: 'Department',
      minWidth: 120,
      read: _department,
    ),
    const RdsoRevisionTableColumn(label: 'Rev.', minWidth: 72, read: _revision),
    const RdsoRevisionTableColumn(
      label: 'Rev. Date',
      minWidth: 110,
      read: _revisionDate,
    ),
    RdsoRevisionTableColumn(
      label: 'Status',
      minWidth: 100,
      read: _status,
      buildCell: (BuildContext context, RdsoDrawingRow row) {
        return _StatusBadge(status: row.status);
      },
    ),
    const RdsoRevisionTableColumn(
      label: 'File Size',
      minWidth: 90,
      read: _fileSize,
    ),
    RdsoRevisionTableColumn(
      label: 'Action',
      minWidth: 56,
      read: _blank,
      buildCell: (BuildContext context, RdsoDrawingRow row) {
        return Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            tooltip: 'Open drawing',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            onPressed: () => onOpen(row),
            icon: Icon(
              Icons.visibility_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      },
    ),
  ];
}

List<RdsoRevisionTableColumn> rdsoRevisionTableColumns({
  required void Function(RdsoDrawingRow row) onPreview,
  required void Function(RdsoDrawingRow row) onDownload,
  required RdsoDrawingRow? busyRow,
}) {
  return <RdsoRevisionTableColumn>[
    const RdsoRevisionTableColumn(
      label: 'Drawing No.',
      minWidth: 140,
      read: _drawingNo,
    ),
    const RdsoRevisionTableColumn(label: 'Title', minWidth: 180, read: _title),
    const RdsoRevisionTableColumn(
      label: 'Department',
      minWidth: 120,
      read: _department,
    ),
    const RdsoRevisionTableColumn(label: 'Rev.', minWidth: 72, read: _revision),
    const RdsoRevisionTableColumn(
      label: 'Rev. Date',
      minWidth: 110,
      read: _revisionDate,
    ),
    RdsoRevisionTableColumn(
      label: 'Status',
      minWidth: 100,
      read: _status,
      buildCell: (BuildContext context, RdsoDrawingRow row) {
        return _StatusBadge(status: row.status);
      },
    ),
    const RdsoRevisionTableColumn(
      label: 'File Size',
      minWidth: 90,
      read: _fileSize,
    ),
    RdsoRevisionTableColumn(
      label: 'Action',
      minWidth: 96,
      read: _blank,
      buildCell: (BuildContext context, RdsoDrawingRow row) {
        return _Actions(
          enabled: row.hasFile,
          busy: identical(busyRow, row),
          onPreview: () => onPreview(row),
          onDownload: () => onDownload(row),
        );
      },
    ),
  ];
}

String _drawingNo(RdsoDrawingRow row) => row.drawingKey;

String _title(RdsoDrawingRow row) => row.title;

String _department(RdsoDrawingRow row) => row.department;

String _revision(RdsoDrawingRow row) => row.revision;

String _revisionDate(RdsoDrawingRow row) => row.revisionDate;

String _status(RdsoDrawingRow row) => row.status;

String _fileSize(RdsoDrawingRow row) => formatRdsoFileSize(row.fileSize);

String _blank(RdsoDrawingRow row) => '';

class RdsoLibraryDrawingsTable extends StatelessWidget {
  const RdsoLibraryDrawingsTable({
    super.key,
    required this.rows,
    required this.onOpen,
  });

  final List<RdsoDrawingRow> rows;
  final void Function(RdsoDrawingRow row) onOpen;

  @override
  Widget build(BuildContext context) {
    return _rdsoTableLayout(
      context: context,
      rows: rows,
      columns: rdsoLibraryTableColumns(onOpen: onOpen),
      onRowTap: onOpen,
    );
  }
}

class RdsoRevisionTable extends StatelessWidget {
  const RdsoRevisionTable({
    super.key,
    required this.rows,
    required this.onPreview,
    required this.onDownload,
    this.busyRow,
  });

  final List<RdsoDrawingRow> rows;
  final void Function(RdsoDrawingRow row) onPreview;
  final void Function(RdsoDrawingRow row) onDownload;
  final RdsoDrawingRow? busyRow;

  @override
  Widget build(BuildContext context) {
    final List<RdsoRevisionTableColumn> columns = rdsoRevisionTableColumns(
      onPreview: onPreview,
      onDownload: onDownload,
      busyRow: busyRow,
    );
    return _rdsoTableLayout(
      context: context,
      rows: rows,
      columns: columns,
    );
  }
}

Widget _rdsoTableLayout({
  required BuildContext context,
  required List<RdsoDrawingRow> rows,
  required List<RdsoRevisionTableColumn> columns,
  void Function(RdsoDrawingRow row)? onRowTap,
}) {
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
                onTap: onRowTap == null ? null : () => onRowTap(rows[index]),
              );
            }, childCount: rows.length),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      );
    },
  );
}

class _ColumnLayout {
  const _ColumnLayout({required this.widths, required this.total});

  final List<double> widths;
  final double total;

  factory _ColumnLayout.fit(
    List<RdsoRevisionTableColumn> columns,
    double viewport,
  ) {
    final double sum = columns.fold<double>(
      0,
      (double total, RdsoRevisionTableColumn column) => total + column.minWidth,
    );
    if (columns.isEmpty) {
      return const _ColumnLayout(widths: <double>[], total: 0);
    }
    if (!viewport.isFinite || viewport <= 0 || sum >= viewport) {
      return _ColumnLayout(
        widths: columns
            .map((RdsoRevisionTableColumn column) => column.minWidth)
            .toList(growable: false),
        total: sum,
      );
    }
    final double extra = (viewport - sum) / columns.length;
    return _ColumnLayout(
      widths: columns
          .map((RdsoRevisionTableColumn column) => column.minWidth + extra)
          .toList(growable: false),
      total: viewport,
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate({required this.columns, required this.widths})
    : assert(columns.length == widths.length);

  final List<RdsoRevisionTableColumn> columns;
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
    this.onTap,
  });

  final RdsoDrawingRow row;
  final List<RdsoRevisionTableColumn> columns;
  final List<double> widths;
  final int index;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color background = index.isEven
        ? (dark ? const Color(0xFF122844) : AppTheme.surfaceLight)
        : (dark ? const Color(0xFF0E1F36) : AppTheme.scaffoldLight);
    final Color line = AppPalette.of(context).borderSubtle;
    return Material(
      color: background,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
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
        ),
      ),
    );
  }

  Widget _cell(
    BuildContext context,
    RdsoRevisionTableColumn column,
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final String label = status.trim();
    if (label.isEmpty) {
      return Text(
        '—',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      );
    }
    final AppPalette palette = AppPalette.of(context);
    final bool current = label.toLowerCase() == 'current';
    final Color fill = current
        ? palette.success.withValues(alpha: 0.16)
        : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.55);
    final Color foreground = current
        ? palette.success
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.enabled,
    required this.busy,
    required this.onPreview,
    required this.onDownload,
  });

  final bool enabled;
  final bool busy;
  final VoidCallback onPreview;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return Text(
        '—',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      );
    }
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  tooltip: 'View file',
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 36,
                    height: 36,
                  ),
                  onPressed: onPreview,
                  icon: Icon(
                    Icons.visibility_rounded,
                    size: 20,
                    color: colors.primary,
                  ),
                ),
                IconButton(
                  tooltip: 'Download file',
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 36,
                    height: 36,
                  ),
                  onPressed: onDownload,
                  icon: Icon(
                    Icons.download_rounded,
                    size: 20,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
    );
  }
}
