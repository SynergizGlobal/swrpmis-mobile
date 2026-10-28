import 'package:swr_pmis_mobile/src/features/structure_form/domain/structure_form_detail.dart';
import 'package:swr_pmis_mobile/src/features/structure_form/domain/structure_form_list.dart';

List<StructureFormOption> parseStructureFormContracts(dynamic data) {
  return _options(data, (Map<String, dynamic> json) {
    final String? id = _text(json['contract_id_fk']) ?? _text(json['contract_id']);
    if (id == null) {
      return null;
    }
    final String shortName =
        _display(json['contract_short_name']) ;
    final String name = _display(json['contract_name']);
    final String label;
    if (shortName.isNotEmpty && name.isNotEmpty) {
      label = '$shortName - $name';
    } else if (shortName.isNotEmpty) {
      label = shortName;
    } else if (name.isNotEmpty) {
      label = name;
    } else {
      label = id;
    }
    return StructureFormOption(value: id, label: label);
  });
}

List<StructureFormOption> parseStructureFormStructureTypes(dynamic data) {
  return _options(data, (Map<String, dynamic> json) {
    final String? value =
        _text(json['structure_type']) ??
        _text(json['structure_type_fk']) ??
        _text(json['structure_type_id_fk']);
    if (value == null) {
      return null;
    }
    return StructureFormOption(value: value, label: value);
  });
}

List<StructureFormOption> parseStructureFormWorkStatuses(dynamic data) {
  return _options(data, (Map<String, dynamic> json) {
    final String? value =
        _text(json['work_status_fk']) ??
        _text(json['work_status']) ??
        _text(json['status']);
    if (value == null) {
      return null;
    }
    return StructureFormOption(value: value, label: value);
  });
}

({List<StructureFormRow> rows, int total}) parseStructureFormList(
  dynamic data,
) {
  final Map<String, dynamic> payload = _dataTablesMap(data);
  final List<StructureFormRow> rows = <StructureFormRow>[];
  for (final Map<String, dynamic> json in _aaData(payload)) {
    final String id = _first(json, const <String>[
      'structure_id',
      'structure_id_fk',
      'id',
    ]);
    final String structure = _display(json['structure']);
    final String structureName = _display(json['structure_name']);
    if (id.isEmpty && structure.isEmpty && structureName.isEmpty) {
      continue;
    }
    rows.add(
      StructureFormRow(
        structureId: id,
        projectIdFk: _first(json, const <String>[
          'project_id_fk',
          'project_id',
          'project',
        ]),
        structureTypeFk: _first(json, const <String>[
          'structure_type_fk',
          'structure_type',
        ]),
        structure: structure,
        structureName: structureName,
        contractIdFk: _first(json, const <String>[
          'contract_id_fk',
          'contract_id',
        ]),
        contractShortName: _first(json, const <String>[
          'contract_short_name',
          'contract_name',
          'contract',
        ]),
        workStatusFk: _first(json, const <String>[
          'work_status_fk',
          'work_status',
        ]),
      ),
    );
  }
  return (rows: rows, total: _total(payload, rows.length));
}

StructureFormMaster parseStructureFormMaster(dynamic data) {
  final Map<String, dynamic> root = _masterMap(data);

  List<StructureFormFormOption> take(
    List<String> keys,
    StructureFormFormOption? Function(dynamic row) read,
  ) {
    final String? found = _findListKey(root, keys);
    return _readFormOptions(
      found == null ? const <dynamic>[] : root[found],
      read,
    );
  }

  final List<StructureFormFormOption> projects = take(
    const <String>['projectsList', 'projectList'],
    (dynamic row) => _formOption(
      row,
      idKeys: const <String>['project_id_fk', 'project_id', 'projectId'],
      labelKeys: const <String>['project_name', 'projectName', 'name'],
      projectIdKeys: const <String>['project_id_fk', 'project_id'],
    ),
  );

  final List<StructureFormFormOption> contracts = take(
    const <String>['contractsList', 'contractList'],
    (dynamic row) => _contractFormOption(row),
  );

  final List<StructureFormFormOption> structureTypes = take(
    const <String>['structuresList', 'structureTypesList', 'structureTypeList'],
    (dynamic row) => _formOption(
      row,
      idKeys: const <String>[
        'structure_type',
        'structure_type_fk',
        'structure_type_id_fk',
        'id',
      ],
      labelKeys: const <String>[
        'structure_type',
        'structure_type_fk',
        'name',
        'label',
      ],
    ),
  );

  final List<StructureFormFormOption> fileTypes = take(
    const <String>['fileType', 'fileTypes', 'fileTypeList'],
    (dynamic row) {
      if (row is String) {
        final String text = row.trim();
        if (text.isEmpty) {
          return null;
        }
        return StructureFormFormOption(id: text, label: text);
      }
      return _formOption(
        row,
        idKeys: const <String>[
          'structure_file_type_fk',
          'structure_file_type',
          'file_type',
          'name',
          'id',
        ],
        labelKeys: const <String>[
          'structure_file_type',
          'structure_file_type_fk',
          'file_type',
          'name',
          'label',
        ],
      );
    },
  );

  final List<StructureFormFormOption> workStatuses = _parseWorkStatuses(root);

  final List<StructureFormPersonOption> people = _parsePeople(
    root['responsiblePeopleList'] ?? root['responsible_people_list'],
  );

  final StructureFormDetail detail = parseStructureFormDetail(root);
  final String action = _display(root['action']);

  return StructureFormMaster(
    projects: projects,
    contracts: contracts,
    structureTypes: structureTypes,
    workStatuses: workStatuses,
    fileTypes: fileTypes,
    responsiblePeople: people,
    detail: detail.isEmpty ? null : detail,
    action: action,
  );
}

