import 'package:swr_pmis_mobile/src/features/contracts/domain/contract_form.dart';
import 'package:swr_pmis_mobile/src/features/contracts/domain/contract_list.dart';

List<ContractOption> parseContractProjects(dynamic data) {
  return _options(data, (Map<String, dynamic> json) {
    final String? id =
        _text(json['project_id_fk']) ??
        _text(json['project_id']) ??
        _text(json['id']);
    if (id == null) {
      return null;
    }
    final String name =
        _display(json['project_name']) ;
    final String label = name.isEmpty || name == id ? id : '$id - $name';
    return ContractOption(value: id, label: label);
  });
}

List<ContractOption> parseContractHods(dynamic data) {
  return _options(data, (Map<String, dynamic> json) {
    final String? value =
        _text(json['designation']) ??
        _text(json['hod']) ??
        _text(json['hod_user_id_fk']) ??
        _text(json['user_id']) ??
        _text(json['name']);
    if (value == null) {
      return null;
    }
    final String label =
        _first(json, const <String>[
          'user_name',
          'name',
          'hod',
          'designation',
        ]).trim();
    return ContractOption(
      value: value,
      label: label.isEmpty ? value : label,
    );
  });
}

List<ContractOption> parseContractDyHods(dynamic data) {
  return _options(data, (Map<String, dynamic> json) {
    final String? value =
        _text(json['dy_hod']) ??
        _text(json['dy_hod_designation']) ??
        _text(json['designation']) ??
        _text(json['dy_hod_user_id_fk']) ??
        _text(json['user_id']) ??
        _text(json['name']);
    if (value == null) {
      return null;
    }
    final String label =
        _first(json, const <String>[
          'user_name',
          'name',
          'dy_hod',
          'designation',
        ]).trim();
    return ContractOption(
      value: value,
      label: label.isEmpty ? value : label,
    );
  });
}

List<ContractOption> parseContractContractors(dynamic data) {
  return _options(data, (Map<String, dynamic> json) {
    final String? id =
        _text(json['contractor_id_fk']) ??
        _text(json['contractor_id']) ??
        _text(json['id']) ??
        _text(json['organization']);
    if (id == null) {
      return null;
    }
    final String label =
        _first(json, const <String>[
          'contractor_name',
          'organization',
          'name',
          'user_name',
        ]).trim();
    return ContractOption(value: id, label: label.isEmpty ? id : label);
  });
}

List<ContractOption> parseContractStatuses(dynamic data) {
  return _options(data, (Map<String, dynamic> json) {
    final String? value =
        _text(json['contract_status']) ??
        _text(json['contract_status_fk']) ??
        _text(json['status']);
    if (value == null) {
      return null;
    }
    return ContractOption(value: value, label: value);
  });
}

List<ContractOption> parseContractWorkStatuses(dynamic data) {
  return _options(data, (Map<String, dynamic> json) {
    final String? value =
        _text(json['status']) ??
        _text(json['work_status_fk']) ??
        _text(json['work_status']) ??
        _text(json['status_of_work']);
    if (value == null) {
      return null;
    }
    return ContractOption(value: value, label: value);
  });
}

({List<ContractRow> rows, int total}) parseContractList(dynamic data) {
  final Map<String, dynamic> payload = _dataTablesMap(data);
  final List<ContractRow> rows = <ContractRow>[];
  for (final Map<String, dynamic> json in _aaData(payload)) {
    final String id = _first(json, const <String>[
      'contract_id_fk',
      'contract_id',
      'contract_id_code',
      'id',
    ]);
    final String name = _display(json['contract_name']);
    final String shortName = _display(json['contract_short_name']);
    if (id.isEmpty && name.isEmpty && shortName.isEmpty) {
      continue;
    }
    rows.add(
      ContractRow(
        contractId: id,
        projectIdFk: _first(json, const <String>[
          'project_id_fk',
          'project_id',
          'project',
        ]),
        projectName: _first(json, const <String>[
          'project_name',
          'work_name',
        ]),
        contractName: name,
        contractShortName: shortName,
        contractorName: _first(json, const <String>[
          'contractor_name',
          'contractor',
          'organization',
        ]),
        department: _first(json, const <String>[
          'department_name',
          'department_fk',
          'department',
          'contract_department',
        ]),
        hod: _first(json, const <String>[
          'hod',
          'hod_designation',
          'designation',
          'hod_user_name',
        ]),
        dyHod: _first(json, const <String>[
          'dy_hod',
          'dy_hod_designation',
          'dy_hod_user_name',
        ]),
        contractStatus: _first(json, const <String>[
          'contract_status',
          'contract_status_fk',
        ]),
        workStatus: _first(json, const <String>[
          'status',
          'work_status_fk',
          'work_status',
          'status_of_work',
        ]),
        lastUpdate: _formatDate(
          json['last_update'] ??
              json['modified_date'] ??
              json['updated_on'] ??
              json['last_updated'],
        ),
      ),
    );
  }
  return (rows: rows, total: _total(payload, rows.length));
}

