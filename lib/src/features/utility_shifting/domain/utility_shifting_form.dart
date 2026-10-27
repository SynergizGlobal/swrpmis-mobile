class UtilityShiftingFormOption {
  const UtilityShiftingFormOption({
    required this.id,
    required this.label,
    this.projectId = '',
    this.extra = '',
  });

  final String id;
  final String label;
  final String projectId;
  final String extra;
}

class UtilityShiftingFormMaster {
  const UtilityShiftingFormMaster({
    this.projects = const <UtilityShiftingFormOption>[],
    this.contracts = const <UtilityShiftingFormOption>[],
    this.utilityTypes = const <UtilityShiftingFormOption>[],
    this.utilityCategories = const <UtilityShiftingFormOption>[],
    this.executionAgencies = const <UtilityShiftingFormOption>[],
    this.requirementStages = const <UtilityShiftingFormOption>[],
    this.units = const <UtilityShiftingFormOption>[],
    this.fileTypes = const <UtilityShiftingFormOption>[],
    this.statuses = const <UtilityShiftingFormOption>[],
    this.hods = const <UtilityShiftingFormOption>[],
    this.impactedContracts = const <UtilityShiftingFormOption>[],
    this.fallbackRequirementStages = const <UtilityShiftingFormOption>[],
    this.fallbackImpactedElements = const <UtilityShiftingFormOption>[],
  });

  static const UtilityShiftingFormMaster empty = UtilityShiftingFormMaster();

  final List<UtilityShiftingFormOption> projects;
  final List<UtilityShiftingFormOption> contracts;
  final List<UtilityShiftingFormOption> utilityTypes;
  final List<UtilityShiftingFormOption> utilityCategories;
  final List<UtilityShiftingFormOption> executionAgencies;
  final List<UtilityShiftingFormOption> requirementStages;
  final List<UtilityShiftingFormOption> units;
  final List<UtilityShiftingFormOption> fileTypes;
  final List<UtilityShiftingFormOption> statuses;
  final List<UtilityShiftingFormOption> hods;
  final List<UtilityShiftingFormOption> impactedContracts;
  final List<UtilityShiftingFormOption> fallbackRequirementStages;
  final List<UtilityShiftingFormOption> fallbackImpactedElements;
}

class UtilityShiftingAttachmentDraft {
  const UtilityShiftingAttachmentDraft({
    required this.fileType,
    required this.name,
    required this.fileName,
    required this.path,
  });

  final String fileType;
  final String name;
  final String fileName;
  final String path;
}

class UtilityShiftingProgressDraft {
  const UtilityShiftingProgressDraft({
    required this.date,
    required this.progressOfWork,
  });

  final DateTime date;
  final String progressOfWork;
}

class UtilityShiftingAddPayload {
  const UtilityShiftingAddPayload({
    required this.fields,
    required this.files,
  });

  final Map<String, String> fields;
  final List<({String path, String fileName})> files;
}

class UtilityShiftingDetail {
  const UtilityShiftingDetail({
    this.id = '',
    this.utilityShiftingId = '',
    this.utilityDescription = '',
    this.locationName = '',
    this.custodian = '',
    this.identification = '',
    this.referenceNumber = '',
    this.executedBy = '',
    this.chainage = '',
    this.latitude = '',
    this.longitude = '',
    this.affectedStructures = '',
    this.plannedCompletionDate = '',
    this.scope = '',
    this.completed = '',
    this.startDate = '',
    this.shiftingCompletionDate = '',
    this.remarks = '',
    this.projectIdFk = '',
    this.executionAgencyFk = '',
    this.hodUserIdFk = '',
    this.utilityTypeFk = '',
    this.utilityCategoryFk = '',
    this.impactedContractIdFk = '',
    this.requirementStageFk = '',
    this.unitFk = '',
    this.shiftingStatusFk = '',
    this.impactedElement = '',
    this.workCode = '',
    this.progress = const <UtilityShiftingProgressDraft>[],
  });

  static const UtilityShiftingDetail empty = UtilityShiftingDetail();