StructureFormDetail parseStructureFormDetail(Map<String, dynamic> root) {
  final Map<String, dynamic>? structureMap = _firstMap(
    root,
    const <String>['structuresListDetails', 'structureDetails', 'structure'],
  );
  if (structureMap == null) {
    return StructureFormDetail.empty;
  }

  final String structureId = _first(structureMap, const <String>[
    'structure_id',
    'structure_id_fk',
    'id',
  ]);
  final String projectIdFk = _first(structureMap, const <String>[
    'project_id_fk',
    'project_id',
  ]);
  final String structureTypeFk = _first(structureMap, const <String>[
    'structure_type_fk',
    'structure_type',
  ]);
  final String structure = _display(structureMap['structure']);
  final String structureName = _display(structureMap['structure_name']);
  final String workStatusFk = _first(structureMap, const <String>[
    'work_status_fk',
    'work_status',
  ]);

  final List<StructureFormExecutiveRow> executives = <StructureFormExecutiveRow>[];
  for (final Map<String, dynamic> exec in _maps(
    structureMap['executivesList'] ?? structureMap['executiveList'],
  )) {
    final String contractId = _first(exec, const <String>[
      'contract_id_fk',
      'contract_id',
    ]);
    final String shortName = _display(exec['contract_short_name']);
    final String contractName = _display(exec['contract_name']);
    final String label = shortName.isNotEmpty
        ? (contractName.isNotEmpty ? '$shortName - $contractName' : shortName)
        : (contractName.isNotEmpty ? contractName : contractId);
    final List<StructureFormResponsiblePerson> people =
        <StructureFormResponsiblePerson>[];
    for (final Map<String, dynamic> person in _maps(
      exec['responsiblePeopleLists'] ??
          exec['responsiblePeopleList'] ??
          exec['responsible_people'],
    )) {
      final String personId = _first(person, const <String>[
        'responsible_people_id_fk',
        'user_id',
        'user_id_fk',
        'id',
      ]);
      if (personId.isEmpty) {
        continue;
      }
      people.add(
        StructureFormResponsiblePerson(
          id: personId,
          userName: _display(person['user_name']),
          designation: _display(person['designation']),
          rowId: _display(person['id']),
        ),
      );
    }
    if (contractId.isEmpty && people.isEmpty) {
      continue;
    }
    executives.add(
      StructureFormExecutiveRow(
        contractIdFk: contractId,
        contractLabel: label,
        people: people,
      ),
    );
  }

  final List<StructureFormDetailRow> details = <StructureFormDetailRow>[];
  for (final Map<String, dynamic> item in _maps(
    structureMap['structureDetailsList1'] ??
        structureMap['structureDetailsList'] ??
        structureMap['structure_details'],
  )) {
    final String detail = _display(item['structure_detail']);
    final String value = _display(item['structure_value']);
    if (detail.isEmpty && value.isEmpty) {
      continue;
    }
    details.add(
      StructureFormDetailRow(
        id: _display(item['id']),
        structureDetail: detail,
        structureValue: value,
      ),
    );
  }

  final List<StructureFormDocumentRow> documents = <StructureFormDocumentRow>[];
  for (final Map<String, dynamic> item in _maps(
    structureMap['documentsList'] ?? structureMap['documents'],
  )) {
    final String fileType = _first(item, const <String>[
      'structure_file_type_fk',
      'structure_file_type',
      'file_type',
    ]);
    final String name = _display(item['name']);
    final String attachment = _first(item, const <String>[
      'attachment',
      'file_name',
      'fileName',
    ]);
    if (fileType.isEmpty && name.isEmpty && attachment.isEmpty) {
      continue;
    }
    documents.add(
      StructureFormDocumentRow(
        structureFileId: _first(item, const <String>[
          'structure_file_id',
          'id',
        ]),
        fileType: fileType,
        name: name,
        existingAttachment: attachment,
      ),
    );
  }

  return StructureFormDetail(
    structureId: structureId,
    projectIdFk: projectIdFk,
    structureTypeFk: structureTypeFk,
    structure: structure,
    structureName: structureName,
    workStatusFk: workStatusFk,
    executives: executives,
    details: details,
    documents: documents,
  );
}

