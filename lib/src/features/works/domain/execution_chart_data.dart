import 'dart:math' as math;

import 'package:swr_pmis_mobile/src/features/works/domain/entities/execution_progress_segment.dart';

class KmWindow {
  const KmWindow({required this.startKm, required this.endKm});

  final double startKm;
  final double endKm;
}

class ExecutionSectionBand {
  const ExecutionSectionBand({
    required this.name,
    required this.fromKm,
    required this.toKm,
  });

  final String name;
  final double fromKm;
  final double toKm;
}

class PlottedSegment {
  const PlottedSegment({required this.segment, required this.layer});

  final ExecutionProgressSegment segment;
  final int layer;
}

class ExecutionChartRow {
  const ExecutionChartRow({
    required this.serialNumber,
    required this.structureType,
    required this.segments,
  });

  final int serialNumber;
  final String structureType;
  final List<PlottedSegment> segments;

  int get layerCount {
    var maxLayer = 0;
    for (final PlottedSegment plotted in segments) {
      if (plotted.layer > maxLayer) {
        maxLayer = plotted.layer;
      }
    }
    return maxLayer + 1;
  }
}

class ExecutionChartData {
  const ExecutionChartData({
    required this.projectName,
    required this.fromKm,
    required this.toKm,
    required this.asOnLabel,
    required this.sections,
    required this.rows,
  });

  static const double windowKm = 75;

  final String projectName;
  final double fromKm;
  final double toKm;
  final String asOnLabel;
  final List<ExecutionSectionBand> sections;
  final List<ExecutionChartRow> rows;

  double get rangeKm => toKm - fromKm;

  bool get isEmpty => rows.isEmpty;

  double pixelsPerKm(double viewportWidth) {
    final double width = viewportWidth <= 0 ? 1 : viewportWidth;
    final double window = rangeKm <= windowKm ? rangeKm : windowKm;
    if (window <= 0) {
      return width;
    }
    return width / window;
  }

  double chartWidth(double viewportWidth) {
    return math.max(rangeKm * pixelsPerKm(viewportWidth), 1);
  }

  KmWindow visibleWindow({
    required double viewportWidth,
    required double scrollOffset,
  }) {
    final double ppk = pixelsPerKm(viewportWidth);
    final double spanKm = viewportWidth <= 0 ? rangeKm : viewportWidth / ppk;
    final double maxStart = math.max(fromKm, toKm - spanKm);
    final double start = (fromKm + math.max(0, scrollOffset) / ppk).clamp(
      fromKm,
      maxStart,
    );
    final double end = math.min(toKm, start + spanKm);
    return KmWindow(startKm: start, endKm: end);
  }

  String showingLabel({
    required double viewportWidth,
    required double scrollOffset,
  }) {
    final KmWindow window = visibleWindow(
      viewportWidth: viewportWidth,
      scrollOffset: scrollOffset,
    );
    return 'Showing KM ${window.startKm.toStringAsFixed(3)} — ${window.endKm.toStringAsFixed(3)}'
        '  |  Full range: ${fromKm.toStringAsFixed(3)} — ${toKm.toStringAsFixed(3)}'
        ' (${rangeKm.toStringAsFixed(3)} km)';
  }

  static ExecutionChartData fromSegments(
    List<ExecutionProgressSegment> segments, {
    DateTime? now,
    String fallbackName = '',
  }) {
    final DateTime clock = now ?? DateTime.now();
    if (segments.isEmpty) {
      return ExecutionChartData(
        projectName: fallbackName,
        fromKm: 0,
        toKm: 1,
        asOnLabel: formatAsOnDate(clock),
        sections: const <ExecutionSectionBand>[],
        rows: const <ExecutionChartRow>[],
      );
    }

    final ExecutionProgressSegment first = segments.first;
    final double maxPlot = segments
        .map((ExecutionProgressSegment item) => item.plotToKm)
        .reduce(math.max);
    final double minPlot = segments
        .map((ExecutionProgressSegment item) => item.plotFromKm)
        .reduce(math.min);

    double fromKm;
    double toKm;
    if (first.projectToKm > first.projectFromKm) {
      fromKm = first.projectFromKm;
      toKm = math.min(first.projectToKm, maxPlot);
      if (toKm <= fromKm) {
        toKm = first.projectToKm;
      }
    } else {
      fromKm = minPlot;
      toKm = maxPlot;
    }
    if (toKm <= fromKm) {
      toKm = fromKm + 1;
    }

    final String projectName = first.project.trim().isEmpty
        ? fallbackName
        : first.project.trim();

    final Map<String, List<ExecutionProgressSegment>> grouped =
        <String, List<ExecutionProgressSegment>>{};
    for (final ExecutionProgressSegment segment in segments) {
      final String type = segment.structureType.trim().isEmpty
          ? '—'
          : segment.structureType.trim();
      grouped
          .putIfAbsent(type, () => <ExecutionProgressSegment>[])
          .add(segment);
    }

    final List<ExecutionChartRow> rows = <ExecutionChartRow>[];
    var serial = 1;
    for (final MapEntry<String, List<ExecutionProgressSegment>> entry
        in grouped.entries) {
      rows.add(
        ExecutionChartRow(
          serialNumber: serial,
          structureType: entry.key,
          segments: _assignLayers(entry.value),
        ),
      );
      serial += 1;
    }

    return ExecutionChartData(
      projectName: projectName,
      fromKm: fromKm,
      toKm: toKm,
      asOnLabel: resolveAsOnLabel(segments, clock),
      sections: _sections(segments),
      rows: rows,
    );
  }