  final String id;
  final String utilityShiftingId;
  final String utilityDescription;
  final String locationName;
  final String custodian;
  final String identification;
  final String referenceNumber;
  final String executedBy;
  final String chainage;
  final String latitude;
  final String longitude;
  final String affectedStructures;
  final String plannedCompletionDate;
  final String scope;
  final String completed;
  final String startDate;
  final String shiftingCompletionDate;
  final String remarks;
  final String projectIdFk;
  final String executionAgencyFk;
  final String hodUserIdFk;
  final String utilityTypeFk;
  final String utilityCategoryFk;
  final String impactedContractIdFk;
  final String requirementStageFk;
  final String unitFk;
  final String shiftingStatusFk;
  final String impactedElement;
  final String workCode;
  final List<UtilityShiftingProgressDraft> progress;

  bool get isEmpty =>
      id.isEmpty && utilityShiftingId.isEmpty && utilityDescription.isEmpty;
}

UtilityShiftingFormMaster parseUtilityShiftingFormMaster(dynamic data) {
  final Map<String, dynamic> root = _masterMap(data);

  List<UtilityShiftingFormOption> take(
    List<String> keys,
    UtilityShiftingFormOption? Function(dynamic row) read,
  ) {
    final String? found = _findListKey(root, keys);
    return _readOptions(found == null ? const <dynamic>[] : root[found], read);
  }

  final List<UtilityShiftingFormOption> projects = take(
    const <String>['projectsList', 'projectList'],
    (dynamic row) => _option(
      row,
      idKeys: const <String>['project_id_fk', 'project_id', 'projectId'],
      labelKeys: const <String>['project_name', 'projectName', 'name'],
      projectIdKeys: const <String>['project_id_fk', 'project_id'],
      labelPrefixWithId: true,
    ),
  );
  final List<UtilityShiftingFormOption> contracts = take(
    const <String>['contractsList', 'contractList'],
    (dynamic row) => _option(
      row,
      idKeys: const <String>['contract_id_fk', 'contract_id', 'contractId'],
      labelKeys: const <String>[
        'contract_short_name',
        'contract_name',
        'contractName',
        'name',
      ],
      projectIdKeys: const <String>['project_id_fk', 'project_id'],
      labelPrefixWithId: true,
    ),
  );
  final List<UtilityShiftingFormOption> utilityTypes = take(
    const <String>['utilityTypeList', 'utilityTypesList'],
    (dynamic row) => _option(
      row,
      idKeys: const <String>['utility_type_fk', 'utility_type'],
      labelKeys: const <String>['utility_type_fk', 'utility_type', 'name'],
    ),
  );
  final List<UtilityShiftingFormOption> utilityCategories = take(
    const <String>['utilityCategoryList', 'utilityCategoriesList'],
    (dynamic row) => _option(
      row,
      idKeys: const <String>['utility_category_fk', 'utility_category'],
      labelKeys: const <String>[
        'utility_category_fk',
        'utility_category',
        'name',
      ],
    ),
  );
  final List<UtilityShiftingFormOption> executionAgencies = take(
    const <String>['utilityExecutionAgencyList', 'executionAgencyList'],
    (dynamic row) => _option(
      row,
      idKeys: const <String>['execution_agency_fk', 'execution_agency'],
      labelKeys: const <String>[
        'execution_agency_fk',
        'execution_agency',
        'name',
      ],
    ),
  );
  final List<UtilityShiftingFormOption> requirementStages = take(
    const <String>['requirementStageList'],
    (dynamic row) => _option(
      row,
      idKeys: const <String>['requirement_stage_fk', 'requirement_stage'],
      labelKeys: const <String>[
        'requirement_stage_fk',
        'requirement_stage',
        'name',
      ],
    ),
  );
  final List<UtilityShiftingFormOption> units = take(
    const <String>['unitList', 'unitsList'],
    (dynamic row) => _option(
      row,
      idKeys: const <String>['unit_fk', 'unit'],
      labelKeys: const <String>['unit_fk', 'unit', 'name'],
    ),
  );
  final List<UtilityShiftingFormOption> fileTypes = take(
    const <String>[
      'utilityshiftingfiletypeList',
      'utilityShiftingFileTypeList',
      'fileTypeList',
    ],
    (dynamic row) => _option(
      row,
      idKeys: const <String>[
        'utility_shifting_file_type',
        'file_type',
        'fileType',
      ],
      labelKeys: const <String>[
        'utility_shifting_file_type',
        'file_type',
        'fileType',
        'name',
      ],
    ),
  );
  final List<UtilityShiftingFormOption> statuses = take(
    const <String>['statusList', 'statusesList'],
    (dynamic row) => _option(
      row,
      idKeys: const <String>['shifting_status_fk', 'status_fk', 'status'],
      labelKeys: const <String>[
        'shifting_status_fk',
        'status_fk',
        'status',
        'name',
      ],
    ),
  );
  final List<UtilityShiftingFormOption> hods = take(
    const <String>['utilityHODList', 'hodList', 'utilityHodList'],
    (dynamic row) {
      if (row is! Map) {
        return _option(
          row,
          idKeys: const <String>['hod_user_id_fk', 'user_id'],
          labelKeys: const <String>['user_name', 'name'],
        );
      }
      final Map<String, dynamic> json = _asMap(row);
      final String id = _pick(json, const <String>[
        'hod_user_id_fk',
        'user_id',
        'userId',
      ]);
      final String name = _pick(json, const <String>['user_name', 'name']);
      final String designation = _pick(json, const <String>['designation']);
      final String label = <String>[
        if (name.isNotEmpty) name,
        if (designation.isNotEmpty) designation,
      ].join(' - ');
      if (id.isEmpty && label.isEmpty) {
        return null;
      }
      return UtilityShiftingFormOption(
        id: id.isEmpty ? label : id,
        label: label.isEmpty ? id : label,
      );
    },
  );
  final List<UtilityShiftingFormOption> impactedContracts = take(
    const <String>['impactedContractsList', 'impactedContractList'],
    (dynamic row) => _option(
      row,
      idKeys: const <String>['contract_id_fk', 'contract_id', 'contractId'],
      labelKeys: const <String>[
        'contract_short_name',
        'contract_name',
        'contractName',
        'name',
      ],
      projectIdKeys: const <String>['project_id_fk', 'project_id'],
      labelPrefixWithId: true,
    ),
  );
  final List<UtilityShiftingFormOption> fallbackRequirementStages = take(
    const <String>['reqStageList', 'requirementStageFallbackList'],
    (dynamic row) => _option(
      row,
      idKeys: const <String>['requirement_stage_fk', 'requirement_stage'],
      labelKeys: const <String>[
        'requirement_stage_fk',
        'requirement_stage',
        'name',
      ],
    ),
  );
  final List<UtilityShiftingFormOption> fallbackImpactedElements = take(
    const <String>['impactedElementList', 'impactedElementsList'],
    (dynamic row) => _option(
      row,
      idKeys: const <String>['impacted_element', 'impactedElement'],
      labelKeys: const <String>['impacted_element', 'impactedElement', 'name'],
    ),
  );

  return UtilityShiftingFormMaster(
    projects: projects,
    contracts: contracts,
    utilityTypes: utilityTypes,
    utilityCategories: utilityCategories,
    executionAgencies: executionAgencies,
    requirementStages: requirementStages,
    units: units,
    fileTypes: fileTypes,
    statuses: statuses,
    hods: hods,
    impactedContracts: impactedContracts,
    fallbackRequirementStages: fallbackRequirementStages,
    fallbackImpactedElements: fallbackImpactedElements,
  );
}