List<StructureFormFormOption> parseStructureFormContractsForProject(
  dynamic data,
) {
  return _readFormOptions(data, _contractFormOption);
}

String parseStructureFormUpdateMessage(dynamic data) {
  if (data == null) {
    return 'Structure updated';
  }
  if (data is String) {
    final String text = data.trim();
    return text.isEmpty ? 'Structure updated' : text;
  }
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    final String? error = _text(map['error']) ?? _text(map['Error']);
    if (error != null) {
      return error;
    }
    for (final String key in const <String>[
      'message',
      'msg',
      'success',
      'result',
    ]) {
      final Object? value = map[key];
      if (value is bool) {
        continue;
      }
      final String? text = _text(value);
      if (text != null) {
        return text;
      }
    }
  }
  return 'Structure updated';
}

bool isStructureFormUpdateSuccess(dynamic data) {
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    final Object? success = map['success'];
    if (success is bool) {
      return success;
    }
    final String? text = _text(success)?.toLowerCase();
    if (text == 'true' || text == '1' || text == 'yes') {
      return true;
    }
    if (text == 'false' || text == '0' || text == 'no') {
      return false;
    }
    final String? error = _text(map['error']) ?? _text(map['Error']);
    if (error != null) {
      return false;
    }
    final String? message = _text(map['message'])?.toLowerCase();
    if (message != null &&
        (message.contains('fail') || message.contains('error'))) {
      return false;
    }
  }
  return true;
}

List<StructureFormFormOption> _parseWorkStatuses(Map<String, dynamic> root) {
  final Object? preferred = root['executionStatusList'];
  if (preferred != null) {
    final List<StructureFormFormOption> fromPreferred = _readFormOptions(
      preferred,
      (dynamic row) {
        if (row is String) {
          final String text = row.trim();
          if (text.isEmpty) {
            return null;
          }
          return StructureFormFormOption(id: text, label: text);
        }
        return _formOption(
          row,
          idKeys: const <String>['work_status_fk', 'status', 'name', 'id'],
          labelKeys: const <String>['work_status_fk', 'status', 'name', 'label'],
        );
      },
    );
    if (fromPreferred.isNotEmpty) {
      return fromPreferred;
    }
  }
  return _readFormOptions(
    root['workStatusList'] ?? root['workStatuses'],
    (dynamic row) {
      if (row is String) {
        final String text = row.trim();
        if (text.isEmpty) {
          return null;
        }
        return StructureFormFormOption(id: text, label: text);
      }
      return _formOption(
        row,
        idKeys: const <String>['work_status_fk', 'status', 'name', 'id'],
        labelKeys: const <String>['work_status_fk', 'status', 'name', 'label'],
      );
    },
  );
}

List<StructureFormPersonOption> _parsePeople(dynamic data) {
  final List<StructureFormPersonOption> people = <StructureFormPersonOption>[];
  final Map<String, StructureFormPersonOption> unique =
      <String, StructureFormPersonOption>{};
  for (final Map<String, dynamic> json in _maps(data)) {
    final String id = _first(json, const <String>[
      'user_id',
      'user_id_fk',
      'responsible_people_id_fk',
      'id',
    ]);
    if (id.isEmpty) {
      continue;
    }
    unique.putIfAbsent(
      id,
      () => StructureFormPersonOption(
        id: id,
        userName: _display(json['user_name']),
        designation: _display(json['designation']),
      ),
    );
  }
  people.addAll(unique.values);
  people.sort(
    (StructureFormPersonOption a, StructureFormPersonOption b) =>
        a.label.toLowerCase().compareTo(b.label.toLowerCase()),
  );
  return people;
}

