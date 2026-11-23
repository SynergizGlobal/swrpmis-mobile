import 'package:intl/intl.dart';

class ExceptionReportSummary {
  const ExceptionReportSummary({
    required this.structuresMonitored,
    required this.criticalExceptions,
    required this.generalDrawingsPending,
    required this.detailedDrawingsPending,
    required this.utilityShiftingImpacted,
  });

  final int structuresMonitored;
  final int criticalExceptions;
  final int generalDrawingsPending;
  final int detailedDrawingsPending;
  final int utilityShiftingImpacted;

  factory ExceptionReportSummary.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const ExceptionReportSummary(
        structuresMonitored: 0,
        criticalExceptions: 0,
        generalDrawingsPending: 0,
        detailedDrawingsPending: 0,
        utilityShiftingImpacted: 0,
      );
    }
    return ExceptionReportSummary(
      structuresMonitored: _asInt(map['structuresMonitored']),
      criticalExceptions: _asInt(map['criticalExceptions']),
      generalDrawingsPending: _asInt(map['generalDrawingsPending']),
      detailedDrawingsPending: _asInt(map['detailedDrawingsPending']),
      utilityShiftingImpacted: _asInt(map['utilityShiftingImpacted']),
    );
  }
}

class ExceptionReportStructure {
  const ExceptionReportStructure({
    required this.id,
    required this.name,
    required this.type,
    required this.unit,
    required this.scope,
    required this.actual,
    required this.issues,
    required this.actualKm,
    required this.contract,
    required this.exception,
    required this.contractId,
    required this.frontTotal,
    required this.utilityDone,
    required this.utilityTotal,
    required this.frontAvailable,
    required this.generalDrawing,
    required this.detailedDrawing,
    required this.tdc,
  });

  final int id;
  final String name;
  final String type;
  final String unit;
  final String scope;
  final double actual;
  final int issues;
  final double? actualKm;
  final String contract;
  final String exception;
  final String contractId;
  final double? frontTotal;
  final double? utilityDone;
  final double? utilityTotal;
  final double? frontAvailable;
  final String? generalDrawing;
  final String? detailedDrawing;
  final DateTime? tdc;

  static final DateFormat _tdcFormat = DateFormat('dd MMM yyyy');

  String get generalDrawingLabel => _drawingLabel(generalDrawing);

  String get detailedDrawingLabel => _drawingLabel(detailedDrawing);

  DrawingStatusDot get generalDrawingDot => _drawingDot(generalDrawing);

  DrawingStatusDot get detailedDrawingDot => _drawingDot(detailedDrawing);

  String get tdcLabel {
    final DateTime? value = tdc;
    if (value == null) {
      return '—';
    }
    return _tdcFormat.format(value);
  }

  String get frontAvailableLabel {
    if (frontAvailable == null && frontTotal == null) {
      return '—';
    }
    final String ratio =
        '${_fmtNum(frontAvailable)} / ${_fmtNum(frontTotal)}';
    final String trimmedUnit = unit.trim();
    if (trimmedUnit.isEmpty) {
      return ratio;
    }
    return '$ratio $trimmedUnit';
  }

  String get utilityShiftingLabel {
    if (utilityDone == null && utilityTotal == null) {
      return '—';
    }
    final String ratio = '${_fmtNum(utilityDone)} / ${_fmtNum(utilityTotal)}';
    final String trimmedUnit = unit.trim();
    if (trimmedUnit.isEmpty) {
      return ratio;
    }
    return '$ratio $trimmedUnit';
  }

  /// Primary progress label: km when [actualKm] is present, else percent.
  String get actualProgressLabel {
    if (actualKm != null && unit.trim().toLowerCase() == 'km') {
      return '${_fmtNum(actualKm, maxDecimals: 2)} km';
    }
    return '${_fmtNum(actual, maxDecimals: 1)}%';
  }

  /// 0–1 fraction for the progress bar (from [actual] percent).
  double get actualProgressFraction {
    if (actual.isNaN || actual.isInfinite) {
      return 0;
    }
    return (actual / 100).clamp(0.0, 1.0);
  }

  String get frontAvailabilityCategory {
    final double available = frontAvailable ?? 0;
    final double total = frontTotal ?? 0;
    if (total <= 0) {
      return available > 0
          ? ExceptionReportFilters.frontPartial
          : ExceptionReportFilters.frontNotAvailable;
    }
    if (available <= 0) {
      return ExceptionReportFilters.frontNotAvailable;
    }
    if (available + 0.0001 >= total) {
      return ExceptionReportFilters.frontFullyAvailable;
    }
    return ExceptionReportFilters.frontPartial;
  }

