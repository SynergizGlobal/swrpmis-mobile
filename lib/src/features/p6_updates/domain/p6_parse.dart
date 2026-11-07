import 'package:swr_pmis_mobile/src/features/p6_updates/domain/p6_list.dart';

P6FormMaster parseP6FormMaster(dynamic data) {
  final Map<String, dynamic> map = _asMap(data);
  return P6FormMaster(
    projects: parseP6Projects(map['projectsList'] ?? data),
    contracts: parseP6Contracts(map['contractsList'] ?? const <dynamic>[]),
  );
}

List<P6Option> parseP6Projects(dynamic data) {
  return _options(data, (Map<String, dynamic> json) {
    final String? id = _text(json['project_id_fk']);
    if (id == null) {
      return null;
    }
    final String? name = _text(json['project_name']);
    return P6Option(value: id, label: name ?? id);
  });
}

List<P6Option> parseP6Contracts(dynamic data) {
  return _options(data, (Map<String, dynamic> json) {
    final String? id = _text(json['contract_id']) ?? _text(json['contract_id_fk']);
    if (id == null) {
      return null;
    }
    final String? shortName = _text(json['contract_short_name']);
    final String? name = _text(json['contract_name']);
    final String label = shortName ?? name ?? id;
    return P6Option(value: id, label: label);
  });
}

List<P6Option> parseP6HistoryContracts(dynamic data) => parseP6Contracts(data);

List<P6Option> parseP6UploadTypes(dynamic data) {
  return _options(data, (Map<String, dynamic> json) {
    final String? value = _text(json['upload_type']);
    if (value == null) {
      return null;
    }
    return P6Option(value: value, label: value);
  });
}

List<P6Option> parseP6Statuses(dynamic data) {
  return _options(data, (Map<String, dynamic> json) {
    final String? value =
        _text(json['soft_delete_status_fk']) ?? _text(json['status_fk']);
    if (value == null) {
      return null;
    }
    return P6Option(value: value, label: value);
  });
}

List<P6HistoryRow> parseP6HistoryRows(dynamic data) {
  final List<P6HistoryRow> rows = <P6HistoryRow>[];
  for (final Map<String, dynamic> json in _records(data)) {
    final String contractId = _first(json, const <String>[
      'contract_id_fk',
      'contract_id',
    ]);
    final String file = _display(json['p6_file_path']);
    final String dataType = _display(json['upload_type']);
    if (contractId.isEmpty && file.isEmpty && dataType.isEmpty) {
      continue;
    }
    rows.add(
      P6HistoryRow(
        contractId: contractId,
        dataType: dataType,
        dataDate: _display(json['data_date']),
        status: _first(json, const <String>[
          'soft_delete_status_fk',
          'status_fk',
        ]),
        uploadedFile: file,
        uploadedBy: _display(json['uploaded_by_user_id_fk']),
        uploadedDate: _display(json['uploaded_date']),
      ),
    );
  }
  return rows;
}

String parseP6UploadMessage(dynamic data) {
  if (data == null) {
    return 'P6 data uploaded successfully.';
  }
  if (data is String) {
    final String text = data.trim();
    return text.isEmpty ? 'P6 data uploaded successfully.' : text;
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
      'status',
    ]) {
      final String? text = _text(map[key]);
      if (text != null) {
        if (text.toUpperCase() == 'SUCCESS') {
          return 'P6 data uploaded successfully.';
        }
        return text;
      }
    }
  }
  return 'P6 data uploaded successfully.';
}

List<P6Option> _options(
  dynamic data,
  P6Option? Function(Map<String, dynamic> json) read,
) {
  final Map<String, P6Option> unique = <String, P6Option>{};
  for (final Map<String, dynamic> json in _records(data)) {
    final P6Option? option = read(json);
    if (option == null) {
      continue;
    }
    unique.putIfAbsent(option.value, () => option);
  }
  return unique.values.toList(growable: false);
}

List<Map<String, dynamic>> _records(dynamic data) {
  if (data is List) {
    return _maps(data);
  }
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    for (final String key in const <String>[
      'data',
      'result',
      'content',
      'list',
      'records',
      'aaData',
      'projectsList',
      'contractsList',
      'fobList',
    ]) {
      final Object? nested = map[key];
      if (nested is List) {
        return _maps(nested);
      }
    }
    if (_looksLikeRecord(map)) {
      return <Map<String, dynamic>>[map];
    }
  }
  return const <Map<String, dynamic>>[];
}

bool _looksLikeRecord(Map<String, dynamic> json) {
  const Set<String> keys = <String>{
    'project_id_fk',
    'project_name',
    'contract_id',
    'contract_id_fk',
    'contract_short_name',
    'upload_type',
    'soft_delete_status_fk',
    'p6_file_path',
    'data_date',
  };
  for (final String key in keys) {
    if (json.containsKey(key) && json[key] != null) {
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

Map<String, dynamic> _asMap(dynamic data) {
  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }
  return const <String, dynamic>{};
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