StructureFormFormOption? _contractFormOption(dynamic row) {
  return _formOption(
    row,
    idKeys: const <String>['contract_id_fk', 'contract_id', 'contractId'],
    labelKeys: const <String>[
      'contract_short_name',
      'contract_name',
      'contractName',
      'name',
    ],
    projectIdKeys: const <String>['project_id_fk', 'project_id'],
    combineShortAndName: true,
  );
}

StructureFormFormOption? _formOption(
  dynamic row, {
  required List<String> idKeys,
  required List<String> labelKeys,
  List<String> projectIdKeys = const <String>[],
  bool combineShortAndName = false,
}) {
  if (row is! Map) {
    return null;
  }
  final Map<String, dynamic> json = Map<String, dynamic>.from(row);
  final String id = _first(json, idKeys);
  if (id.isEmpty) {
    return null;
  }
  String label = _first(json, labelKeys);
  if (combineShortAndName) {
    final String shortName = _display(json['contract_short_name']);
    final String name = _display(json['contract_name']);
    if (shortName.isNotEmpty && name.isNotEmpty && shortName != name) {
      label = '$shortName - $name';
    } else if (shortName.isNotEmpty) {
      label = shortName;
    } else if (name.isNotEmpty) {
      label = name;
    }
  }
  if (label.isEmpty) {
    label = id;
  }
  return StructureFormFormOption(
    id: id,
    label: label,
    projectId: _first(json, projectIdKeys),
  );
}

List<StructureFormFormOption> _readFormOptions(
  dynamic data,
  StructureFormFormOption? Function(dynamic row) read,
) {
  final Map<String, StructureFormFormOption> unique =
      <String, StructureFormFormOption>{};
  if (data is List) {
    for (final dynamic item in data) {
      final StructureFormFormOption? option = read(item);
      if (option == null) {
        continue;
      }
      unique.putIfAbsent(option.id, () => option);
    }
  } else if (data is Map) {
    final StructureFormFormOption? option = read(data);
    if (option != null) {
      unique[option.id] = option;
    } else {
      for (final Object? value in data.values) {
        if (value is List) {
          for (final dynamic item in value) {
            final StructureFormFormOption? nested = read(item);
            if (nested != null) {
              unique.putIfAbsent(nested.id, () => nested);
            }
          }
        }
      }
    }
  }
  final List<StructureFormFormOption> values = unique.values.toList()
    ..sort(
      (StructureFormFormOption a, StructureFormFormOption b) =>
          a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );
  return values;
}

List<StructureFormOption> _options(
  dynamic data,
  StructureFormOption? Function(Map<String, dynamic> json) read,
) {
  final Map<String, StructureFormOption> unique =
      <String, StructureFormOption>{};
  for (final Map<String, dynamic> json in _records(data)) {
    final StructureFormOption? option = read(json);
    if (option == null) {
      continue;
    }
    unique.putIfAbsent(option.value, () => option);
  }
  final List<StructureFormOption> values = unique.values.toList()
    ..sort(
      (StructureFormOption a, StructureFormOption b) =>
          a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );
  return values;
}

Map<String, dynamic> _masterMap(dynamic data) {
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    for (final String key in const <String>['data', 'result', 'payload']) {
      final Object? nested = map[key];
      if (nested is Map) {
        final Map<String, dynamic> nestedMap = Map<String, dynamic>.from(
          nested,
        );
        if (nestedMap.containsKey('projectsList') ||
            nestedMap.containsKey('structuresListDetails') ||
            nestedMap.containsKey('contractsList')) {
          return nestedMap;
        }
      }
    }
    return map;
  }
  return <String, dynamic>{};
}

String? _findListKey(Map<String, dynamic> root, List<String> keys) {
  for (final String key in keys) {
    if (root.containsKey(key) && root[key] != null) {
      return key;
    }
  }
  return null;
}

Map<String, dynamic>? _firstMap(
  Map<String, dynamic> root,
  List<String> keys,
) {
  for (final String key in keys) {
    final Object? value = root[key];
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    if (value is List && value.isNotEmpty && value.first is Map) {
      return Map<String, dynamic>.from(value.first as Map);
    }
  }
  return null;
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
    'structure_type',
    'structure_type_fk',
    'work_status_fk',
    'structure_id',
    'structure_name',
  };
  for (final String key in keys) {
    if (json.containsKey(key)) {
      return true;
    }
  }
  return false;
}

List<Map<String, dynamic>> _maps(dynamic data) {
  if (data is! List) {
    return const <Map<String, dynamic>>[];
  }
  return data
      .whereType<Map>()
      .map((Map<dynamic, dynamic> item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
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
