import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';

class RfiReferenceColumn {
  const RfiReferenceColumn(this.label, this.minWidth);

  final String label;
  final double minWidth;
}

class RfiReferenceTable extends StatelessWidget {
  const RfiReferenceTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.actionBuilder,
  });

  final List<RfiReferenceColumn> columns;
  final List<List<String>> rows;
  final Widget Function(BuildContext context, int index) actionBuilder;

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
        final _ColumnLayout layout = _ColumnLayout.fit(columns, viewport);
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(
            context,
          ).copyWith(overscroll: false, physics: const ClampingScrollPhysics()),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: SizedBox(
              width: math.max(layout.total, viewport),
              height: height,
              child: CustomScrollView(
                physics: const ClampingScrollPhysics(),
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
                        values: rows[index],
                        widths: layout.widths,
                        index: index,
                        action: actionBuilder(context, index),
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

class _ColumnLayout {
  const _ColumnLayout({required this.widths, required this.total});

  final List<double> widths;
  final double total;

  factory _ColumnLayout.fit(List<RfiReferenceColumn> columns, double viewport) {
    final double sum = columns.fold<double>(
      0,
      (double total, RfiReferenceColumn column) => total + column.minWidth,
    );
    if (columns.isEmpty) {
      return const _ColumnLayout(widths: <double>[], total: 0);
    }
    if (!viewport.isFinite || viewport <= 0 || sum >= viewport) {
      return _ColumnLayout(
        widths: columns
            .map((RfiReferenceColumn column) => column.minWidth)
            .toList(growable: false),
        total: sum,
      );
    }
    final double extra = (viewport - sum) / columns.length;
    return _ColumnLayout(
      widths: columns
          .map((RfiReferenceColumn column) => column.minWidth + extra)
          .toList(growable: false),
      total: viewport,
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate({required this.columns, required this.widths})
    : assert(columns.length == widths.length);

  final List<RfiReferenceColumn> columns;
  final List<double> widths;

  static const double _height = 48;

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
    required this.values,
    required this.widths,
    required this.index,
    required this.action,
  });

  final List<String> values;
  final List<double> widths;
  final int index;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color background = index.isEven
        ? (dark ? const Color(0xFF122844) : AppTheme.surfaceLight)
        : (dark ? const Color(0xFF0E1F36) : AppTheme.scaffoldLight);
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
                  _cell(values[i]),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          SizedBox(
            width: widths[values.length],
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: action,
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
