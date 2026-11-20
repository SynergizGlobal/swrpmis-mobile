import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';

/// Reports → Quality → Quality Control Summary Tests Report
/// (formId 1404 / qualitytestsummaryreport).
bool isQualityControlSummaryReport({
  required String formId,
  required String formName,
  required String webFormUrl,
}) {
  final String id = formId.trim();
  if (id == '1404') {
    return true;
  }

  final String url = webFormUrl.trim().toLowerCase();
  if (url.contains('qualitytestsummaryreport')) {
    return true;
  }

  final String name = formName.trim().toLowerCase();
  final bool hasQuality = name.contains('quality control');
  final bool hasSummary = name.contains('summary');
  final bool hasTest = name.contains('test');
  return hasQuality && hasSummary && hasTest;
}

/// Projects from `GET /material-receipt/dropdown-projects` (`data` envelope).
List<ContractDetailOption> parseQualitySummaryProjects(Object? data) {
  final List<ContractDetailOption> out = <ContractDetailOption>[];
  final Set<String> seen = <String>{};
  for (final Map<String, dynamic> map in _asMaps(data)) {
    final Object? rawId =
        map['projectIdFk'] ??
        map['project_id_fk'] ??
        map['project_id'] ??
        map['projectId'] ??
        map['id'];
    if (!_isNonNullToken(rawId)) {
      continue;
    }
    final String id = _text(rawId);
    if (id.isEmpty || !seen.add(id)) {
      continue;
    }
    final String name = _firstText(map, const <String>[
      'projectName',
      'project_name',
      'name',
    ]);
    out.add(ContractDetailOption(id: id, label: name.isEmpty ? id : name));
  }
  return out;
}

/// Contracts from `GET /api/quality/test-obligations/contracts?projectId=`.
List<ContractDetailOption> parseQualitySummaryContracts(Object? data) {
  final List<ContractDetailOption> out = <ContractDetailOption>[];
  final Set<String> seen = <String>{};
  for (final Map<String, dynamic> map in _asMaps(data)) {
    final String id = _firstText(map, const <String>[
      'id',
      'contractId',
      'contract_id',
    ]);
    if (id.isEmpty || !seen.add(id)) {
      continue;
    }
    final String name = _firstText(map, const <String>[
      'name',
      'contractShortName',
      'contract_short_name',
      'contractName',
    ]);
    out.add(ContractDetailOption(id: id, label: name.isEmpty ? id : name));
  }
  return out;
}

class QualitySummaryCounts {
  const QualitySummaryCounts({
    this.performed = 0,
    this.passed = 0,
    this.failed = 0,
  });

  final int performed;
  final int passed;
  final int failed;

  factory QualitySummaryCounts.fromJson(Object? raw) {
    if (raw is! Map) {
      return const QualitySummaryCounts();
    }
    final Map<String, dynamic> map = Map<String, dynamic>.from(raw);
    return QualitySummaryCounts(
      performed: _int(map['performed']),
      passed: _int(map['passed']),
      failed: _int(map['failed']),
    );
  }
}

class QualitySummaryTestRow {
  const QualitySummaryTestRow({
    this.label = '',
    this.testName = '',
    this.unit = '',
    this.frequency = '',
    this.previous = const QualitySummaryCounts(),
    this.current = const QualitySummaryCounts(),
    this.cumulative = const QualitySummaryCounts(),
  });

  final String label;
  final String testName;
  final String unit;
  final String frequency;
  final QualitySummaryCounts previous;
  final QualitySummaryCounts current;
  final QualitySummaryCounts cumulative;

  factory QualitySummaryTestRow.fromJson(Map<String, dynamic> json) {
    return QualitySummaryTestRow(
      label: _firstText(json, const <String>['label', 'srNo', 'sr_no']),
      testName: _firstText(json, const <String>[
        'testName',
        'test_name',
        'name',
        'description',
      ]),
      unit: _firstText(json, const <String>['unit']),
      frequency: _firstText(json, const <String>[
        'frequency',
        'frequencyOfTest',
        'frequency_of_test',
      ]),
      previous: QualitySummaryCounts.fromJson(json['previous']),
      current: QualitySummaryCounts.fromJson(json['current']),
      cumulative: QualitySummaryCounts.fromJson(json['cumulative']),
    );
  }
}

class QualitySummarySection {
  const QualitySummarySection({
    this.srNo = '',
    this.title = '',
    this.rows = const <QualitySummaryTestRow>[],
  });

  final String srNo;
  final String title;
  final List<QualitySummaryTestRow> rows;

