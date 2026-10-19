import 'package:swr_pmis_mobile/src/features/utility_shifting/domain/utility_shifting_list.dart';

List<UtilityShiftingOption> parseUtilityShiftingLocations(dynamic data) {
  return _options(data, (Map<String, dynamic> json) {
    final String? value = _text(json['location_name']);
    if (value == null) {
      return null;
    }
    return UtilityShiftingOption(value: value, label: value);
  });
}

List<UtilityShiftingOption> parseUtilityShiftingCategories(dynamic data) {
  return _options(data, (Map<String, dynamic> json) {
    final String? value = _text(json['utility_category_fk']);
    if (value == null) {
      return null;
    }
    return UtilityShiftingOption(value: value, label: value);
  });
}

List<UtilityShiftingOption> parseUtilityShiftingTypes(dynamic data) {
  return _options(data, (Map<String, dynamic> json) {
    final String? value = _text(json['utility_type_fk']);
    if (value == null) {
      return null;
    }
    return UtilityShiftingOption(value: value, label: value);
  });
}

List<UtilityShiftingOption> parseUtilityShiftingStatuses(dynamic data) {
  return _options(data, (Map<String, dynamic> json) {
    final String? value = _text(json['shifting_status_fk']);
    if (value == null) {
      return null;
    }
    return UtilityShiftingOption(value: value, label: value);
  });
}

({List<UtilityShiftingRow> rows, int total}) parseUtilityShiftingList(
  dynamic data,
) {
  final Map<String, dynamic> payload = _dataTablesMap(data);
  final List<UtilityShiftingRow> rows = <UtilityShiftingRow>[];
  for (final Map<String, dynamic> json in _aaData(payload)) {
    final String id = _first(json, const <String>[
      'utility_shifting_id',
      'utility_shifting_id_fk',
      'id',
    ]);
    final String description = _display(json['utility_description']);
    if (id.isEmpty && description.isEmpty) {
      continue;
    }
    rows.add(
      UtilityShiftingRow(
        utilityShiftingId: id,
        project: _first(json, const <String>[
          'project_name',
          'project_id_fk',
        ]),
        executionAgency: _display(json['execution_agency_fk']),
        hod: _first(json, const <String>['designation', 'user_name']),
        utilityType: _display(json['utility_type_fk']),
        description: description,
        location: _display(json['location_name']),
        custodian: _first(json, const <String>[
          'custodian',
          'custodian_fk',
          'utility_custodian',
        ]),
        identificationDate: _formatDate(json['identification']),
        referenceNo: _display(json['reference_number']),
        chainage: _display(json['chainage']),
        executedBy: _display(json['executed_by']),
        impactedContract: _first(json, const <String>[
          'impacted_contract_name',
          'impacted_contract_id_fk',
        ]),
        requirementStage: _display(json['requirement_stage_fk']),
        impactedElement: _display(json['impacted_element']),
        affectedStructures: _display(json['affected_structures']),
        targetDate: _formatDate(json['target_date']),
        scope: _display(json['scope']),
        completed: _display(json['completed']),
        unit: _display(json['unit_fk']),
        startDate: _formatDate(json['start_date']),
        status: _display(json['shifting_status_fk']),
        completionDate: _formatDate(json['shifting_completion_date']),
        remarks: _display(json['remarks']),
        lastUpdate: _display(json['modified_date']),
      ),
    );
  }
  return (rows: rows, total: _total(payload, rows.length));
}

String parseUtilityShiftingUploadMessage(dynamic data) {
  if (data == null) {
    return 'Utility shifting uploaded successfully.';
  }
  if (data is String) {
    final String text = data.trim();
    return text.isEmpty ? 'Utility shifting uploaded successfully.' : text;
  }
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    final String? error = _text(map['error']) ?? _text(map['Error']);
    if (error != null) {
      throw StateError(error);
    }
    for (final String key in const <String>[
      'success',
      'message',
      'msg',
      'result',
    ]) {
      final String? text = _text(map[key]);
      if (text != null) {
        return text;
      }
    }
  }
  return 'Utility shifting uploaded successfully.';
}

List<UtilityShiftingUploadRow> parseUtilityShiftingUploads(dynamic data) {
  final List<UtilityShiftingUploadRow> rows = <UtilityShiftingUploadRow>[];
  for (final Map<String, dynamic> json in _uploadRecords(data)) {
    final String file = _display(json['uploaded_file']);
    final String id = _first(json, const <String>[
      'utility_data_id',
      'utility_data_id_fk',
      'id',
    ]);
    if (file.isEmpty && id.isEmpty) {
      continue;
    }
    rows.add(
      UtilityShiftingUploadRow(
        utilityDataId: id,
        uploadedFile: file,
        status: _display(json['status']),
        remarks: _display(json['remarks']),
        uploadedBy: _display(json['uploaded_by_user_id_fk']),
        uploadedOn: _formatUploadedOn(json['uploaded_on']),
      ),
    );
  }
  return rows;
}