ContractFormMaster parseContractFormMaster(dynamic data) {
  final Map<String, dynamic> root = _masterMap(data);
  List<ContractFormOption> take(
    List<String> keys, {
    required List<String> idKeys,
    required List<String> labelKeys,
    List<String> metaKeys = const <String>[],
  }) {
    final Object? raw = _findList(root, keys);
    return _formOptions(
      raw,
      idKeys: idKeys,
      labelKeys: labelKeys,
      metaKeys: metaKeys,
    );
  }

  final List<ContractFormOption> projects = take(
    const <String>['projectsList', 'projectList', 'projects'],
    idKeys: const <String>['project_id_fk', 'project_id', 'id'],
    labelKeys: const <String>['project_name', 'work_name', 'name'],
  );
  final List<ContractFormOption> departments = take(
    const <String>['departmentList', 'departmentsList', 'departments'],
    idKeys: const <String>[
      'department_fk',
      'department_id_fk',
      'department_id',
      'id',
      'department_name',
      'name',
    ],
    labelKeys: const <String>['department_name', 'name', 'department_fk'],
  );
  final List<ContractFormOption> hods = take(
    const <String>['hodList', 'hodsList', 'hods'],
    idKeys: const <String>[
      'user_id',
      'hod_user_id_fk',
      'id',
      'designation',
      'name',
    ],
    labelKeys: const <String>[
      'user_name',
      'name',
      'designation',
      'hod',
    ],
  );
  final List<ContractFormOption> dyHods = take(
    const <String>[
      'dyHodList',
      'dy_hodList',
      'dyHodsList',
      'dyHodDesignationsList',
    ],
    idKeys: const <String>[
      'user_id',
      'dy_hod_user_id_fk',
      'id',
      'designation',
      'name',
    ],
    labelKeys: const <String>[
      'user_name',
      'name',
      'designation',
      'dy_hod',
    ],
  );
  final List<ContractFormOption> units = take(
    const <String>['unitsList', 'unitList', 'units'],
    idKeys: const <String>['unit', 'unit_fk', 'id', 'name', 'value'],
    labelKeys: const <String>['unit', 'name', 'label', 'value'],
  );
  final List<ContractFormOption> responsiblePeople = take(
    const <String>[
      'responsiblePeopleList',
      'responsible_peopleList',
      'executivesList',
    ],
    idKeys: const <String>[
      'user_id',
      'responsible_people_id_fk',
      'id',
      'executive_user_id_fk',
    ],
    labelKeys: const <String>['user_name', 'name', 'designation'],
    metaKeys: const <String>['department_fk', 'department_name', 'department'],
  );
  final List<ContractFormOption> contractors = take(
    const <String>['contractors', 'contractorsList', 'contractorList'],
    idKeys: const <String>[
      'contractor_id_fk',
      'contractor_id',
      'organization',
      'id',
    ],
    labelKeys: const <String>[
      'contractor_name',
      'organization',
      'name',
      'user_name',
    ],
  );
  final List<ContractFormOption> contractStatuses = take(
    const <String>[
      'contract_Status',
      'contract_status',
      'contractStatusList',
      'contractStatuses',
    ],
    idKeys: const <String>[
      'contract_status',
      'contract_status_fk',
      'status',
      'id',
      'name',
    ],
    labelKeys: const <String>[
      'contract_status',
      'status',
      'name',
      'label',
    ],
  );
  final List<ContractFormOption> contractTypes = take(
    const <String>[
      'contract_type',
      'contract_Type',
      'contractTypeList',
      'contractTypes',
    ],
    idKeys: const <String>[
      'contract_type',
      'contract_type_fk',
      'id',
      'name',
    ],
    labelKeys: const <String>['contract_type', 'name', 'label'],
  );
  final List<ContractFormOption> workStatuses = take(
    const <String>[
      'statusList',
      'workStatusList',
      'statuses',
      'status_of_work',
    ],
    idKeys: const <String>[
      'status',
      'work_status_fk',
      'work_status',
      'id',
      'name',
    ],
    labelKeys: const <String>['status', 'work_status', 'name', 'label'],
  );
  final List<ContractFormOption> banks = take(
    const <String>['banksList', 'bankList', 'banks'],
    idKeys: const <String>['bank_name', 'bank', 'id', 'name'],
    labelKeys: const <String>['bank_name', 'bank', 'name', 'label'],
  );
  final List<ContractFormOption> reviewTypes = take(
    const <String>['reviewTypeList', 'reviewTypes', 'typeOfReviewList'],
    idKeys: const <String>['review_type', 'type_of_review', 'id', 'name'],
    labelKeys: const <String>[
      'review_type',
      'type_of_review',
      'name',
      'label',
    ],
  );
  final List<ContractFormOption> bgTypes = take(
    const <String>['bgTypeList', 'bankGuaranteeTypes', 'bgTypes'],
    idKeys: const <String>['bg_type', 'bank_guarantee_type', 'id', 'name'],
    labelKeys: const <String>[
      'bg_type',
      'bank_guarantee_type',
      'name',
      'label',
    ],
  );
  final List<ContractFormOption> insuranceTypes = take(
    const <String>['insuranceTypeList', 'insuranceTypes'],
    idKeys: const <String>['insurance_type', 'id', 'name'],
    labelKeys: const <String>['insurance_type', 'name', 'label'],
  );
  final List<ContractFormOption> fileTypes = take(
    const <String>['fileTypeList', 'documentTypes', 'fileTypes'],
    idKeys: const <String>[
      'file_type',
      'structure_file_type',
      'id',
      'name',
    ],
    labelKeys: const <String>['file_type', 'name', 'label'],
  );

  final Map<String, List<ContractFormOption>> byDept =
      <String, List<ContractFormOption>>{};
  for (final ContractFormOption person in responsiblePeople) {
    final String dept = person.meta.trim().isEmpty ? '_' : person.meta.trim();
    byDept.putIfAbsent(dept, () => <ContractFormOption>[]).add(person);
  }

  return ContractFormMaster(
    projects: projects.isNotEmpty
        ? projects
        : _projectFallbackFromFlat(root),
    departments: departments,
    hods: hods,
    dyHods: dyHods,
    units: units.isNotEmpty ? units : contractCostUnitOptions,
    responsiblePeople: responsiblePeople,
    contractors: contractors,
    contractStatuses: contractStatuses,
    contractTypes: contractTypes,
    workStatuses: workStatuses,
    banks: banks,
    reviewTypes: reviewTypes,
    bgTypes: bgTypes,
    insuranceTypes: insuranceTypes,
    fileTypes: fileTypes,
    executivesByDepartment: byDept,
  );
}

