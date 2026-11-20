import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';

/// Reports → Contracts → BG/Insurance Report (formId 1336 / contract-report/8).
bool isBgInsuranceReport({
  required String formId,
  required String formName,
  required String webFormUrl,
}) {
  final String id = formId.trim();
  if (id == '1336') {
    return true;
  }

  final String url = webFormUrl.trim().toLowerCase();
  if (url.contains('generate-bg-insurance')) {
    return true;
  }
  if (_isBgInsuranceUrl(url)) {
    return true;
  }

  final String name = formName.trim().toLowerCase();
  return name == 'bg/insurance report' ||
      name == 'bg insurance report' ||
      name == 'bg/insurance';
}

bool _isBgInsuranceUrl(String url) {
  // Web menu uses paths like `contract-report/8`.
  final RegExpMatch? match = RegExp(
    r'contract-report(?:/|#)?0*8(?:/|$|\?|#)',
    caseSensitive: false,
  ).firstMatch(url);
  return match != null;
}

List<ContractDetailOption> parseBgInsuranceProjects(Object? data) {
  return parseContractDetailProjects(data);
}

/// Contractor options with label `CON0001 - M/s …` when id + name exist.
List<ContractDetailOption> parseBgInsuranceContractors(Object? data) {
  final List<ContractDetailOption> out = <ContractDetailOption>[];
  final Set<String> seen = <String>{};
  for (final Map<String, dynamic> map in _asMaps(data)) {
    final String fk = _firstText(map, const <String>[
      'contractor_id_fk',
      'id',
    ]);
    final String code = _firstText(map, const <String>[
      'contractor_id',
      'contractor_id_fk',
      'id',
    ]);
    final String name = _firstText(map, const <String>[
      'contractor_name',
      'name',
    ]);
    final String id = fk.isNotEmpty ? fk : code;
    if (id.isEmpty || !seen.add(id)) {
      continue;
    }
    final String displayCode = code.isNotEmpty ? code : id;
    final String label;
    if (displayCode.isNotEmpty && name.isNotEmpty && name != displayCode) {
      label = '$displayCode - $name';
    } else if (name.isNotEmpty) {
      label = name;
    } else {
      label = displayCode;
    }
    out.add(ContractDetailOption(id: id, label: label));
  }
  return out;
}

/// Status of Work options from `getContractStatusListInContractReport`
/// (`contract_status_fk`: Completed / In Progress / Not Awarded).
List<ContractDetailOption> parseBgInsuranceContractStatuses(Object? data) {
  return parseContractDetailStatuses(data);
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
  return '$value'.trim();
}
