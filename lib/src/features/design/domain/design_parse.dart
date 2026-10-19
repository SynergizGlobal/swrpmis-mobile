import 'package:swr_pmis_mobile/src/features/design/domain/design_list.dart';

List<DesignOption> parseDesignContracts(dynamic data) {
  return _options(data, (Map<String, dynamic> json) {
    final String? id = _text(json['contract_id_fk']);
    if (id == null) {
      return null;
    }
    final String? shortName = _text(json['contract_short_name']);
    final String? name = _text(json['contract_name']);
    final String label = shortName ?? name ?? id;
    return DesignOption(value: id, label: label);
  });
}

List<DesignOption> parseDesignStructureTypes(dynamic data) {
  return _options(data, (Map<String, dynamic> json) {
    final String? value = _text(json['structure_type_fk']);
    if (value == null) {
      return null;
    }
    return DesignOption(value: value, label: value);
  });
}

List<DesignOption> parseDesignDrawingTypes(dynamic data) {
  return _options(data, (Map<String, dynamic> json) {
    final String? value = _text(json['drawing_type_fk']);
    if (value == null) {
      return null;
    }
    return DesignOption(value: value, label: value);
  });
}

({List<DesignRow> rows, int total}) parseDesignsList(dynamic data) {
  final Map<String, dynamic> payload = _dataTablesMap(data);
  final List<DesignRow> rows = <DesignRow>[];
  for (final Map<String, dynamic> json in _aaData(payload)) {
    final String pmisDrawingNo = _display(json['design_seq_id']);
    final String designId = _first(json, const <String>[
      'design_id',
      'design_id_fk',
      'design_seq_id',
    ]);
    if (pmisDrawingNo.isEmpty && designId.isEmpty) {
      continue;
    }
    rows.add(
      DesignRow(
        designId: designId.isEmpty ? pmisDrawingNo : designId,
        pmisDrawingNo: pmisDrawingNo,
        structureType: _display(json['structure_type_fk']),
        structure: _display(json['structure_id_fk']),
        title: _display(json['drawing_title']),
        drawingType: _display(json['drawing_type_fk']),
        drawingNo: _drawingNo(json),
        lastUpdate: _display(json['modified_date']),
      ),
    );
  }
  return (rows: rows, total: _total(payload, rows.length));
}

String parseDesignUploadMessage(dynamic data) {
  if (data == null) {
    return 'Designs uploaded successfully.';
  }
  if (data is String) {
    final String text = data.trim();
    return text.isEmpty ? 'Designs uploaded successfully.' : text;
  }
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
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
    final String? error = _text(map['error']) ?? _text(map['Error']);
    if (error != null) {
      throw StateError(error);
    }
  }
  return 'Designs uploaded successfully.';
}

List<DesignUploadRow> parseDesignUploads(dynamic data) {
  final List<DesignUploadRow> rows = <DesignUploadRow>[];
  for (final Map<String, dynamic> json in _uploadRecords(data)) {
    final String file = _display(json['uploaded_file']);
    final String id = _first(json, const <String>[
      'design_data_id',
      'design_data_id_fk',
      'id',
    ]);
    if (file.isEmpty && id.isEmpty) {
      continue;
    }
    rows.add(
      DesignUploadRow(
        designDataId: id,
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

String _drawingNo(Map<String, dynamic> json) {
  return _first(json, const <String>[
    'drawing_no',
    'mrvc_drawing_no',
    'contractor_drawing_no',
    'division_drawing_no',
    'hq_drawing_no',
  ]);
}

List<DesignOption> _options(
  dynamic data,
  DesignOption? Function(Map<String, dynamic> json) read,
) {
  final Map<String, DesignOption> unique = <String, DesignOption>{};
  for (final Map<String, dynamic> json in _records(data)) {
    final DesignOption? option = read(json);
    if (option == null) {
      continue;
    }
    unique.putIfAbsent(option.value, () => option);
  }
  final List<DesignOption> values = unique.values.toList()
    ..sort(
      (DesignOption a, DesignOption b) =>
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
    'contract_id_fk',
    'contract_short_name',
    'contract_name',
    'structure_type_fk',
    'drawing_type_fk',
    'design_seq_id',
    'uploaded_file',
    'design_data_id',
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
