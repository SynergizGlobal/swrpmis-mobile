import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_assign_executive.dart';

class RfiAssignExecutiveTable extends StatelessWidget {
  const RfiAssignExecutiveTable({
    super.key,
    required this.rows,
    required this.onRefresh,
    required this.onDelete,
    required this.deletingId,
  });

  final List<RfiAssignExecutiveLog> rows;
  final Future<void> Function() onRefresh;
  final ValueChanged<RfiAssignExecutiveLog> onDelete;
  final int? deletingId;

  static const List<_AssignColumn> _columns = <_AssignColumn>[
    _AssignColumn('Contract', 180),
    _AssignColumn('Structure Type', 140),
    _AssignColumn('Structure', 170),
    _AssignColumn('Assigned Executive', 190),
    _AssignColumn('Action', 88),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewport = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 0;
        final double height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 480;
        final _ColumnLayout layout = _ColumnLayout.fit(_columns, viewport);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: SizedBox(
            width: math.max(layout.total, viewport),
            height: height,
            child: RefreshIndicator(
              onRefresh: onRefresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: <Widget>[
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _HeaderDelegate(
                      columns: _columns,
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
                        widths: layout.widths,
                        index: index,
                        deletingId: deletingId,
                        onDelete: onDelete,
                      );
                    }, childCount: rows.length),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 88)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AssignColumn {
  const _AssignColumn(this.label, this.minWidth);

  final String label;
  final double minWidth;
}

class _ColumnLayout {
  const _ColumnLayout({required this.widths, required this.total});

  final List<double> widths;
  final double total;

  factory _ColumnLayout.fit(List<_AssignColumn> columns, double viewport) {
    final double sum = columns.fold<double>(
      0,
      (double total, _AssignColumn column) => total + column.minWidth,
    );
    if (columns.isEmpty) {
      return const _ColumnLayout(widths: <double>[], total: 0);
    }
    if (!viewport.isFinite || viewport <= 0 || sum >= viewport) {
      return _ColumnLayout(
        widths: columns
            .map((_AssignColumn column) => column.minWidth)
            .toList(growable: false),
        total: sum,
      );
    }
    final double extra = (viewport - sum) / columns.length;
    return _ColumnLayout(
      widths: columns
          .map((_AssignColumn column) => column.minWidth + extra)
          .toList(growable: false),
      total: viewport,
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate({required this.columns, required this.widths})
    : assert(columns.length == widths.length);

  final List<_AssignColumn> columns;
  final List<double> widths;

  static const double _height = 44;

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
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    columns[i].label,
                    maxLines: 2,
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
    required this.widths,
    required this.index,
    required this.deletingId,
    required this.onDelete,
  });

  final RfiAssignExecutiveLog row;
  final List<double> widths;
  final int index;
  final int? deletingId;
  final ValueChanged<RfiAssignExecutiveLog> onDelete;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color background = index.isEven
        ? (dark ? const Color(0xFF122844) : AppTheme.surfaceLight)
        : (dark ? const Color(0xFF0E1F36) : AppTheme.scaffoldLight);
    final List<String> values = <String>[
      _cell(row.contract),
      _cell(row.structureType),
      _cell(row.structure),
      _cell(row.assignedExecutive),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border(
          bottom: BorderSide(color: AppPalette.of(context).borderSubtle),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < values.length; i++)
            SizedBox(
              width: widths[i],
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                child: Text(
                  values[i],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          SizedBox(
            width: widths[4],
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: WidgetStatePropertyAll<Size>(Size(0, 28)),
                    padding: WidgetStatePropertyAll<EdgeInsets>(
                      EdgeInsets.symmetric(horizontal: 10),
                    ),
                    backgroundColor: WidgetStateProperty.resolveWith((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.disabled)) {
                        return AppTheme.railwayRed.withValues(alpha: 0.38);
                      }
                      return AppTheme.railwayRed;
                    }),
                    foregroundColor: WidgetStatePropertyAll<Color>(
                      Colors.white,
                    ),
                    textStyle: WidgetStatePropertyAll<TextStyle>(
                      TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                  onPressed: row.id == null || deletingId != null
                      ? null
                      : () => onDelete(row),
                  child: deletingId != null && deletingId == row.id
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Delete'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _cell(String value) {
  final String text = value.trim();
  return text.isEmpty ? '—' : text;
}