  static List<PlottedSegment> _assignLayers(
    List<ExecutionProgressSegment> segments,
  ) {
    final List<ExecutionProgressSegment> ordered =
        List<ExecutionProgressSegment>.from(segments)
          ..sort((ExecutionProgressSegment a, ExecutionProgressSegment b) {
            final int byStart = a.plotFromKm.compareTo(b.plotFromKm);
            if (byStart != 0) {
              return byStart;
            }
            final double aSpan = (a.plotToKm - a.plotFromKm).abs();
            final double bSpan = (b.plotToKm - b.plotFromKm).abs();
            return bSpan.compareTo(aSpan);
          });

    final List<List<ExecutionProgressSegment>> layers =
        <List<ExecutionProgressSegment>>[];
    final List<PlottedSegment> plotted = <PlottedSegment>[];
    for (final ExecutionProgressSegment segment in ordered) {
      var layer = 0;
      while (true) {
        if (layer == layers.length) {
          layers.add(<ExecutionProgressSegment>[]);
        }
        final bool overlaps = layers[layer].any(
          (ExecutionProgressSegment other) =>
              !(segment.plotToKm <= other.plotFromKm ||
                  segment.plotFromKm >= other.plotToKm),
        );
        if (!overlaps) {
          layers[layer].add(segment);
          plotted.add(PlottedSegment(segment: segment, layer: layer));
          break;
        }
        layer += 1;
      }
    }
    return plotted;
  }

  static List<ExecutionSectionBand> _sections(
    List<ExecutionProgressSegment> segments,
  ) {
    final Map<String, _SectionSpan> grouped = <String, _SectionSpan>{};
    for (final ExecutionProgressSegment segment in segments) {
      final String name = segment.projectSection.trim();
      if (name.isEmpty) {
        continue;
      }
      grouped
          .putIfAbsent(name, () => _SectionSpan())
          .add(segment.plotFromKm, segment.plotToKm);
    }
    final List<ExecutionSectionBand> bands =
        grouped.entries
            .map(
              (MapEntry<String, _SectionSpan> entry) => ExecutionSectionBand(
                name: entry.key,
                fromKm: entry.value.minKm,
                toKm: entry.value.maxKm,
              ),
            )
            .toList()
          ..sort(
            (ExecutionSectionBand a, ExecutionSectionBand b) =>
                a.fromKm.compareTo(b.fromKm),
          );
    return bands;
  }
}

class _SectionSpan {
  double minKm = double.infinity;
  double maxKm = double.negativeInfinity;

  void add(double fromKm, double toKm) {
    minKm = math.min(minKm, math.min(fromKm, toKm));
    maxKm = math.max(maxKm, math.max(fromKm, toKm));
  }
}

String formatAsOnDate(DateTime date) {
  final String day = date.day.toString().padLeft(2, '0');
  final String month = date.month.toString().padLeft(2, '0');
  return '$day-$month-${date.year}';
}

String resolveAsOnLabel(List<ExecutionProgressSegment> segments, DateTime now) {
  DateTime? latest;
  for (final ExecutionProgressSegment segment in segments) {
    final DateTime? parsed = parseProgressDate(segment.progressDate);
    if (parsed == null) {
      continue;
    }
    if (latest == null || parsed.isAfter(latest)) {
      latest = parsed;
    }
  }
  if (latest != null) {
    return formatAsOnDate(latest);
  }
  for (final ExecutionProgressSegment segment in segments) {
    final String raw = segment.progressDate.trim();
    if (raw.isNotEmpty) {
      return raw;
    }
  }
  return formatAsOnDate(now);
}

DateTime? parseProgressDate(String raw) {
  final String text = raw.trim();
  if (text.isEmpty) {
    return null;
  }
  final DateTime? iso = DateTime.tryParse(text);
  if (iso != null) {
    return iso;
  }
  final RegExpMatch? match = RegExp(
    r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})$',
  ).firstMatch(text);
  if (match == null) {
    return null;
  }
  final int? day = int.tryParse(match.group(1)!);
  final int? month = int.tryParse(match.group(2)!);
  final int? year = int.tryParse(match.group(3)!);
  if (day == null || month == null || year == null) {
    return null;
  }
  if (month < 1 || month > 12 || day < 1 || day > 31) {
    return null;
  }
  return DateTime(year, month, day);
}
