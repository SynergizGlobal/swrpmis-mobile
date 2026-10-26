import 'package:swr_pmis_mobile/src/features/ncr_observations/domain/ncr_observation_detail.dart';
import 'package:swr_pmis_mobile/src/features/ncr_observations/domain/ncr_observation_list.dart';

({List<NcrObservationRow> rows, int total}) parseNcrObservationList(
  dynamic data, {
  int apiPage = 0,
  int pageSize = 10,
  int? headerTotal,
}) {
  final List<Map<String, dynamic>> maps;
  int? total;

  final Map<String, dynamic>? root = _map(data);
  if (root != null) {
    final dynamic nested =
        root['data'] ??
        root['content'] ??
        root['items'] ??
        root['results'];
    maps = _listOfMaps(nested ?? (root.containsKey('id') ? <dynamic>[root] : null));
    total =
        _int(root['totalRecords']) ??
        _int(root['totalElements']) ??
        _int(root['total']) ??
        headerTotal;
  } else if (data is List) {
    maps = _listOfMaps(data);
    total = headerTotal;
  } else {
    return (rows: const <NcrObservationRow>[], total: 0);
  }

  final List<NcrObservationRow> rows = <NcrObservationRow>[];
  for (final Map<String, dynamic> json in maps) {
    final int? id = _int(json['id']);
    final String code = _text(json['ncrCode']);
    if (id == null || code.isEmpty) {
      continue;
    }
    rows.add(_rowFromJson(json, id: id, code: code));
  }

  if (total != null && total >= 0) {
    return (rows: rows, total: total);
  }

  final int size = pageSize < 1 ? 10 : pageSize;
  final int page = apiPage < 0 ? 0 : apiPage;
  final int offset = page * size;
  if (rows.length < size) {
    return (rows: rows, total: offset + rows.length);
  }
  // Full page without total header — allow advancing one more page.
  return (rows: rows, total: offset + rows.length + 1);
}

NcrObservationDetail parseNcrObservationDetail(
  dynamic data, {
  NcrObligationReference obligation = NcrObligationReference.empty,
  List<NcrAttachment> issueAttachments = const <NcrAttachment>[],
  List<NcrAttachment> correctiveAttachments = const <NcrAttachment>[],
}) {
  final Map<String, dynamic>? root = _map(data);
  if (root == null) {
    throw StateError('Empty NCR observation response.');
  }
  final Map<String, dynamic>? payload =
      _map(root['data']) ?? (root.containsKey('id') ? root : null);
  if (payload == null) {
    throw StateError('NCR observation details missing.');
  }
  final int? id = _int(payload['id']);
  final String code = _text(payload['ncrCode']);
  if (id == null || code.isEmpty) {
    throw StateError('NCR observation id missing.');
  }
  return NcrObservationDetail(
    id: id,
    ncrCode: code,
    ncrType: _text(payload['ncrType']),
    severity: _text(payload['severity']),
    description: _text(payload['description']),
    applicableRequirement: _text(payload['applicableRequirement']),
    projectId: _text(payload['projectId']),
    sectionId: _text(payload['sectionId']),
    contractId: _text(payload['contractId']),
    location: _text(payload['location']),
    sourceType: _text(payload['sourceType']),
    testObligationId: _int(payload['testObligationId']),
    materialReceiptId: _text(payload['materialReceiptId']),
    raisedBy: _text(payload['raisedBy']),
    raisedDate: formatNcrDate(payload['raisedDate']),
    responsibleContractorId: _text(payload['responsibleContractorId']),
    correctiveActionRequired: _text(payload['correctiveActionRequired']),
    targetClosureDate: formatNcrDate(payload['targetClosureDate']),
    status: _text(payload['status']),
    correctiveActionTaken: _text(payload['correctiveActionTaken']),
    submittedBy: _text(payload['submittedBy']),
    submittedOn: formatNcrDateTime(payload['submittedOn']),
    verifiedBy: _text(payload['verifiedBy']),
    verifiedOn: formatNcrDateTime(payload['verifiedOn']),
    verificationRemarks: _text(payload['verificationRemarks']),
    retestObligationId: _int(payload['retestObligationId']),
    overdue: payload['overdue'] == true,
    obligation: obligation,
    issueAttachments: issueAttachments,
    correctiveAttachments: correctiveAttachments,
  );
}

NcrObligationReference parseNcrObligationReference(dynamic data) {
  final Map<String, dynamic>? root = _map(data);
  if (root == null) {
    return NcrObligationReference.empty;
  }
  final Map<String, dynamic>? payload =
      _map(root['data']) ?? (root.containsKey('id') ? root : null);
  if (payload == null) {
    return NcrObligationReference.empty;
  }
  final int? id = _int(payload['id']);
  if (id == null) {
    return NcrObligationReference.empty;
  }
  return NcrObligationReference(
    id: id,
    obligationCode: _text(payload['obligationCode']),
    materialName: _text(payload['materialName']),
    batchLotNo: _text(payload['batchLotNo']),
    testName: _text(payload['testName']),
  );
}