List<UtilityShiftingFormOption> parseUtilityShiftingRequirementStages(
  dynamic data,
) {
  return _parseOptionList(
    data,
    idKeys: const <String>['requirement_stage_fk', 'requirement_stage'],
    labelKeys: const <String>[
      'requirement_stage_fk',
      'requirement_stage',
      'name',
    ],
    listKeys: const <String>[
      'reqStageList',
      'requirementStageList',
      'data',
      'aaData',
    ],
  );
}

List<UtilityShiftingFormOption> parseUtilityShiftingImpactedElements(
  dynamic data,
) {
  return _parseOptionList(
    data,
    idKeys: const <String>['impacted_element', 'impactedElement'],
    labelKeys: const <String>['impacted_element', 'impactedElement', 'name'],
    listKeys: const <String>[
      'impactedElementList',
      'impactedElementsList',
      'data',
      'aaData',
    ],
  );
}

UtilityShiftingDetail parseUtilityShiftingDetail(dynamic data) {
  final Map<String, dynamic> json = _detailMap(data);
  if (json.isEmpty) {
    return UtilityShiftingDetail.empty;
  }
  final String id = _pick(json, const <String>['id']);
  final String utilityShiftingId = _pick(json, const <String>[
    'utility_shifting_id',
    'utility_shifting_id_fk',
  ]);
  return UtilityShiftingDetail(
    id: id.isNotEmpty ? id : utilityShiftingId,
    utilityShiftingId: utilityShiftingId.isNotEmpty ? utilityShiftingId : id,
    utilityDescription: _pick(json, const <String>['utility_description']),
    locationName: _pick(json, const <String>['location_name']),
    custodian: _pick(json, const <String>['custodian']),
    identification: _pick(json, const <String>['identification']),
    referenceNumber: _pick(json, const <String>['reference_number']),
    executedBy: _pick(json, const <String>['executed_by']),
    chainage: _pick(json, const <String>['chainage']),
    latitude: _pick(json, const <String>['latitude']),
    longitude: _pick(json, const <String>['longitude']),
    affectedStructures: _pick(json, const <String>['affected_structures']),
    plannedCompletionDate: _pick(json, const <String>[
      'planned_completion_date',
      'target_date',
    ]),
    scope: _pick(json, const <String>['scope']),
    completed: _pick(json, const <String>['completed']),
    startDate: _pick(json, const <String>['start_date']),
    shiftingCompletionDate: _pick(json, const <String>[
      'shifting_completion_date',
    ]),
    remarks: _pick(json, const <String>['remarks']),
    projectIdFk: _pick(json, const <String>['project_id_fk', 'project_id']),
    executionAgencyFk: _pick(json, const <String>['execution_agency_fk']),
    hodUserIdFk: _pick(json, const <String>['hod_user_id_fk']),
    utilityTypeFk: _pick(json, const <String>['utility_type_fk']),
    utilityCategoryFk: _pick(json, const <String>['utility_category_fk']),
    impactedContractIdFk: _pick(json, const <String>[
      'impacted_contract_id_fk',
    ]),
    requirementStageFk: _pick(json, const <String>['requirement_stage_fk']),
    unitFk: _pick(json, const <String>['unit_fk']),
    shiftingStatusFk: _pick(json, const <String>[
      'shifting_status_fk',
      'status_fk',
    ]),
    impactedElement: _pick(json, const <String>['impacted_element']),
    workCode: _pick(json, const <String>['work_code', 'project_id_fk']),
    progress: _parseProgressDrafts(json),
  );
}

