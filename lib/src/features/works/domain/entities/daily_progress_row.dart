import 'package:intl/intl.dart';

/// One structure-level row from `GET /execution/daily-progress`.
class DailyProgressRow {
  const DailyProgressRow({
    required this.unit,
    required this.plannedTillDate,
    required this.actualTillDate,
    required this.askingRatePerDay,
    required this.actualForDay,
    required this.cumulativeActual,
    required this.scope,
    required this.structure,
    required this.structureType,
    required this.section,
    required this.tdc,
    this.mpDeployment,
    this.manpowerDeployment,
  });

  final String unit;
  final double plannedTillDate;
  final double actualTillDate;
  final double askingRatePerDay;
  final double actualForDay;
  final double cumulativeActual;
  final double scope;
  final String structure;
  final String structureType;
  final String section;
  final DateTime? tdc;
  final String? mpDeployment;
  final String? manpowerDeployment;

  double get completedQty =>
      actualTillDate != 0 ? actualTillDate : cumulativeActual;

  double get balance => scope - completedQty;

  String get sectionFilterValue => _filterValue(section);

  String get activityFilterValue => _filterValue(structureType);

  String get tdcLabel {
    final DateTime? value = tdc;
    if (value == null) {
      return '—';
    }
    return _dateFormat.format(value);
  }

  String get mpLabel => _dashOr(mpDeployment);

  String get manpowerLabel => _dashOr(manpowerDeployment);

  factory DailyProgressRow.fromMap(Map<String, dynamic> map) {
    return DailyProgressRow(
      unit: _asString(map['unit']),
      plannedTillDate: _asDouble(map['planned_till_date']) ?? 0,
      actualTillDate: _asDouble(map['actual_till_date']) ?? 0,
      askingRatePerDay: _asDouble(map['asking_rate_per_day']) ?? 0,
      actualForDay: _asDouble(map['actual_for_day']) ?? 0,
      cumulativeActual: _asDouble(map['cumulative_actual']) ?? 0,
      scope: _asDouble(map['scope']) ?? 0,
      structure: _asDisplay(map['structure']),
      structureType: _asDisplay(map['structure_type']),
      section: _asDisplay(map['section']),
      tdc: _asDate(map['tdc']),
      mpDeployment: _asNullableString(
        map['mp_deployment'] ?? map['m_and_p'] ?? map['mp'],
      ),
      manpowerDeployment: _asNullableString(
        map['manpower_deployment'] ?? map['manpower'],
      ),
    );
  }

  static final DateFormat _dateFormat = DateFormat('dd-MM-yyyy');

  /// Indian grouping to match web / export samples (e.g. `2,39,244.40`).
  static String formatQty(double value) {
    final bool negative = value < 0;
    final double abs = value.abs();
    final String fixed = abs.toStringAsFixed(2);
    final List<String> parts = fixed.split('.');
    final String grouped = _indianGroup(parts[0]);
    final String out = '$grouped.${parts[1]}';
    return negative ? '-$out' : out;
  }

  static String _indianGroup(String digits) {
    if (digits.length <= 3) {
      return digits;
    }
    final StringBuffer buffer = StringBuffer();
    final String last3 = digits.substring(digits.length - 3);
    String rest = digits.substring(0, digits.length - 3);
    final List<String> chunks = <String>[];
    while (rest.length > 2) {
      chunks.add(rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) {
      chunks.add(rest);
    }
    for (int i = chunks.length - 1; i >= 0; i--) {
      buffer.write(chunks[i]);
      buffer.write(',');
    }
    buffer.write(last3);
    return buffer.toString();
  }

  static String _filterValue(String display) {
    final String trimmed = display.trim();
    if (trimmed.isEmpty || trimmed == 'N/A') {
      return 'N/A';
    }
    return trimmed;
  }

  static String _dashOr(String? value) {
    final String? text = value?.trim();
    if (text == null || text.isEmpty) {
      return '—';
    }
    return text;
  }

  static String _asDisplay(dynamic value) {
    final String text = _asString(value);
    return text.isEmpty ? 'N/A' : text;
  }

  static String _asString(dynamic value) {
    final String text = value?.toString().trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return '';
    }
    return text;
  }

  static String? _asNullableString(dynamic value) {
    if (value == null) {
      return null;
    }
    final String text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }
    return text;
  }

  static double? _asDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    final String text = value
        .toString()
        .trim()
        .replaceAll(',', '');
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }
    return double.tryParse(text);
  }

  static DateTime? _asDate(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is List && value.length >= 3) {
      final int? y = _asInt(value[0]);
      final int? m = _asInt(value[1]);
      final int? d = _asInt(value[2]);
      if (y == null || m == null || d == null) {
        return null;
      }
      return DateTime(y, m, d);
    }
    if (value is Map) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(value);
      final int? y = _asInt(map['year'] ?? map['y']);
      final int? m = _asInt(map['month'] ?? map['m']);
      final int? d = _asInt(map['day'] ?? map['d']);
      if (y != null && m != null && d != null) {
        return DateTime(y, m, d);
      }
    }
    final String text = value.toString().trim();
    if (text.isEmpty) {
      return null;
    }
    final DateTime? direct = DateTime.tryParse(text);
    if (direct != null) {
      return direct;
    }
    final Match? parts = RegExp(
      r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})$',
    ).firstMatch(text);
    if (parts != null) {
      final int d = int.parse(parts.group(1)!);
      final int m = int.parse(parts.group(2)!);
      final int y = int.parse(parts.group(3)!);
      return DateTime(y, m, d);
    }
    return null;
  }

  static int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString().trim() ?? '');
  }
}

