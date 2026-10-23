import 'package:swr_pmis_mobile/src/features/quality_test_register/domain/quality_test_register_detail.dart';
import 'package:swr_pmis_mobile/src/features/quality_test_register/domain/quality_test_register_list.dart';

({List<QualityTestObligationRow> rows, int total}) parseQualityTestObligationList(
  dynamic data,
) {
  final Map<String, dynamic>? root = _map(data);
  if (root == null) {
    return (rows: const <QualityTestObligationRow>[], total: 0);
  }
  final List<QualityTestObligationRow> rows = <QualityTestObligationRow>[];
  for (final Map<String, dynamic> json in _listOfMaps(root['data'])) {
    final int? id = _int(json['id']);
    final String code = _text(json['obligationCode']);
    if (id == null || code.isEmpty) {
      continue;
    }
    rows.add(
      QualityTestObligationRow(
        id: id,
        obligationCode: code,
        projectId: _text(json['projectId']),
        projectName: _text(json['projectName']),
        sectionName: _text(json['sectionName']),
        contractId: _text(json['contractId']),
        contractName: _text(json['contractName']),
        materialCode: _text(json['materialCode']),
        materialName: _text(json['materialName']),
        testName: _text(json['testName']),
        frequencyBasis: _text(json['frequencyBasis']),
        generatedFrom: _text(json['generatedFrom']),
        obligationBasisCoverage: _text(json['obligationBasisCoverage']),
        batchLotNo: _text(json['batchLotNo']),
        requiredByDate: formatQualityTestDate(json['requiredByDate']),
        contractorStatus: _text(json['contractorStatus']),
        engineerStatus: _text(json['engineerStatus']),
      ),
    );
  }
  final int total =
      _int(root['totalRecords']) ?? _int(root['total']) ?? rows.length;
  return (rows: rows, total: total < 0 ? rows.length : total);
}

QualityTestObligationDetail parseQualityTestObligationDetail(dynamic data) {
  final Map<String, dynamic>? root = _map(data);
  if (root == null) {
    throw StateError('Empty test obligation response.');
  }
  final Map<String, dynamic>? payload =
      _map(root['data']) ?? (root.containsKey('id') ? root : null);
  if (payload == null) {
    throw StateError('Test obligation details missing.');
  }
  final int? id = _int(payload['id']);
  if (id == null) {
    throw StateError('Test obligation id missing.');
  }
  return QualityTestObligationDetail(
    id: id,
    obligationCode: _text(payload['obligationCode']),
    projectId: _text(payload['projectId']),
    sectionId: _text(payload['sectionId']),
    contractId: _text(payload['contractId']),
    materialCode: _text(payload['materialCode']),
    materialName: _text(payload['materialName']),
    testName: _text(payload['testName']),
    generatedFrom: _text(payload['generatedFrom']),
    batchLotNo: _text(payload['batchLotNo']),
    obligationBasisCoverage: _text(payload['obligationBasisCoverage']),
    requiredByDate: formatQualityTestDate(payload['requiredByDate']),
    contractorStatus: _text(payload['contractorStatus']),
    engineerStatus: _text(payload['engineerStatus']),
    finalResult: _text(payload['finalResult']),
    contractorRemarks: _text(payload['contractorRemarks']),
    submittedBy: _text(payload['submittedBy']),
    submittedOn: formatQualityTestDateTime(payload['submittedOn']),
    reviewedBy: _text(payload['reviewedBy']),
    reviewDate: formatQualityTestDateTime(payload['reviewDate']),
    reviewComments: _text(payload['reviewComments']),
    testDate: formatQualityTestDate(payload['testDate']),
    remarks: _text(payload['remarks']),
  );
}

List<QualityTestOption> parseQualityTestDropdownProjects(dynamic data) {
  return _namedOptions(
    _envelopeList(data),
    idKeys: const <String>['projectIdFk', 'project_id', 'projectId', 'id'],
    nameKeys: const <String>['projectName', 'project_name', 'name'],
  );
}

List<QualityTestOption> parseQualityTestDropdownMaterials(dynamic data) {
  return _namedOptions(
    _envelopeList(data),
    idKeys: const <String>['materialCode', 'material_code', 'id'],
    nameKeys: const <String>['materialName', 'material_name', 'name'],
  );
}

List<QualityTestOption> parseQualityTestDropdownSections(dynamic data) {
  return _namedOptions(
    _envelopeList(data),
    idKeys: const <String>['section_id', 'sectionId', 'id'],
    nameKeys: const <String>['section_name', 'sectionName', 'name'],
  );
}

List<QualityTestOption> parseQualityTestDropdownContracts(dynamic data) {
  return _namedOptions(
    _envelopeList(data),
    idKeys: const <String>['id', 'contract_id', 'contractId'],
    nameKeys: const <String>[
      'name',
      'contract_name',
      'contractName',
      'contractShortName',
    ],
  );
}

