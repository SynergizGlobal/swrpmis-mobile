import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/entities/execution_progress_segment.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/execution_chart_data.dart';
import 'package:swr_pmis_mobile/src/features/works/presentation/execution_bar_style.dart';
import 'package:swr_pmis_mobile/src/features/works/presentation/widgets/execution_segment_sheet.dart';

class ExecutionProgressChart extends StatefulWidget {
  const ExecutionProgressChart({super.key, required this.data});

  final ExecutionChartData data;

  @override
  State<ExecutionProgressChart> createState() => _ExecutionProgressChartState();
}

class _ExecutionProgressChartState extends State<ExecutionProgressChart> {
  final ScrollController _scrollController = ScrollController();

  static const double _leftWidth = 156;
  static const double _serialWidth = 28;
  static const double _sectionHeight = 36;
  static const double _kmHeight = 24;
  static const double _layerPitch = 22;
  static const Color _headerColor = Color(0xFF1E4F8A);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double _rowHeight(ExecutionChartRow row) {
    return math.max(46, 12 + row.layerCount * _layerPitch);
  }

  double get _headerHeight {
    if (widget.data.sections.isEmpty) {
      return _kmHeight;
    }
    return _sectionHeight + _kmHeight;
  }

  @override
  Widget build(BuildContext context) {
    final ExecutionChartData data = widget.data;
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double offset = _scrollController.hasClients
        ? _scrollController.offset
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          data.projectName,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'As on ${data.asOnLabel}',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double viewport = math.max(
              0,
              constraints.maxWidth - _leftWidth,
            );
            return Text(
              data.showingLabel(viewportWidth: viewport, scrollOffset: offset),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppPalette.of(context).mutedText,
                fontWeight: FontWeight.w600,
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double viewport = math.max(
                  0,
                  constraints.maxWidth - _leftWidth,
                );
                final double chartWidth = data.chartWidth(viewport);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: _leftWidth,
                      child: Column(
                        children: <Widget>[
                          _LeftHeader(height: _headerHeight),
                          for (final ExecutionChartRow row in data.rows)
                            _LeftLabel(
                              row: row,
                              height: _rowHeight(row),
                              isDark: isDark,
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: chartWidth,
                          child: Column(
                            children: <Widget>[
                              _AxisHeader(
                                data: data,
                                width: chartWidth,
                                height: _headerHeight,
                              ),
                              for (final ExecutionChartRow row in data.rows)
                                _TimelineRow(
                                  data: data,
                                  row: row,
                                  width: chartWidth,
                                  height: _rowHeight(row),
                                  isDark: isDark,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _Legend(),
      ],
    );
  }
}

class _LeftHeader extends StatelessWidget {
  const _LeftHeader({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: _ExecutionProgressChartState._headerColor,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: const Row(
        children: <Widget>[
          SizedBox(
            width: _ExecutionProgressChartState._serialWidth,
            child: Text(
              'SN',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'STRUCTURE TYPE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeftLabel extends StatelessWidget {
  const _LeftLabel({
    required this.row,
    required this.height,
    required this.isDark,
  });

  final ExecutionChartRow row;
  final double height;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool even = row.serialNumber.isEven;
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: even
            ? (isDark ? const Color(0xFF16304F) : const Color(0xFFF4F7FB))
            : colors.surface,
        border: Border(
          top: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.8)),
        ),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: _ExecutionProgressChartState._serialWidth,
            child: Text(
              '${row.serialNumber}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              row.structureType,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AxisHeader extends StatelessWidget {
  const _AxisHeader({
    required this.data,
    required this.width,
    required this.height,
  });

  final ExecutionChartData data;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final double ppk = width / data.rangeKm;
    return SizedBox(
      height: height,
      width: width,
      child: ColoredBox(
        color: _ExecutionProgressChartState._headerColor,
        child: Stack(
          children: <Widget>[
            if (data.sections.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: _ExecutionProgressChartState._sectionHeight,
                child: Stack(
                  children: <Widget>[
                    for (var index = 0; index < data.sections.length; index++)
                      _sectionLabel(data.sections[index], ppk, index),
                  ],
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: _ExecutionProgressChartState._kmHeight,
              child: Stack(
                children: <Widget>[
                  for (final double km in _kmTicks(data, ppk))
                    _kmLabel(data, km, ppk),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(ExecutionSectionBand section, double ppk, int index) {
    final double left = ((section.fromKm - data.fromKm) * ppk).clamp(0, width);
    final double right = ((section.toKm - data.fromKm) * ppk).clamp(0, width);
    final double bandWidth = math.max(right - left, 24);
    return Positioned(
      left: left,
      width: math.min(bandWidth, width - left),
      top: 0,
      bottom: 0,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        color: index.isEven
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.08),
        child: Text(
          section.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
      ),
    );
  }

  Widget _kmLabel(ExecutionChartData data, double km, double ppk) {
    final String label = km == km.roundToDouble()
        ? km.toStringAsFixed(0)
        : km.toStringAsFixed(1);
    const double labelWidth = 36;
    final double left = ((km - data.fromKm) * ppk - labelWidth / 2).clamp(
      0.0,
      math.max(0, width - labelWidth),
    );
    return Positioned(
      left: left,
      width: labelWidth,
      top: 0,
      bottom: 0,
      child: Center(
        child: Text(
          label,
          maxLines: 1,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

List<double> _kmTicks(ExecutionChartData data, double ppk) {
  final double range = data.rangeKm;
  if (range <= 0) {
    return <double>[data.fromKm];
  }
  double step = 1;
  while (step * ppk < 56 && step < range) {
    step *= 2;
  }
  final List<double> ticks = <double>[data.fromKm];
  var km = (data.fromKm / step).ceil() * step;
  if ((km - data.fromKm).abs() < 0.001) {
    km += step;
  }
  while (km < data.toKm - step * 0.25) {
    ticks.add(km);
    km += step;
  }
  if ((ticks.last - data.toKm).abs() > 0.001) {
    ticks.add(data.toKm);
  }
  return ticks;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.data,
    required this.row,
    required this.width,
    required this.height,
    required this.isDark,
  });

  final ExecutionChartData data;
  final ExecutionChartRow row;
  final double width;
  final double height;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool even = row.serialNumber.isEven;
    final double ppk = width / data.rangeKm;
    return SizedBox(
      height: height,
      width: width,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: CustomPaint(
              painter: _BandPainter(
                data: data,
                evenRow: even,
                isDark: isDark,
                surface: colors.surface,
                divider: colors.outlineVariant.withValues(alpha: 0.7),
              ),
            ),
          ),
          for (final PlottedSegment plotted in row.segments)
            _SegmentBar(
              data: data,
              plotted: plotted,
              ppk: ppk,
              rowHeight: height,
              tallTick: plotted.segment.isPoint && row.layerCount == 1,
            ),
        ],
      ),
    );
  }
}

class _BandPainter extends CustomPainter {
  _BandPainter({
    required this.data,
    required this.evenRow,
    required this.isDark,
    required this.surface,
    required this.divider,
  });

  final ExecutionChartData data;
  final bool evenRow;
  final bool isDark;
  final Color surface;
  final Color divider;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint base = Paint()
      ..color = evenRow
          ? (isDark ? const Color(0xFF16304F) : const Color(0xFFF4F7FB))
          : surface;
    canvas.drawRect(Offset.zero & size, base);

    if (data.rangeKm <= 0) {
      return;
    }
    final double ppk = size.width / data.rangeKm;
    final Paint shade = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.04)
          : const Color(0xFFE7EDF5);
    for (var index = 0; index < data.sections.length; index++) {
      if (index.isOdd) {
        continue;
      }
      final ExecutionSectionBand section = data.sections[index];
      final double left = (section.fromKm - data.fromKm) * ppk;
      final double right = (section.toKm - data.fromKm) * ppk;
      canvas.drawRect(
        Rect.fromLTRB(left, 0, math.max(right, left + 1), size.height),
        shade,
      );
    }

    final Paint line = Paint()
      ..color = divider
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, 0), Offset(size.width, 0), line);
    for (final ExecutionSectionBand section in data.sections) {
      final double x = (section.fromKm - data.fromKm) * ppk;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
  }

  @override
  bool shouldRepaint(covariant _BandPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.evenRow != evenRow ||
        oldDelegate.isDark != isDark;
  }
}

class _SegmentBar extends StatelessWidget {
  const _SegmentBar({
    required this.data,
    required this.plotted,
    required this.ppk,
    required this.rowHeight,
    required this.tallTick,
  });

  final ExecutionChartData data;
  final PlottedSegment plotted;
  final double ppk;
  final double rowHeight;
  final bool tallTick;

  @override
  Widget build(BuildContext context) {
    final ExecutionProgressSegment segment = plotted.segment;
    final Color color = executionSegmentColor(
      barColor: segment.barColor,
      status: segment.status,
      progress: segment.progress,
    );
    final double start = (segment.plotFromKm - data.fromKm) * ppk;
    final double end = (segment.plotToKm - data.fromKm) * ppk;
    final double rawWidth = (end - start).abs();
    final double left = math.min(start, end);
    final double top = tallTick
        ? 6
        : 8 + plotted.layer * _ExecutionProgressChartState._layerPitch;
    final double barHeight = tallTick ? math.max(20, rowHeight - 12) : 14;
    final double barWidth = segment.isPoint ? 6 : math.max(rawWidth, 3);

    return Positioned(
      left: segment.isPoint ? left - 8 : left,
      top: top,
      width: segment.isPoint ? 22 : math.max(barWidth, 18),
      height: math.max(barHeight, 24),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () =>
            showExecutionSegmentSheet(context: context, segment: segment),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: barWidth,
            height: barHeight,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(segment.isPoint ? 1 : 3),
              border: Border.all(color: Colors.black.withValues(alpha: 0.2)),
            ),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: executionLegendItems.map((ExecutionLegendItem item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 18,
              height: 12,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: colors.outline.withValues(alpha: 0.4),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              item.label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        );
      }).toList(),
    );
  }
}
