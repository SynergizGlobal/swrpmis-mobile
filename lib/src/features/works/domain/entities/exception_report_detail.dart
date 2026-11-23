import 'package:intl/intl.dart';

class ExceptionReportDetail {
  const ExceptionReportDetail({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.contract,
    required this.front,
    required this.utility,
    required this.issues,
    required this.tabCounts,
    required this.generalDrawings,
    required this.detailedDrawings,
  });

  final int id;
  final String name;
  final String type;
  final String status;
  final String contract;
  final ExceptionFrontSection front;
  final ExceptionUtilitySection utility;
  final List<ExceptionIssueRow> issues;
  final ExceptionTabCounts tabCounts;
  final ExceptionDrawingsSection generalDrawings;
  final ExceptionDrawingsSection detailedDrawings;

  String get title => '$type – $name';

  bool get isActive => status.trim().toLowerCase() == 'active';

  factory ExceptionReportDetail.fromMap(Map<String, dynamic> map) {
    return ExceptionReportDetail(
      id: _asInt(map['id']),
      name: _asString(map['name']),
      type: _asString(map['type']),
      status: _asString(map['status']),
      contract: _asString(map['contract']),
      front: ExceptionFrontSection.fromMap(_asMap(map['front'])),
      utility: ExceptionUtilitySection.fromMap(_asMap(map['utility'])),
      issues: _asList(map['issues'])
          .map(ExceptionIssueRow.fromMap)
          .toList(growable: false),
      tabCounts: ExceptionTabCounts.fromMap(_asMap(map['tabCounts'])),
      generalDrawings: ExceptionDrawingsSection.fromMap(
        _asMap(map['generalDrawings']),
      ),
      detailedDrawings: ExceptionDrawingsSection.fromMap(
        _asMap(map['detailedDrawings']),
      ),
    );
  }
}

class ExceptionTabCounts {
  const ExceptionTabCounts({
    required this.front,
    required this.issues,
    required this.general,
    required this.utility,
    required this.detailed,
  });

  final int front;
  final int issues;
  final int general;
  final int utility;
  final int detailed;

  factory ExceptionTabCounts.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const ExceptionTabCounts(
        front: 0,
        issues: 0,
        general: 0,
        utility: 0,
        detailed: 0,
      );
    }
    return ExceptionTabCounts(
      front: _asInt(map['front']),
      issues: _asInt(map['issues']),
      general: _asInt(map['general']),
      utility: _asInt(map['utility']),
      detailed: _asInt(map['detailed']),
    );
  }
}

class ExceptionFrontSection {
  const ExceptionFrontSection({
    required this.unit,
    required this.total,
    required this.available,
    required this.segments,
  });

  final String unit;
  final double total;
  final double available;
  final List<ExceptionFrontSegment> segments;

  double get percent => total <= 0 ? 0 : (available / total * 100);

  double get fraction => total <= 0 ? 0 : (available / total).clamp(0.0, 1.0);

  String get summaryLabel =>
      '${_fmtNum(available)} / ${_fmtNum(total)} $unit (${_fmtNum(percent)}%)';

  factory ExceptionFrontSection.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const ExceptionFrontSection(
        unit: 'km',
        total: 0,
        available: 0,
        segments: <ExceptionFrontSegment>[],
      );
    }
    return ExceptionFrontSection(
      unit: _asString(map['unit']).isEmpty ? 'km' : _asString(map['unit']),
      total: _asDouble(map['total']) ?? 0,
      available: _asDouble(map['available']) ?? 0,
      segments: _asList(map['segments'])
          .map(ExceptionFrontSegment.fromMap)
          .toList(growable: false),
    );
  }
}

class ExceptionFrontSegment {
  const ExceptionFrontSegment({
    required this.from,
    required this.to,
    required this.length,
    required this.status,
    required this.remarks,
  });

  final double from;
  final double to;
  final double length;
  final String status;
  final String remarks;

  bool get isAvailable => status.trim().toLowerCase() == 'available';

  factory ExceptionFrontSegment.fromMap(Map<String, dynamic> map) {
    return ExceptionFrontSegment(
      from: _asDouble(map['from']) ?? 0,
      to: _asDouble(map['to']) ?? 0,
      length: _asDouble(map['length']) ?? 0,
      status: _asString(map['status']),
      remarks: _dash(_asString(map['remarks'])),
    );
  }
}

class ExceptionUtilitySection {
  const ExceptionUtilitySection({
    required this.done,
    required this.unit,
    required this.total,
    required this.segments,
  });

  final double done;
  final String unit;
  final double total;
  final List<ExceptionUtilitySegment> segments;

  double get percent => total <= 0 ? 0 : (done / total * 100);

  double get fraction => total <= 0 ? 0 : (done / total).clamp(0.0, 1.0);

  String get summaryLabel =>
      '${_fmtNum(done)} / ${_fmtNum(total)} $unit (${_fmtNum(percent)}%)';