String formatQualityTestDate(dynamic value) {
  if (value == null) {
    return '';
  }
  if (value is List && value.length >= 3) {
    final int? year = _int(value[0]);
    final int? month = _int(value[1]);
    final int? day = _int(value[2]);
    if (year == null || month == null || day == null) {
      return '';
    }
    return '${day.toString().padLeft(2, '0')}-'
        '${month.toString().padLeft(2, '0')}-'
        '$year';
  }
  final String text = _text(value);
  final RegExpMatch? iso = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})',
  ).firstMatch(text);
  if (iso != null) {
    return '${iso.group(3)}-${iso.group(2)}-${iso.group(1)}';
  }
  return text;
}

String formatQualityTestDateTime(dynamic value) {
  if (value == null) {
    return '';
  }
  if (value is List && value.length >= 3) {
    final String date = formatQualityTestDate(value);
    if (value.length < 5) {
      return date;
    }
    final int? hour = _int(value[3]);
    final int? minute = _int(value[4]);
    if (hour == null || minute == null) {
      return date;
    }
    return '$date ${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }
  return formatQualityTestDate(value);
}

String formatQualityTestStatus(String? raw) {
  final String value = (raw ?? '').trim();
  if (value.isEmpty) {
    return '';
  }
  return value.replaceAll('_', ' ').toUpperCase();
}

List<QualityTestObligationRow> enrichQualityTestRows({
  required List<QualityTestObligationRow> rows,
  required List<QualityTestOption> projects,
  required List<QualityTestOption> contracts,
}) {
  if (rows.isEmpty) {
    return rows;
  }
  final Map<String, String> projectNames = <String, String>{
    for (final QualityTestOption o in projects) o.value: o.label,
  };
  final Map<String, String> contractNames = <String, String>{
    for (final QualityTestOption o in contracts) o.value: o.label,
  };
  return <QualityTestObligationRow>[
    for (final QualityTestObligationRow row in rows)
      QualityTestObligationRow(
        id: row.id,
        obligationCode: row.obligationCode,
        projectId: row.projectId,
        projectName: row.projectName.isNotEmpty
            ? row.projectName
            : _labelWithoutId(projectNames[row.projectId] ?? '', row.projectId),
        sectionName: row.sectionName,
        contractId: row.contractId,
        contractName: row.contractName.isNotEmpty
            ? row.contractName
            : _labelWithoutId(
                contractNames[row.contractId] ?? '',
                row.contractId,
              ),
        materialCode: row.materialCode,
        materialName: row.materialName,
        testName: row.testName,
        frequencyBasis: row.frequencyBasis,
        generatedFrom: row.generatedFrom,
        obligationBasisCoverage: row.obligationBasisCoverage,
        batchLotNo: row.batchLotNo,
        requiredByDate: row.requiredByDate,
        contractorStatus: row.contractorStatus,
        engineerStatus: row.engineerStatus,
      ),
  ];
}

String _labelWithoutId(String label, String id) {
  final String trimmed = label.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  final String prefix = '${id.trim()} - ';
  if (id.trim().isNotEmpty && trimmed.startsWith(prefix)) {
    return trimmed.substring(prefix.length).trim();
  }
  return trimmed;
}

List<QualityTestOption> _namedOptions(
  List<dynamic> raw, {
  required List<String> idKeys,
  required List<String> nameKeys,
}) {
  final List<QualityTestOption> out = <QualityTestOption>[];
  for (final Map<String, dynamic> json in _listOfMaps(raw)) {
    final String id = _firstText(json, idKeys);
    final String name = _firstText(json, nameKeys);
    if (id.isEmpty && name.isEmpty) {
      continue;
    }
    final String value = id.isEmpty ? name : id;
    final String label = name.isEmpty
        ? id
        : id.isEmpty
        ? name
        : '$id - $name';
    out.add(QualityTestOption(value: value, label: label));
  }
  return out;
}

List<dynamic> _envelopeList(dynamic data) {
  final Map<String, dynamic>? root = _map(data);
  if (root != null) {
    final dynamic nested = root['data'] ?? root['items'] ?? root['results'];
    if (nested is List) {
      return nested;
    }
  }
  if (data is List) {
    return data;
  }
  return const <dynamic>[];
}

List<Map<String, dynamic>> _listOfMaps(dynamic raw) {
  if (raw is! List) {
    return const <Map<String, dynamic>>[];
  }
  final List<Map<String, dynamic>> out = <Map<String, dynamic>>[];
  for (final dynamic item in raw) {
    final Map<String, dynamic>? map = _map(item);
    if (map != null) {
      out.add(map);
    }
  }
  return out;
}

Map<String, dynamic>? _map(dynamic raw) {
  if (raw is Map<String, dynamic>) {
    return raw;
  }
  if (raw is Map) {
    return raw.map(
      (dynamic key, dynamic value) =>
          MapEntry<String, dynamic>(key.toString(), value),
    );
  }
  return null;
}

String _text(dynamic value) {
  if (value == null) {
    return '';
  }
  final String text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return '';
  }
  return text;
}

int? _int(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(_text(value));
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