String parseContractMutationMessage(
  dynamic data, {
  required String fallback,
}) {
  if (data is String && data.trim().isNotEmpty) {
    return data.trim();
  }
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    for (final String key in const <String>[
      'message',
      'msg',
      'statusMessage',
      'error',
      'errorMessage',
    ]) {
      final String text = _display(map[key]);
      if (text.isNotEmpty) {
        return text;
      }
    }
  }
  return fallback;
}

bool isContractMutationSuccess(dynamic data) {
  if (data == null) {
    return true;
  }
  if (data is String) {
    final String lower = data.toLowerCase();
    if (lower.contains('fail') || lower.contains('error')) {
      return false;
    }
    return true;
  }
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    final Object? success = map['success'] ?? map['status'];
    if (success is bool) {
      return success;
    }
    if (success is String) {
      final String lower = success.toLowerCase();
      if (lower == 'false' || lower == 'error' || lower == 'fail') {
        return false;
      }
      if (lower == 'true' || lower == 'success' || lower == 'ok') {
        return true;
      }
    }
    final String message = parseContractMutationMessage(data, fallback: '');
    final String lower = message.toLowerCase();
    if (lower.contains('fail') ||
        lower.contains('error') ||
        lower.contains('session expired')) {
      return false;
    }
  }
  return true;
}

List<ContractFormOption> _projectFallbackFromFlat(Map<String, dynamic> root) {
  return _formOptions(
    root['aaData'] ?? root['data'],
    idKeys: const <String>['project_id_fk', 'project_id', 'id'],
    labelKeys: const <String>['project_name', 'work_name', 'name'],
  );
}

