import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';

/// Reports → Quality → RFI Summary Report (formId 1405 / rfisummaryreport).
bool isRfiSummaryReport({
  required String formId,
  required String formName,
  required String webFormUrl,
}) {
  final String id = formId.trim();
  if (id == '1405') {
    return true;
  }

  final String url = webFormUrl.trim().toLowerCase();
  if (url.contains('rfi-summary-report') ||
      url.contains('rfisummaryreport') ||
      url.contains('rfi-summary')) {
    return true;
  }

  final String name = formName.trim().toLowerCase();
  return name.contains('rfi') && name.contains('summary');
}

/// Options from RFI Summary dropdown APIs (`{value,label}`).
/// Accepts a bare list, a single object, or a common data envelope.
List<ContractDetailOption> parseRfiSummaryOptions(Object? data) {
  final List<ContractDetailOption> out = <ContractDetailOption>[];
  final Set<String> seen = <String>{};
  for (final Map<String, dynamic> map in _asMaps(data)) {
    final String id = _firstText(map, const <String>[
      'value',
      'id',
      'projectId',
      'project_id',
      'contractId',
      'contract_id',
      'rfiCategory',
      'rfi_category',
      'category',
    ]);
    if (id.isEmpty || !seen.add(id)) {
      continue;
    }
    final String label = _firstText(map, const <String>[
      'label',
      'name',
      'projectName',
      'project_name',
      'contractName',
      'contract_name',
      'contractShortName',
      'contract_short_name',
      'categoryName',
      'category_name',
    ]);
    out.add(ContractDetailOption(id: id, label: label.isEmpty ? id : label));
  }
  return out;
}

class RfiSummaryDateRange {
  const RfiSummaryDateRange({this.minDate, this.maxDate});

  final DateTime? minDate;
  final DateTime? maxDate;

  bool get hasBounds => minDate != null || maxDate != null;

  String get hintLabel {
    final String min = _ymd(minDate);
    final String max = _ymd(maxDate);
    if (min.isEmpty && max.isEmpty) {
      return '';
    }
    if (min.isEmpty) {
      return 'Available submission dates: up to $max. '
          'Leave dates blank to include the full range.';
    }
    if (max.isEmpty) {
      return 'Available submission dates: from $min. '
          'Leave dates blank to include the full range.';
    }
    return 'Available submission dates: $min to $max. '
        'Leave dates blank to include the full range.';
  }

  factory RfiSummaryDateRange.fromJson(Object? data) {
    final Map<String, dynamic> map = _rootMap(data);
    return RfiSummaryDateRange(
      minDate: _parseYmd(
        map['minDate'] ?? map['min_date'] ?? map['from'] ?? map['dateFrom'],
      ),
      maxDate: _parseYmd(
        map['maxDate'] ?? map['max_date'] ?? map['to'] ?? map['dateTo'],
      ),
    );
  }
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
      'options',
      'projects',
      'contracts',
      'categories',
    ]) {
      final Object? nested = map[key];
      if (nested is List || nested is Map) {
        return _asMaps(nested);
      }
    }
    // Single option object (e.g. one project returned as a map).
    if (_firstText(map, const <String>['value', 'id', 'label', 'name'])
        .isNotEmpty) {
      return <Map<String, dynamic>>[map];
    }
  }
  return const <Map<String, dynamic>>[];
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

String _ymd(DateTime? date) {
  if (date == null) {
    return '';
  }
  final String m = date.month.toString().padLeft(2, '0');
  final String d = date.day.toString().padLeft(2, '0');
  return '${date.year}-$m-$d';
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