/// Aggregated metrics shared by activity / section parent rows.
class DailyProgressTotals {
  const DailyProgressTotals({
    required this.unit,
    required this.scope,
    required this.completedQty,
    required this.askingRate,
    required this.progressOnDate,
    required this.structureCount,
    required this.tdc,
  });

  final String unit;
  final double scope;
  final double completedQty;
  final double askingRate;
  final double progressOnDate;
  final int structureCount;
  final DateTime? tdc;

  double get balance => scope - completedQty;

  String get tdcLabel {
    final DateTime? value = tdc;
    if (value == null) {
      return '—';
    }
    return DateFormat('dd-MM-yyyy').format(value);
  }

  String get structuresBadge =>
      '$structureCount Structure${structureCount == 1 ? '' : 's'}';

  factory DailyProgressTotals.fromRows(List<DailyProgressRow> rows) {
    if (rows.isEmpty) {
      return const DailyProgressTotals(
        unit: '',
        scope: 0,
        completedQty: 0,
        askingRate: 0,
        progressOnDate: 0,
        structureCount: 0,
        tdc: null,
      );
    }
    double scope = 0;
    double completed = 0;
    double asking = 0;
    double progress = 0;
    DateTime? latestTdc;
    final Map<String, int> unitCounts = <String, int>{};
    for (final DailyProgressRow row in rows) {
      scope += row.scope;
      completed += row.completedQty;
      asking += row.askingRatePerDay;
      progress += row.actualForDay;
      final String unit = row.unit.trim();
      if (unit.isNotEmpty) {
        unitCounts[unit] = (unitCounts[unit] ?? 0) + 1;
      }
      final DateTime? tdc = row.tdc;
      if (tdc != null && (latestTdc == null || tdc.isAfter(latestTdc))) {
        latestTdc = tdc;
      }
    }
    String unit = rows.first.unit;
    if (unitCounts.isNotEmpty) {
      unit = unitCounts.entries
          .reduce(
            (MapEntry<String, int> a, MapEntry<String, int> b) =>
                a.value >= b.value ? a : b,
          )
          .key;
    }
    return DailyProgressTotals(
      unit: unit,
      scope: scope,
      completedQty: completed,
      askingRate: asking,
      progressOnDate: progress,
      structureCount: rows.length,
      tdc: latestTdc,
    );
  }
}

class DailyProgressSectionGroup {
  const DailyProgressSectionGroup({
    required this.section,
    required this.structures,
    required this.totals,
  });

  final String section;
  final List<DailyProgressRow> structures;
  final DailyProgressTotals totals;
}

class DailyProgressActivityGroup {
  const DailyProgressActivityGroup({
    required this.activity,
    required this.sections,
    required this.totals,
  });

  final String activity;
  final List<DailyProgressSectionGroup> sections;
  final DailyProgressTotals totals;

  List<DailyProgressRow> get allStructures => sections
      .expand((DailyProgressSectionGroup s) => s.structures)
      .toList(growable: false);
}

List<DailyProgressActivityGroup> groupDailyProgress(
  List<DailyProgressRow> rows,
) {
  final Map<String, List<DailyProgressRow>> byActivity =
      <String, List<DailyProgressRow>>{};
  for (final DailyProgressRow row in rows) {
    byActivity
        .putIfAbsent(row.structureType, () => <DailyProgressRow>[])
        .add(row);
  }

  final List<String> activityKeys = byActivity.keys.toList()
    ..sort((String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()));

  return activityKeys.map((String activity) {
    final List<DailyProgressRow> activityRows = byActivity[activity]!;
    final Map<String, List<DailyProgressRow>> bySection =
        <String, List<DailyProgressRow>>{};
    for (final DailyProgressRow row in activityRows) {
      bySection
          .putIfAbsent(row.section, () => <DailyProgressRow>[])
          .add(row);
    }
    final List<String> sectionKeys = bySection.keys.toList()
      ..sort(
        (String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()),
      );
    final List<DailyProgressSectionGroup> sections = sectionKeys.map((
      String section,
    ) {
      final List<DailyProgressRow> structures = bySection[section]!;
      return DailyProgressSectionGroup(
        section: section,
        structures: structures,
        totals: DailyProgressTotals.fromRows(structures),
      );
    }).toList(growable: false);

    return DailyProgressActivityGroup(
      activity: activity,
      sections: sections,
      totals: DailyProgressTotals.fromRows(activityRows),
    );
  }).toList(growable: false);
}