  factory ExceptionUtilitySection.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const ExceptionUtilitySection(
        done: 0,
        unit: 'km',
        total: 0,
        segments: <ExceptionUtilitySegment>[],
      );
    }
    return ExceptionUtilitySection(
      done: _asDouble(map['done']) ?? 0,
      unit: _asString(map['unit']).isEmpty ? 'km' : _asString(map['unit']),
      total: _asDouble(map['total']) ?? 0,
      segments: _asList(map['segments'])
          .map(ExceptionUtilitySegment.fromMap)
          .toList(growable: false),
    );
  }
}

class ExceptionUtilitySegment {
  const ExceptionUtilitySegment({
    required this.from,
    required this.to,
    required this.type,
    required this.length,
    required this.status,
    required this.remarks,
  });

  final double from;
  final double to;
  final String type;
  final double length;
  final String status;
  final String remarks;

  bool get isCompleted => status.trim().toLowerCase() == 'completed';

  bool get isInProgress => status.trim().toLowerCase() == 'in progress';

  factory ExceptionUtilitySegment.fromMap(Map<String, dynamic> map) {
    return ExceptionUtilitySegment(
      from: _asDouble(map['from']) ?? 0,
      to: _asDouble(map['to']) ?? 0,
      type: _asString(map['type']),
      length: _asDouble(map['length']) ?? 0,
      status: _asString(map['status']),
      remarks: _dash(_asString(map['remarks'])),
    );
  }
}

class ExceptionIssueRow {
  const ExceptionIssueRow({
    required this.id,
    required this.status,
    required this.category,
    required this.raisedOn,
    required this.targetDate,
    required this.description,
  });

  final String id;
  final String status;
  final String category;
  final DateTime? raisedOn;
  final DateTime? targetDate;
  final String description;

  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  String get raisedOnLabel {
    final DateTime? value = raisedOn;
    if (value == null) {
      return '—';
    }
    return _dateFormat.format(value);
  }

  String get targetDateLabel {
    final DateTime? value = targetDate;
    if (value == null) {
      return '—';
    }
    return _dateFormat.format(value);
  }

  factory ExceptionIssueRow.fromMap(Map<String, dynamic> map) {
    return ExceptionIssueRow(
      id: _asString(map['id']),
      status: _asString(map['status']),
      category: _asString(map['category']),
      raisedOn: _asDate(map['raisedOn']),
      targetDate: _asDate(map['targetDate']),
      description: _asString(map['description']),
    );
  }
}

class ExceptionDrawingsSection {
  const ExceptionDrawingsSection({
    required this.status,
    required this.rows,
  });

  final String? status;
  final List<ExceptionDrawingRow> rows;

  String get statusLabel {
    final String? value = status?.trim();
    if (value == null || value.isEmpty) {
      return 'Not Available';
    }
    return value;
  }

  bool get isEmpty => rows.isEmpty;

  factory ExceptionDrawingsSection.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const ExceptionDrawingsSection(
        status: null,
        rows: <ExceptionDrawingRow>[],
      );
    }
    final dynamic statusRaw = map['status'];
    String? status;
    if (statusRaw != null) {
      final String text = statusRaw.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        status = text;
      }
    }
    return ExceptionDrawingsSection(
      status: status,
      rows: _asList(map['rows'])
          .map(ExceptionDrawingRow.fromMap)
          .toList(growable: false),
    );
  }
}

class ExceptionDrawingRow {
  const ExceptionDrawingRow({
    required this.structure,
    required this.drawingCategory,
    required this.total,
    required this.approved,
    required this.pending,
    required this.remarks,
  });

  final String structure;
  final String drawingCategory;
  final String total;
  final String approved;
  final String pending;
  final String remarks;

  factory ExceptionDrawingRow.fromMap(Map<String, dynamic> map) {
    return ExceptionDrawingRow(
      structure: _asString(
        map['structure'] ?? map['structureName'] ?? map['name'],
      ),
      drawingCategory: _asString(
        map['drawingCategory'] ?? map['category'] ?? map['drawing_category'],
      ),
      total: _displayNum(map['total']),
      approved: _displayNum(map['approved']),
      pending: _displayNum(map['pending']),
      remarks: _dash(_asString(map['remarks'])),
    );
  }
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

List<Map<String, dynamic>> _asList(dynamic value) {
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }
  return value
      .whereType<Map>()
      .map((Map item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
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
  if (value == null) {
    return null;
  }
  final String text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
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

String _dash(String value) {
  final String trimmed = value.trim();
  if (trimmed.isEmpty || trimmed == '-' || trimmed == '–') {
    return '—';
  }
  return trimmed;
}

String _displayNum(dynamic value) {
  if (value == null) {
    return '0';
  }
  if (value is num) {
    return _fmtNum(value.toDouble());
  }
  final String text = value.toString().trim();
  return text.isEmpty ? '0' : text;
}

String _fmtNum(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  final String fixed = value.toStringAsFixed(1);
  if (fixed.endsWith('.0')) {
    return fixed.substring(0, fixed.length - 2);
  }
  return fixed;
}