  factory QualitySummarySection.fromJson(Map<String, dynamic> json) {
    final Object? rawRows = json['rows'];
    final List<QualitySummaryTestRow> rows = <QualitySummaryTestRow>[];
    if (rawRows is List) {
      for (final Object? item in rawRows) {
        if (item is Map) {
          rows.add(
            QualitySummaryTestRow.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return QualitySummarySection(
      srNo: _firstText(json, const <String>['srNo', 'sr_no', 'serialNo']),
      title: _firstText(json, const <String>[
        'title',
        'materialDescription',
        'material_description',
        'name',
      ]),
      rows: rows,
    );
  }
}

class QualityControlSummaryReport {
  const QualityControlSummaryReport({
    this.projectName = '',
    this.contractShortName = '',
    this.contractorName = '',
    this.periodFrom,
    this.periodTo,
    this.sections = const <QualitySummarySection>[],
  });

  final String projectName;
  final String contractShortName;
  final String contractorName;
  final DateTime? periodFrom;
  final DateTime? periodTo;
  final List<QualitySummarySection> sections;

  String get periodLabel {
    final String from = _displayDate(periodFrom);
    final String to = _displayDate(periodTo);
    if (from.isEmpty && to.isEmpty) {
      return '';
    }
    if (from.isEmpty) {
      return to;
    }
    if (to.isEmpty) {
      return from;
    }
    return '$from - $to';
  }

  factory QualityControlSummaryReport.fromJson(Object? data) {
    final Map<String, dynamic> map = _rootMap(data);
    final Object? rawSections = map['sections'];
    final List<QualitySummarySection> sections = <QualitySummarySection>[];
    if (rawSections is List) {
      for (final Object? item in rawSections) {
        if (item is Map) {
          sections.add(
            QualitySummarySection.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return QualityControlSummaryReport(
      projectName: _firstText(map, const <String>[
        'projectName',
        'project_name',
      ]),
      contractShortName: _firstText(map, const <String>[
        'contractShortName',
        'contract_short_name',
        'contractName',
      ]),
      contractorName: _firstText(map, const <String>[
        'contractorName',
        'contractor_name',
      ]),
      periodFrom: _parseYmd(map['periodFrom'] ?? map['period_from']),
      periodTo: _parseYmd(map['periodTo'] ?? map['period_to']),
      sections: sections,
    );
  }
}

/// Formats a count for the report grid: `0` → `-`.
String qualitySummaryCountDisplay(int value) {
  if (value == 0) {
    return '-';
  }
  return '$value';
}

String qualitySummaryDashOrText(String value) {
  final String text = value.trim();
  return text.isEmpty ? '-' : text;
}

Map<String, dynamic> _rootMap(Object? data) {
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    final Object? nested = map['data'];
    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }
    return map;
  }
  return <String, dynamic>{};
}

DateTime? _parseYmd(Object? raw) {
  if (raw is List && raw.length >= 3) {
    final int? y = _nullableInt(raw[0]);
    final int? m = _nullableInt(raw[1]);
    final int? d = _nullableInt(raw[2]);
    if (y != null && m != null && d != null) {
      return DateTime(y, m, d);
    }
  }
  if (raw is String) {
    final String text = raw.trim();
    final RegExpMatch? iso = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})',
    ).firstMatch(text);
    if (iso != null) {
      return DateTime(
        int.parse(iso.group(1)!),
        int.parse(iso.group(2)!),
        int.parse(iso.group(3)!),
      );
    }
  }
  return null;
}

String _displayDate(DateTime? date) {
  if (date == null) {
    return '';
  }
  final String d = date.day.toString().padLeft(2, '0');
  final String m = date.month.toString().padLeft(2, '0');
  return '$d-$m-${date.year}';
}

bool _isNonNullToken(Object? value) {
  if (value == null) {
    return false;
  }
  final String text = '$value'.trim().toLowerCase();
  return text.isNotEmpty && text != 'null';
}

List<Map<String, dynamic>> _asMaps(Object? data) {
  if (data is List) {
    return data
        .whereType<Map>()
        .map((Map item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    for (final String key in const <String>[
      'data',
      'result',
      'content',
      'list',
      'records',
    ]) {
      final Object? nested = map[key];
      if (nested is List || nested is Map) {
        return _asMaps(nested);
      }
    }
    return <Map<String, dynamic>>[map];
  }
  return const <Map<String, dynamic>>[];
}

String _firstText(Map<String, dynamic> json, List<String> keys) {
  for (final String key in keys) {
    final String value = _text(json[key]);
    if (value.isNotEmpty) {
      return value;
    }
  }
  return '';
}

String _text(Object? value) {
  if (value == null) {
    return '';
  }
  final String text = '$value'.trim();
  if (text.toLowerCase() == 'null') {
    return '';
  }
  return text;
}

int _int(Object? value) {
  return _nullableInt(value) ?? 0;
}

int? _nullableInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim());
  }
  return null;
}