List<NcrAttachment> parseNcrAttachments(dynamic data) {
  final List<Map<String, dynamic>> maps;
  final Map<String, dynamic>? root = _map(data);
  if (root != null) {
    maps = _listOfMaps(
      root['data'] ?? root['content'] ?? root['items'] ?? root['results'],
    );
  } else {
    maps = _listOfMaps(data);
  }
  final List<NcrAttachment> out = <NcrAttachment>[];
  for (final Map<String, dynamic> json in maps) {
    final int? id = _int(json['id']);
    final String fileName = _text(json['fileName']);
    final String filePath = _text(json['filePath']);
    if (id == null || (fileName.isEmpty && filePath.isEmpty)) {
      continue;
    }
    out.add(
      NcrAttachment(
        id: id,
        fileName: fileName.isEmpty ? filePath.split('/').last : fileName,
        filePath: filePath,
        attachmentStage: _text(json['attachmentStage']),
        fileSizeKb: _int(json['fileSizeKb']),
      ),
    );
  }
  return out;
}

String formatNcrDateTime(dynamic value) {
  if (value == null) {
    return '';
  }
  if (value is List && value.length >= 3) {
    final String date = formatNcrDate(value);
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
  return formatNcrDate(value);
}

List<NcrOption> parseNcrDropdownProjects(dynamic data) {
  return _namedOptions(
    _envelopeList(data),
    idKeys: const <String>['projectIdFk', 'project_id', 'projectId', 'id'],
    nameKeys: const <String>['projectName', 'project_name', 'name'],
  );
}

List<NcrOption> parseNcrDropdownSections(dynamic data) {
  return _namedOptions(
    _envelopeList(data),
    idKeys: const <String>['section_id', 'sectionId', 'id'],
    nameKeys: const <String>['section_name', 'sectionName', 'name'],
  );
}

List<NcrOption> parseNcrDropdownContracts(dynamic data) {
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

List<NcrObservationRow> enrichNcrRows({
  required List<NcrObservationRow> rows,
  required List<NcrOption> projects,
  required List<NcrOption> contracts,
}) {
  if (rows.isEmpty) {
    return rows;
  }
  final Map<String, String> projectNames = <String, String>{
    for (final NcrOption o in projects) o.value: o.label,
  };
  final Map<String, String> contractNames = <String, String>{
    for (final NcrOption o in contracts) o.value: o.label,
  };
  return <NcrObservationRow>[
    for (final NcrObservationRow row in rows)
      NcrObservationRow(
        id: row.id,
        ncrCode: row.ncrCode,
        ncrType: row.ncrType,
        severity: row.severity,
        description: row.description,
        location: row.location,
        testObligationId: row.testObligationId,
        sourceType: row.sourceType,
        status: row.status,
        overdue: row.overdue,
        raisedDate: row.raisedDate,
        targetClosureDate: row.targetClosureDate,
        projectId: row.projectId,
        projectName: row.projectName.isNotEmpty
            ? row.projectName
            : _labelWithoutId(projectNames[row.projectId] ?? '', row.projectId),
        sectionId: row.sectionId,
        contractId: row.contractId,
        contractName: row.contractName.isNotEmpty
            ? row.contractName
            : _labelWithoutId(
                contractNames[row.contractId] ?? '',
                row.contractId,
              ),
        materialReceiptId: row.materialReceiptId,
        responsibleContractorId: row.responsibleContractorId,
      ),
  ];
}

String formatNcrDate(dynamic value) {
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

String formatNcrEnumLabel(String? raw) {
  final String value = (raw ?? '').trim();
  if (value.isEmpty) {
    return '';
  }
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((String part) => part.isNotEmpty)
      .map((String part) {
        final String lower = part.toLowerCase();
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
      })
      .join(' ');
}

NcrObservationRow _rowFromJson(
  Map<String, dynamic> json, {
  required int id,
  required String code,
}) {
  return NcrObservationRow(
    id: id,
    ncrCode: code,
    ncrType: _text(json['ncrType']),
    severity: _text(json['severity']),
    description: _text(json['description']),
    location: _text(json['location']),
    testObligationId: _int(json['testObligationId']),
    sourceType: _text(json['sourceType']),
    status: _text(json['status']),
    overdue: json['overdue'] == true,
    raisedDate: formatNcrDate(json['raisedDate']),
    targetClosureDate: formatNcrDate(json['targetClosureDate']),
    projectId: _text(json['projectId']),
    projectName: _text(json['projectName']),
    sectionId: _text(json['sectionId']),
    contractId: _text(json['contractId']),
    contractName: _text(json['contractName']),
    materialReceiptId: _text(json['materialReceiptId']),
    responsibleContractorId: _text(json['responsibleContractorId']),
  );
}

List<NcrOption> _namedOptions(
  List<dynamic> raw, {
  required List<String> idKeys,
  required List<String> nameKeys,
}) {
  final List<NcrOption> out = <NcrOption>[];
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
    out.add(NcrOption(value: value, label: label));
  }
  return out;
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
