import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_log_row.dart';

class RfiLogTable extends StatelessWidget {
  const RfiLogTable({
    super.key,
    required this.rows,
    required this.onRefresh,
    required this.onPreview,
    required this.onDownload,
    this.downloadingRow,
  });

  final List<RfiLogRow> rows;
  final Future<void> Function() onRefresh;
  final ValueChanged<RfiLogRow> onPreview;
  final ValueChanged<RfiLogRow> onDownload;
  final RfiLogRow? downloadingRow;

  static const List<_LogColumn> _columns = <_LogColumn>[
    _LogColumn('RFI Category', 120),
    _LogColumn('RFI ID', 196),
    _LogColumn('RFI Raised Date', 132),
    _LogColumn('ID Of Structure', 150),
    _LogColumn('RFI Description', 160),
    _LogColumn('Contractor Representative', 168, group: 'RFI Sent To'),
    _LogColumn("Employer's Engineer", 150, group: 'RFI Sent To'),
    _LogColumn('Contractor', 120, group: 'Date Responded'),
    _LogColumn('Engineer', 110, group: 'Date Responded'),
    _LogColumn('Status', 150),
    _LogColumn('Notes', 110),
    _LogColumn('Preview', 72, group: 'View'),
    _LogColumn('Download', 88, group: 'View'),
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
        final double sum = _columns.fold<double>(
          0,
          (double total, _LogColumn column) => total + column.width,
        );
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: SizedBox(
            width: math.max(sum, viewport),
            height: height,
            child: RefreshIndicator(
              onRefresh: onRefresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: <Widget>[
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _LogHeaderDelegate(columns: _columns),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((
                      BuildContext context,
                      int index,
                    ) {
                      return _LogDataRow(
                        row: rows[index],
                        index: index,
                        onPreview: onPreview,
                        onDownload: onDownload,
                        downloadingRow: downloadingRow,
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

class _LogColumn {
  const _LogColumn(this.label, this.width, {this.group});

  final String label;
  final double width;
  final String? group;
}

class _LogHeaderDelegate extends SliverPersistentHeaderDelegate {
  _LogHeaderDelegate({required this.columns});

  final List<_LogColumn> columns;

  static const double _height = 64;

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
    final List<Widget> cells = <Widget>[];
    int index = 0;
    while (index < columns.length) {
      final _LogColumn column = columns[index];
      final String? group = column.group;
      if (group == null) {
        cells.add(_spanLabel(column.label, column.width, twoRows: true));
        index += 1;
        continue;
      }
      double width = 0;
      final List<_LogColumn> members = <_LogColumn>[];
      while (index < columns.length && columns[index].group == group) {
        members.add(columns[index]);
        width += columns[index].width;
        index += 1;
      }
      cells.add(
        SizedBox(
          width: width,
          height: _height,
          child: Column(
            children: <Widget>[
              SizedBox(
                height: 28,
                child: Center(child: Text(group, style: _headerStyle)),
              ),
              const Divider(height: 1, thickness: 1, color: Colors.white24),
              SizedBox(
                height: 35,
                child: Row(
                  children: <Widget>[
                    for (final _LogColumn member in members)
                      _spanLabel(member.label, member.width, twoRows: false),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ColoredBox(
      color: AppTheme.brandPrimary,
      child: Row(children: cells),
    );
  }

  @override
  bool shouldRebuild(covariant _LogHeaderDelegate oldDelegate) => false;
}

const TextStyle _headerStyle = TextStyle(
  color: Colors.white,
  fontSize: 11,
  fontWeight: FontWeight.w700,
  height: 1.15,
);

Widget _spanLabel(String label, double width, {required bool twoRows}) {
  return SizedBox(
    width: width,
    height: twoRows ? 64 : 35,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(label, maxLines: 2, style: _headerStyle),
      ),
    ),
  );
}

class _LogDataRow extends StatelessWidget {
  const _LogDataRow({
    required this.row,
    required this.index,
    required this.onPreview,
    required this.onDownload,
    required this.downloadingRow,
  });

  final RfiLogRow row;
  final int index;
  final ValueChanged<RfiLogRow> onPreview;
  final ValueChanged<RfiLogRow> onDownload;
  final RfiLogRow? downloadingRow;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color background = index.isEven
        ? (dark ? const Color(0xFF122844) : AppTheme.surfaceLight)
        : (dark ? const Color(0xFF0E1F36) : AppTheme.scaffoldLight);
    final List<String> values = <String>[
      rfiLogCell(row.rfiCategory),
      rfiLogCell(row.rfiId),
      rfiLogCell(row.dateRaised),
      rfiLogCell(row.structure),
      rfiLogCell(row.rfiDescription),
      rfiLogCell(row.nameOfRepresentative),
      rfiLogCell(row.person),
      rfiLogCell(row.conRespondedDate),
      rfiLogCell(row.enggRespondedDate),
      row.statusLabel,
      rfiLogCell(row.notes),
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
              width: RfiLogTable._columns[i].width,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                child: Text(
                  _softBreak(values[i]),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: i == 1 || i == 9
                        ? FontWeight.w800
                        : FontWeight.w600,
                    height: 1.3,
                    color: i == 1
                        ? (dark
                              ? const Color(0xFF9DC0F0)
                              : AppTheme.brandPrimary)
                        : null,
                  ),
                ),
              ),
            ),
          SizedBox(
            width: RfiLogTable._columns[11].width,
            child: IconButton(
              tooltip: 'Preview',
              visualDensity: VisualDensity.compact,
              onPressed: row.id == null ? null : () => onPreview(row),
              icon: const Icon(Icons.visibility_outlined, size: 20),
            ),
          ),
          SizedBox(
            width: RfiLogTable._columns[12].width,
            child: IconButton(
              tooltip: 'Download',
              visualDensity: VisualDensity.compact,
              onPressed: downloadingRow != null ? null : () => onDownload(row),
              icon: identical(downloadingRow, row)
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : const Icon(Icons.download_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

String _softBreak(String text) {
  return text.replaceAllMapped(RegExp(r'[_/\-]'), (Match match) {
    return '${match[0]}\u200B';
  });
}