List<ContractFormOption> _formOptions(
  dynamic data, {
  required List<String> idKeys,
  required List<String> labelKeys,
  List<String> metaKeys = const <String>[],
}) {
  final Map<String, ContractFormOption> unique =
      <String, ContractFormOption>{};
  for (final Map<String, dynamic> json in _records(data)) {
    final String id = _first(json, idKeys);
    if (id.isEmpty) {
      continue;
    }
    String label = _first(json, labelKeys);
    if (label.isEmpty) {
      label = id;
    } else if (idKeys.contains('project_id_fk') ||
        idKeys.contains('project_id')) {
      if (label != id && !label.startsWith('$id ')) {
        label = '$id - $label';
      }
    }
    unique.putIfAbsent(
      id,
      () => ContractFormOption(
        id: id,
        label: label,
        meta: _first(json, metaKeys),
      ),
    );
  }
  final List<ContractFormOption> values = unique.values.toList()
    ..sort(
      (ContractFormOption a, ContractFormOption b) =>
          a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );
  return values;
}

List<ContractOption> _options(
  dynamic data,
  ContractOption? Function(Map<String, dynamic> json) read,
) {
  final Map<String, ContractOption> unique = <String, ContractOption>{};
  for (final Map<String, dynamic> json in _records(data)) {
    final ContractOption? option = read(json);
    if (option == null) {
      continue;
    }
    unique.putIfAbsent(option.value, () => option);
  }
  final List<ContractOption> values = unique.values.toList()
    ..sort(
      (ContractOption a, ContractOption b) =>
          a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );
  return values;
}

Iterable<Map<String, dynamic>> _records(dynamic data) sync* {
  if (data is List) {
    for (final dynamic item in data) {
      if (item is Map) {
        yield Map<String, dynamic>.from(item);
      }
    }
    return;
  }
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    final Object? nested =
        map['aaData'] ?? map['data'] ?? map['result'] ?? map['payload'];
    if (nested != null && nested != data) {
      yield* _records(nested);
      if (nested is List ||
          (nested is Map &&
              (nested.containsKey('aaData') || nested.containsKey('data')))) {
        return;
      }
    }
    yield map;
  }
}

Map<String, dynamic> _dataTablesMap(dynamic data) {
  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }
  if (data is List) {
    return <String, dynamic>{
      'aaData': data,
      'iTotalRecords': data.length,
      'iTotalDisplayRecords': data.length,
    };
  }
  return <String, dynamic>{};
}

Iterable<Map<String, dynamic>> _aaData(Map<String, dynamic> payload) sync* {
  final Object? raw = payload['aaData'] ?? payload['data'];
  if (raw is List) {
    for (final dynamic item in raw) {
      if (item is Map) {
        yield Map<String, dynamic>.from(item);
      }
    }
  }
}

int _total(Map<String, dynamic> payload, int fallback) {
  for (final String key in const <String>[
    'iTotalDisplayRecords',
    'iTotalRecords',
    'total',
    'recordsTotal',
  ]) {
    final Object? value = payload[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      final int? parsed = int.tryParse(value.trim());
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return fallback;
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
        if (nestedMap.keys.any(
          (String k) =>
              k.toLowerCase().contains('list') ||
              k.toLowerCase().contains('status') ||
              k.toLowerCase().contains('type'),
        )) {
          return nestedMap;
        }
      }
    }
    return map;
  }
  return <String, dynamic>{};
}

Object? _findList(Map<String, dynamic> root, List<String> keys) {
  for (final String key in keys) {
    if (root.containsKey(key) && root[key] != null) {
      return root[key];
    }
  }
  for (final String key in keys) {
    final String lower = key.toLowerCase();
    for (final MapEntry<String, dynamic> entry in root.entries) {
      if (entry.key.toLowerCase() == lower && entry.value != null) {
        return entry.value;
      }
    }
  }
  return null;
}

String _formatDate(Object? raw) {
  final String text = _display(raw);
  if (text.isEmpty) {
    return '';
  }
  final DateTime? parsed = parseContractFormDate(text);
  if (parsed == null) {
    return text;
  }
  return formatContractDisplayDate(parsed).replaceAll('/', '-');
}

String _first(Map<String, dynamic> json, List<String> keys) {
  for (final String key in keys) {
    final String? value = _text(json[key]);
    if (value != null) {
      return value;
    }
  }
  return '';
}

String _display(Object? value) => _text(value) ?? '';

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