List<UtilityShiftingOption> _options(
  dynamic data,
  UtilityShiftingOption? Function(Map<String, dynamic> json) read,
) {
  final Map<String, UtilityShiftingOption> unique =
      <String, UtilityShiftingOption>{};
  for (final Map<String, dynamic> json in _records(data)) {
    final UtilityShiftingOption? option = read(json);
    if (option == null) {
      continue;
    }
    unique.putIfAbsent(option.value, () => option);
  }
  final List<UtilityShiftingOption> values = unique.values.toList()
    ..sort(
      (UtilityShiftingOption a, UtilityShiftingOption b) =>
          a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );
  return values;
}

List<Map<String, dynamic>> _uploadRecords(dynamic data) {
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    if (map.containsKey('aaData') || map.containsKey('iTotalRecords')) {
      return _aaData(map);
    }
  }
  return _records(data);
}

Map<String, dynamic> _dataTablesMap(dynamic data) {
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    if (_hasDataTables(map)) {
      return map;
    }
    for (final String key in const <String>['data', 'result', 'payload']) {
      final Object? nested = map[key];
      if (nested is Map) {
        final Map<String, dynamic> nestedMap = Map<String, dynamic>.from(
          nested,
        );
        if (_hasDataTables(nestedMap)) {
          return nestedMap;
        }
      }
    }
    return map;
  }
  if (data is List) {
    return <String, dynamic>{'aaData': data, 'iTotalRecords': data.length};
  }
  return <String, dynamic>{};
}

bool _hasDataTables(Map<String, dynamic> map) {
  return map.containsKey('aaData') ||
      map.containsKey('iTotalDisplayRecords') ||
      map.containsKey('iTotalRecords');
}

List<Map<String, dynamic>> _aaData(Map<String, dynamic> map) {
  dynamic raw = map['aaData'] ?? map['rows'];
  if (raw is! List) {
    final Object? nested = map['data'];
    if (nested is List) {
      raw = nested;
    } else if (nested is Map) {
      raw = nested['aaData'] ?? nested['rows'];
    }
  }
  if (raw is! List) {
    return const <Map<String, dynamic>>[];
  }
  return _maps(raw);
}

int _total(Map<String, dynamic> map, int fallback) {
  for (final String key in const <String>[
    'iTotalDisplayRecords',
    'iTotalRecords',
    'recordsFiltered',
    'recordsTotal',
    'total',
  ]) {
    final Object? value = map[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    final int? parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null) {
      return parsed;
    }
  }
  return fallback;
}

List<Map<String, dynamic>> _records(dynamic data) {
  if (data is List) {
    return _maps(data);
  }
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    if (_isRecord(map)) {
      return <Map<String, dynamic>>[map];
    }
    for (final String key in const <String>[
      'data',
      'result',
      'content',
      'list',
      'records',
      'aaData',
    ]) {
      final Object? nested = map[key];
      if (nested is List) {
        return _maps(nested);
      }
      if (nested is Map) {
        return <Map<String, dynamic>>[Map<String, dynamic>.from(nested)];
      }
    }
    return <Map<String, dynamic>>[map];
  }
  return const <Map<String, dynamic>>[];
}

bool _isRecord(Map<String, dynamic> json) {
  const Set<String> keys = <String>{
    'location_name',
    'utility_category_fk',
    'utility_type_fk',
    'shifting_status_fk',
    'utility_shifting_id',
    'uploaded_file',
    'utility_data_id',
  };
  for (final String key in keys) {
    if (json.containsKey(key)) {
      return true;
    }
  }
  return false;
}

List<Map<String, dynamic>> _maps(List<dynamic> data) {
  return data
      .whereType<Map>()
      .map((Map<dynamic, dynamic> item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

String _formatUploadedOn(Object? value) {
  final String raw = _display(value);
  if (raw.isEmpty) {
    return '';
  }
  if (raw.contains('.')) {
    return raw.split('.').first;
  }
  return raw;
}

String _formatDate(Object? value) {
  final String raw = _display(value);
  if (raw.isEmpty) {
    return '';
  }
  final String trimmed = raw.contains('.') ? raw.split('.').first.trim() : raw;
  final Match? iso = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})',
  ).firstMatch(trimmed);
  if (iso != null) {
    return '${iso.group(3)}-${iso.group(2)}-${iso.group(1)}';
  }
  return trimmed;
}

String _display(Object? value) => _text(value) ?? '';

String _first(Map<String, dynamic> json, List<String> keys) {
  for (final String key in keys) {
    final String? text = _text(json[key]);
    if (text != null) {
      return text;
    }
  }
  return '';
}

String? _text(Object? value) {
  if (value == null) {
    return null;
  }
  final String text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }
  return text;
}