DateTime? parseUtilityShiftingFormDate(String raw) {
  final String text = raw.trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }
  final String datePart = text.contains(' ')
      ? text.split(RegExp(r'\s+')).first
      : text;
  final DateTime? iso = DateTime.tryParse(datePart);
  if (iso != null) {
    return DateTime(iso.year, iso.month, iso.day);
  }
  final List<String> parts = datePart.split(RegExp(r'[/-]'));
  if (parts.length == 3) {
    final int? a = int.tryParse(parts[0]);
    final int? b = int.tryParse(parts[1]);
    final int? c = int.tryParse(parts[2]);
    if (a != null && b != null && c != null) {
      // yyyy-MM-dd vs dd-MM-yyyy
      if (parts[0].length == 4) {
        return DateTime(a, b, c);
      }
      if (parts[2].length == 4) {
        return DateTime(c, b, a);
      }
    }
  }
  return null;
}

String parseUtilityShiftingAddMessage(dynamic data) {
  if (data == true || data == 'true') {
    return 'Utility shifting saved successfully.';
  }
  if (data == false || data == 'false') {
    return 'Unable to save utility shifting.';
  }
  if (data is String) {
    final String text = data.trim();
    if (text.isEmpty || text.toLowerCase() == 'true') {
      return 'Utility shifting saved successfully.';
    }
    if (text.toLowerCase() == 'false') {
      return 'Unable to save utility shifting.';
    }
    return text;
  }
  if (data is Map) {
    final Map<String, dynamic> json = _asMap(data);
    for (final String key in const <String>[
      'success',
      'message',
      'msg',
      'error',
      'status',
    ]) {
      final String value = _scalar(json[key]);
      if (value.isEmpty) {
        continue;
      }
      if (value.toLowerCase() == 'true') {
        return 'Utility shifting saved successfully.';
      }
      return value;
    }
  }
  return 'Utility shifting saved successfully.';
}