  String get utilityShiftingCategory {
    if (utilityDone == null && utilityTotal == null) {
      return ExceptionReportFilters.utilityNotApplicable;
    }
    final double done = utilityDone ?? 0;
    final double total = utilityTotal ?? 0;
    if (total <= 0) {
      return ExceptionReportFilters.utilityNotApplicable;
    }
    if (done + 0.0001 >= total) {
      return ExceptionReportFilters.utilityCompleted;
    }
    return ExceptionReportFilters.utilityImpacted;
  }

  String get drawingStatusCategory {
    final String general = generalDrawingLabel;
    final String detailed = detailedDrawingLabel;
    if (general == 'Approved' || detailed == 'Approved') {
      return 'Approved';
    }
    if (general == 'Under Review' || detailed == 'Under Review') {
      return 'Under Review';
    }
    return 'Not Available';
  }

  factory ExceptionReportStructure.fromMap(Map<String, dynamic> map) {
    return ExceptionReportStructure(
      id: _asInt(map['id']),
      name: _asString(map['name']),
      type: _asString(map['type']),
      unit: _asString(map['unit']),
      scope: _asString(map['scope']),
      actual: _asDouble(map['actual']) ?? 0,
      issues: _asInt(map['issues']),
      actualKm: _asDouble(map['actualKm']),
      contract: _asString(map['contract']),
      exception: _asString(map['exception']),
      contractId: _asString(map['contractId']),
      frontTotal: _asDouble(map['frontTotal']),
      utilityDone: _asDouble(map['utilityDone']),
      utilityTotal: _asDouble(map['utilityTotal']),
      frontAvailable: _asDouble(map['frontAvailable']),
      generalDrawing: _asNullableDrawing(map['generalDrawing']),
      detailedDrawing: _asNullableDrawing(map['detailedDrawing']),
      tdc: _asDate(map['tdc']),
    );
  }

  static String _drawingLabel(String? raw) {
    final String? value = raw?.trim();
    if (value == null || value.isEmpty) {
      return 'Not Available';
    }
    return value;
  }

  static DrawingStatusDot _drawingDot(String? raw) {
    final String label = _drawingLabel(raw).toLowerCase();
    if (label == 'approved') {
      return DrawingStatusDot.approved;
    }
    if (label == 'under review') {
      return DrawingStatusDot.underReview;
    }
    return DrawingStatusDot.none;
  }

  static String? _asNullableDrawing(dynamic value) {
    if (value == null) {
      return null;
    }
    final String text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }
    return text;
  }
}

enum DrawingStatusDot { none, approved, underReview }

class ExceptionReportData {
  const ExceptionReportData({
    required this.summary,
    required this.structures,
  });

  final ExceptionReportSummary summary;
  final List<ExceptionReportStructure> structures;

