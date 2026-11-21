import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';

/// Reports → Issues → Pending Issues Report (formId 296 / issues-report).
bool isPendingIssuesReport({
  required String formId,
  required String formName,
  required String webFormUrl,
}) {
  final String id = formId.trim();
  if (id == '296') {
    return true;
  }

  final String url = webFormUrl.trim().toLowerCase();
  if (url.contains('generate-pending') ||
      (url.contains('issues-report') &&
          !url.contains('summary') &&
          !url.contains('details'))) {
    return true;
  }

  final String name = formName.trim().toLowerCase();
  return name.contains('pending') && name.contains('issue');
}

/// HOD row from `POST /api/issues-report/getHodList`.
class PendingIssuesHodOption {
  const PendingIssuesHodOption({
    required this.userId,
    required this.name,
    this.designation = '',
  });

  final String userId;
  final String name;
  final String designation;

  /// Stable picker key (user id when present, else name).
  String get selectionId => userId.isNotEmpty ? userId : name;

  /// Dropdown label: name, optionally with designation.
  String get label {
    if (name.isNotEmpty &&
        designation.isNotEmpty &&
        name != designation) {
      return '$name ($designation)';
    }
    if (name.isNotEmpty) {
      return name;
    }
    if (designation.isNotEmpty) {
      return designation;
    }
    return userId;
  }
}

/// Parses HOD list: array, single object, or common data envelope.
List<PendingIssuesHodOption> parsePendingIssuesHods(Object? data) {
  final List<PendingIssuesHodOption> out = <PendingIssuesHodOption>[];
  final Set<String> seen = <String>{};
  for (final Map<String, dynamic> map in _asMaps(data)) {
    final String userId = _firstText(map, const <String>[
      'hod_user_id_fk',
      'user_id',
      'userId',
      'id',
    ]);
    final String name = _firstText(map, const <String>[
      'hod_name',
      'user_name',
      'name',
      'label',
    ]);
    final String designation = _firstText(map, const <String>[
      'designation',
      'hod_designation',
    ]);
    if (userId.isEmpty && name.isEmpty) {
      continue;
    }
    final String key = userId.isNotEmpty ? userId : name;
    if (!seen.add(key)) {
      continue;
    }
    out.add(
      PendingIssuesHodOption(
        userId: userId,
        name: name.isEmpty ? userId : name,
        designation: designation,
      ),
    );
  }
  return out;
}

/// Parses contract list: array, single object, or common data envelope.
List<ContractDetailOption> parsePendingIssuesContracts(Object? data) {
  final List<ContractDetailOption> out = <ContractDetailOption>[];
  final Set<String> seen = <String>{};
  for (final Map<String, dynamic> map in _asMaps(data)) {
    final String id = _firstText(map, const <String>[
      'contract_id_fk',
      'contract_id',
      'id',
      'value',
    ]);
    if (id.isEmpty || !seen.add(id)) {
      continue;
    }
    final String label = _firstText(map, const <String>[
      'contract_name',
      'contract_short_name',
      'name',
      'label',
    ]);
    out.add(ContractDetailOption(id: id, label: label.isEmpty ? id : label));
  }
  return out;
}

/// Live web generate sends [hod_user_id_fk] as the **HOD name**, not user id.
Map<String, dynamic> buildPendingIssuesGenerateBody({
  required String hodName,
  required String contractId,
}) {
  return <String, dynamic>{
    'hod_user_id_fk': hodName.trim(),
    'contract_id_fk': contractId.trim(),
  };
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
      'hods',
      'contracts',
    ]) {
      final Object? nested = map[key];
      if (nested is List || nested is Map) {
        return _asMaps(nested);
      }
    }
    if (_firstText(map, const <String>[
      'hod_user_id_fk',
      'hod_name',
      'contract_id_fk',
      'contract_id',
      'contract_name',
      'id',
      'name',
    ]).isNotEmpty) {
      return <Map<String, dynamic>>[map];
    }
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