bool isUtilityShiftingAddSuccess(dynamic data) {
  if (data == true || data == 'true') {
    return true;
  }
  if (data == false || data == 'false') {
    return false;
  }
  if (data is String) {
    final String text = data.trim().toLowerCase();
    if (text == 'true' || text == 'success' || text.isEmpty) {
      return true;
    }
    if (text == 'false' || text.startsWith('error')) {
      return false;
    }
    return !text.contains('fail') && !text.contains('error');
  }
  if (data is Map) {
    final Map<String, dynamic> json = _asMap(data);
    if (json.containsKey('success')) {
      final dynamic success = json['success'];
      if (success == false || success == 'false') {
        return false;
      }
      if (success == true || success == 'true') {
        return true;
      }
    }
    if (json.containsKey('error')) {
      final String error = _scalar(json['error']);
      if (error.isNotEmpty && error.toLowerCase() != 'null') {
        return false;
      }
    }
    return true;
  }
  return true;
}

List<UtilityShiftingFormOption> utilityShiftingImpactedContractsForProject(
  List<UtilityShiftingFormOption> options,
  String projectId,
) {
  final String id = projectId.trim();
  if (id.isEmpty) {
    return options;
  }
  final bool scoped = options.any(
    (UtilityShiftingFormOption option) => option.projectId.isNotEmpty,
  );
  if (!scoped) {
    return options;
  }
  return options
      .where(
        (UtilityShiftingFormOption option) =>
            option.projectId.isEmpty || option.projectId == id,
      )
      .toList(growable: false);
}

List<UtilityShiftingFormOption> _parseOptionList(
  dynamic data, {
  required List<String> idKeys,
  required List<String> labelKeys,
  required List<String> listKeys,
}) {
  if (data is List) {
    return _readOptions(
      data,
      (dynamic row) => _option(row, idKeys: idKeys, labelKeys: labelKeys),
    );
  }
  if (data is Map) {
    final Map<String, dynamic> map = _asMap(data);
    for (final String key in listKeys) {
      final dynamic nested = map[key];
      if (nested is List) {
        return _readOptions(
          nested,
          (dynamic row) => _option(row, idKeys: idKeys, labelKeys: labelKeys),
        );
      }
    }
    // Cascade APIs sometimes return a single option object.
    final UtilityShiftingFormOption? single = _option(
      map,
      idKeys: idKeys,
      labelKeys: labelKeys,
    );
    if (single != null) {
      return <UtilityShiftingFormOption>[single];
    }
  }
  return const <UtilityShiftingFormOption>[];
}

UtilityShiftingFormOption? _option(
  dynamic row, {
  required List<String> idKeys,
  required List<String> labelKeys,
  List<String> projectIdKeys = const <String>[],
  bool labelPrefixWithId = false,
}) {
  if (row is Map) {
    final Map<String, dynamic> json = _asMap(row);
    String id = _pick(json, idKeys);
    String label = _pick(json, labelKeys);
    if (id.isEmpty) {
      id = label;
    }
    if (label.isEmpty) {
      label = id;
    }
    if (id.isEmpty) {
      return null;
    }
    if (labelPrefixWithId && label != id && !label.startsWith('$id ')) {
      label = '$id - $label';
    }
    return UtilityShiftingFormOption(
      id: id,
      label: label,
      projectId: _pick(json, projectIdKeys),
    );
  }
  final String id = _scalar(row);
  if (id.isEmpty) {
    return null;
  }
  return UtilityShiftingFormOption(id: id, label: id);
}

List<UtilityShiftingFormOption> _readOptions(
  dynamic data,
  UtilityShiftingFormOption? Function(dynamic row) read,
) {
  if (data is! List) {
    return const <UtilityShiftingFormOption>[];
  }
  final Map<String, UtilityShiftingFormOption> unique =
      <String, UtilityShiftingFormOption>{};
  for (final dynamic row in data) {
    final UtilityShiftingFormOption? option = read(row);
    if (option == null) {
      continue;
    }
    unique.putIfAbsent(option.id, () => option);
  }
  return unique.values.toList(growable: false);
}

Map<String, dynamic> _masterMap(dynamic data) {
  if (data is! Map) {
    return const <String, dynamic>{};
  }
  final Map<String, dynamic> root = _asMap(data);
  final Map<String, dynamic> merged = Map<String, dynamic>.from(root);
  for (final String key in const <String>['data', 'model', 'result', 'body']) {
    final dynamic node = root[key];
    if (node is! Map) {
      continue;
    }
    _asMap(node).forEach((String childKey, dynamic value) {
      merged.putIfAbsent(childKey, () => value);
    });
  }
  return merged;
}