  factory ExceptionReportData.fromMap(Map<String, dynamic> map) {
    final dynamic summaryRaw = map['summary'];
    final Map<String, dynamic>? summaryMap = summaryRaw is Map
        ? Map<String, dynamic>.from(summaryRaw)
        : null;
    final dynamic structuresRaw = map['structures'];
    final List<ExceptionReportStructure> structures = <ExceptionReportStructure>[];
    if (structuresRaw is List) {
      for (final dynamic item in structuresRaw) {
        if (item is Map) {
          structures.add(
            ExceptionReportStructure.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return ExceptionReportData(
      summary: ExceptionReportSummary.fromMap(summaryMap),
      structures: structures,
    );
  }
}

/// Client-side filter helpers for the Exception Report list.
class ExceptionReportFilters {
  ExceptionReportFilters._();

  static const String all = 'All';
  static const String frontFullyAvailable = 'Fully Available';
  static const String frontPartial = 'Partially Available';
  static const String frontNotAvailable = 'Not Available';
  static const String utilityImpacted = 'Impacted';
  static const String utilityCompleted = 'Completed';
  static const String utilityNotApplicable = 'Not Applicable';

  static const List<String> drawingStatusOptions = <String>[
    all,
    'Approved',
    'Under Review',
    'Not Available',
  ];

  static const List<String> frontAvailabilityOptions = <String>[
    all,
    frontFullyAvailable,
    frontPartial,
    frontNotAvailable,
  ];

  static const List<String> utilityShiftingOptions = <String>[
    all,
    utilityImpacted,
    utilityCompleted,
    utilityNotApplicable,
  ];

  static List<String> structureTypeOptions(
    List<ExceptionReportStructure> rows,
  ) {
    return _withAll(_unique(rows.map((ExceptionReportStructure r) => r.type)));
  }

  static List<String> exceptionCategoryOptions(
    List<ExceptionReportStructure> rows,
  ) {
    return _withAll(
      _unique(rows.map((ExceptionReportStructure r) => r.exception)),
    );
  }

  static List<ExceptionReportStructure> apply(
    List<ExceptionReportStructure> rows,
    ExceptionReportFilterState state,
  ) {
    final String query = state.searchQuery.trim().toLowerCase();
    return rows.where((ExceptionReportStructure row) {
      if (state.structureType != all && row.type != state.structureType) {
        return false;
      }
      if (query.isNotEmpty && !row.name.toLowerCase().contains(query)) {
        return false;
      }
      if (state.drawingStatus != all &&
          row.drawingStatusCategory != state.drawingStatus) {
        return false;
      }
      if (state.frontAvailability != all &&
          row.frontAvailabilityCategory != state.frontAvailability) {
        return false;
      }
      if (state.utilityShifting != all &&
          row.utilityShiftingCategory != state.utilityShifting) {
        return false;
      }
      if (state.exceptionCategory != all &&
          row.exception != state.exceptionCategory) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  static List<String> _withAll(List<String> values) => <String>[all, ...values];

  static List<String> _unique(Iterable<String> values) {
    final Set<String> seen = <String>{};
    final List<String> out = <String>[];
    for (final String value in values) {
      final String trimmed = value.trim();
      if (trimmed.isEmpty || seen.contains(trimmed)) {
        continue;
      }
      seen.add(trimmed);
      out.add(trimmed);
    }
    out.sort(
      (String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()),
    );
    return out;
  }
}

class ExceptionReportFilterState {
  const ExceptionReportFilterState({
    this.structureType = ExceptionReportFilters.all,
    this.searchQuery = '',
    this.drawingStatus = ExceptionReportFilters.all,
    this.frontAvailability = ExceptionReportFilters.all,
    this.utilityShifting = ExceptionReportFilters.all,
    this.exceptionCategory = ExceptionReportFilters.all,
  });

  static const ExceptionReportFilterState cleared = ExceptionReportFilterState();

  final String structureType;
  final String searchQuery;
  final String drawingStatus;
  final String frontAvailability;
  final String utilityShifting;
  final String exceptionCategory;

  bool get hasActiveFilters =>
      structureType != ExceptionReportFilters.all ||
      searchQuery.trim().isNotEmpty ||
      drawingStatus != ExceptionReportFilters.all ||
      frontAvailability != ExceptionReportFilters.all ||
      utilityShifting != ExceptionReportFilters.all ||
      exceptionCategory != ExceptionReportFilters.all;

  int get activeCount {
    int n = 0;
    if (structureType != ExceptionReportFilters.all) n++;
    if (searchQuery.trim().isNotEmpty) n++;
    if (drawingStatus != ExceptionReportFilters.all) n++;
    if (frontAvailability != ExceptionReportFilters.all) n++;
    if (utilityShifting != ExceptionReportFilters.all) n++;
    if (exceptionCategory != ExceptionReportFilters.all) n++;
    return n;
  }

  ExceptionReportFilterState copyWith({
    String? structureType,
    String? searchQuery,
    String? drawingStatus,
    String? frontAvailability,
    String? utilityShifting,
    String? exceptionCategory,
  }) {
    return ExceptionReportFilterState(
      structureType: structureType ?? this.structureType,
      searchQuery: searchQuery ?? this.searchQuery,
      drawingStatus: drawingStatus ?? this.drawingStatus,
      frontAvailability: frontAvailability ?? this.frontAvailability,
      utilityShifting: utilityShifting ?? this.utilityShifting,
      exceptionCategory: exceptionCategory ?? this.exceptionCategory,
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString().trim() ?? '') ?? 0;
}

double? _asDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  final String text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }
  return double.tryParse(text);
}

String _asString(dynamic value) {
  final String text = value?.toString().trim() ?? '';
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return '';
  }
  return text;
}

DateTime? _asDate(dynamic value) {
  final String text = value?.toString().trim() ?? '';
  if (text.isEmpty) {
    return null;
  }
  final DateTime? direct = DateTime.tryParse(text);
  if (direct != null) {
    return direct;
  }
  final String isoLike = text.contains(' ')
      ? text.replaceFirst(' ', 'T')
      : text;
  return DateTime.tryParse(isoLike);
}

String _fmtNum(double? value, {int maxDecimals = 1}) {
  if (value == null) {
    return '0';
  }
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  String fixed = value.toStringAsFixed(maxDecimals);
  while (fixed.contains('.') && fixed.endsWith('0')) {
    fixed = fixed.substring(0, fixed.length - 1);
  }
  if (fixed.endsWith('.')) {
    fixed = fixed.substring(0, fixed.length - 1);
  }
  return fixed;
}