Map<String, dynamic> _detailMap(dynamic data) {
  if (data is Map) {
    final Map<String, dynamic> root = _asMap(data);
    for (final String key in const <String>[
      'data',
      'model',
      'result',
      'body',
      'utilityShifting',
      'utility_shifting',
    ]) {
      final dynamic node = root[key];
      if (node is Map) {
        final Map<String, dynamic> nested = _asMap(node);
        if (_pick(nested, const <String>[
              'utility_shifting_id',
              'id',
              'utility_description',
            ])
            .isNotEmpty) {
          return nested;
        }
      }
    }
    if (_pick(root, const <String>[
          'utility_shifting_id',
          'id',
          'utility_description',
        ])
        .isNotEmpty) {
      return root;
    }
    return root;
  }
  if (data is List && data.isNotEmpty) {
    final dynamic first = data.first;
    if (first is Map) {
      return _asMap(first);
    }
  }
  return const <String, dynamic>{};
}

List<UtilityShiftingProgressDraft> _parseProgressDrafts(
  Map<String, dynamic> json,
) {
  final List<UtilityShiftingProgressDraft> fromList = <UtilityShiftingProgressDraft>[];
  for (final String key in const <String>[
    'utilityShiftingProgressDetailsList',
    'progressDetailsList',
    'progress_details',
  ]) {
    final dynamic node = json[key];
    if (node is! List) {
      continue;
    }
    for (final dynamic row in node) {
      if (row is! Map) {
        continue;
      }
      final Map<String, dynamic> item = _asMap(row);
      final DateTime? date = parseUtilityShiftingFormDate(
        _pick(item, const <String>['progress_date', 'progressDate', 'date']),
      );
      final String work = _pick(item, const <String>[
        'progress_of_work',
        'progressOfWork',
        'progress_of_works',
      ]);
      if (date == null || work.isEmpty) {
        continue;
      }
      fromList.add(
        UtilityShiftingProgressDraft(date: date, progressOfWork: work),
      );
    }
    if (fromList.isNotEmpty) {
      return fromList;
    }
  }

  final List<String> dates = _stringList(json['progress_dates']);
  final List<String> works = _stringList(json['progress_of_works']);
  final int count = dates.length > works.length ? dates.length : works.length;
  final List<UtilityShiftingProgressDraft> paired =
      <UtilityShiftingProgressDraft>[];
  for (int i = 0; i < count; i++) {
    final DateTime? date = i < dates.length
        ? parseUtilityShiftingFormDate(dates[i])
        : null;
    final String work = i < works.length ? works[i].trim() : '';
    if (date == null || work.isEmpty) {
      continue;
    }
    paired.add(UtilityShiftingProgressDraft(date: date, progressOfWork: work));
  }
  return paired;
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return <String>[
      for (final dynamic item in value)
        if (_scalar(item).isNotEmpty) _scalar(item),
    ];
  }
  final String text = _scalar(value);
  if (text.isEmpty) {
    return const <String>[];
  }
  return <String>[text];
}

String? _findListKey(Map<String, dynamic> map, List<String> keys) {
  for (final String key in keys) {
    if (map[key] is List) {
      return key;
    }
  }
  final Map<String, String> lower = <String, String>{
    for (final MapEntry<String, dynamic> entry in map.entries)
      entry.key.toLowerCase(): entry.key,
  };
  for (final String key in keys) {
    final String? actual = lower[key.toLowerCase()];
    if (actual != null && map[actual] is List) {
      return actual;
    }
  }
  return null;
}

String _pick(Map<String, dynamic> json, List<String> keys) {
  for (final String key in keys) {
    final String value = _scalar(json[key]);
    if (value.isNotEmpty) {
      return value;
    }
  }
  final Map<String, String> lower = <String, String>{
    for (final MapEntry<String, dynamic> entry in json.entries)
      entry.key.toLowerCase(): entry.key,
  };
  for (final String key in keys) {
    final String? actual = lower[key.toLowerCase()];
    if (actual == null) {
      continue;
    }
    final String value = _scalar(json[actual]);
    if (value.isNotEmpty) {
      return value;
    }
  }
  return '';
}

Map<String, dynamic> _asMap(dynamic data) {
  return <String, dynamic>{
    for (final MapEntry<dynamic, dynamic> entry
        in (data as Map).entries)
      entry.key.toString(): entry.value,
  };
}

String _scalar(dynamic value) {
  if (value == null) {
    return '';
  }
  if (value is String) {
    final String text = value.trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return '';
    }
    return text;
  }
  if (value is num || value is bool) {
    return value.toString();
  }
  return '';
}
