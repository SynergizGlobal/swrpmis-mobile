class IssueFormOption {
  const IssueFormOption({
    required this.id,
    required this.label,
    this.projectId = '',
    this.contractId = '',
    this.categoryId = '',
    this.structureId = '',
    this.departmentId = '',
  });

  final String id;
  final String label;
  final String projectId;
  final String contractId;
  final String categoryId;
  final String structureId;
  final String departmentId;
}

class IssueFormMaster {
  const IssueFormMaster({
    this.projects = const <IssueFormOption>[],
    this.contracts = const <IssueFormOption>[],
    this.statuses = const <IssueFormOption>[],
    this.priorities = const <IssueFormOption>[],
    this.categories = const <IssueFormOption>[],
    this.titles = const <IssueFormOption>[],
    this.departments = const <IssueFormOption>[],
    this.railways = const <IssueFormOption>[],
    this.reportedBy = const <IssueFormOption>[],
    this.responsiblePersons = const <IssueFormOption>[],
    this.escalatedTo = const <IssueFormOption>[],
    this.otherOrganizations = const <IssueFormOption>[],
    this.fileTypes = const <IssueFormOption>[],
    this.structures = const <IssueFormOption>[],
    this.components = const <IssueFormOption>[],
    this.hods = const <IssueFormOption>[],
    this.extras = const <String, List<IssueFormOption>>{},
  });

  static const IssueFormMaster empty = IssueFormMaster();

  final List<IssueFormOption> projects;
  final List<IssueFormOption> contracts;
  final List<IssueFormOption> statuses;
  final List<IssueFormOption> priorities;
  final List<IssueFormOption> categories;
  final List<IssueFormOption> titles;
  final List<IssueFormOption> departments;
  final List<IssueFormOption> railways;
  final List<IssueFormOption> reportedBy;
  final List<IssueFormOption> responsiblePersons;
  final List<IssueFormOption> escalatedTo;
  final List<IssueFormOption> otherOrganizations;
  final List<IssueFormOption> fileTypes;
  final List<IssueFormOption> structures;
  final List<IssueFormOption> components;
  final List<IssueFormOption> hods;

  /// Catalog lists from the payload that are not one of the named fields above.
  final Map<String, List<IssueFormOption>> extras;
}

class IssueDetail {
  const IssueDetail({
    this.issueId = '',
    this.projectIdFk = '',
    this.contractIdFk = '',
    this.title = '',
    this.description = '',
    this.date = '',
    this.location = '',
    this.priorityFk = '',
    this.categoryFk = '',
    this.statusFk = '',
    this.reportedBy = '',
    this.reportedByUserId = '',
    this.responsiblePerson = '',
    this.responsiblePersonUserId = '',
    this.departmentFk = '',
    this.zonalRailwayFk = '',
    this.otherOrganization = '',
    this.otherOrgResponsiblePersonName = '',
    this.otherOrgResponsiblePersonDesignation = '',
    this.structure = '',
    this.component = '',
    this.correctiveMeasure = '',
    this.escalatedTo = '',
    this.escalatedToUserId = '',
    this.remarks = '',
    this.hodUserId = '',
    this.additional = const <String, String>{},
  });

  static const IssueDetail empty = IssueDetail();

  final String issueId;
  final String projectIdFk;
  final String contractIdFk;
  final String title;
  final String description;
  final String date;
  final String location;
  final String priorityFk;
  final String categoryFk;
  final String statusFk;
  final String reportedBy;
  final String reportedByUserId;
  final String responsiblePerson;
  final String responsiblePersonUserId;
  final String departmentFk;
  final String zonalRailwayFk;
  final String otherOrganization;
  final String otherOrgResponsiblePersonName;
  final String otherOrgResponsiblePersonDesignation;
  final String structure;
  final String component;
  final String correctiveMeasure;
  final String escalatedTo;
  final String escalatedToUserId;
  final String remarks;
  final String hodUserId;

  /// Other scalar values from the detail payload, so unknown keys are kept.
  final Map<String, String> additional;
}

IssueFormMaster parseIssueFormMaster(dynamic data) {
  final Map<String, dynamic> root = _masterMap(data);
  final Set<String> used = <String>{};

  List<IssueFormOption> take(
    List<String> keys,
    IssueFormOption? Function(dynamic row) read,
  ) {
    final String? found = _findKey(root, keys);
    if (found != null) {
      used.add(found);
    }
    return _readList(found == null ? const <dynamic>[] : root[found], read);
  }

  final List<IssueFormOption> projects = take(
    const <String>['projectsList', 'projectList'],
    (dynamic row) => _record(
      row,
      idKeys: const <String>['project_id_fk', 'project_id', 'projectId'],
      labelKeys: const <String>['project_name', 'projectName', 'name'],
    ),
  );
  final List<IssueFormOption> contracts = take(
    const <String>['contractsList', 'contractList'],
    (dynamic row) => _record(
      row,
      idKeys: const <String>['contract_id_fk', 'contract_id'],
      labelKeys: const <String>[
        'contract_short_name',
        'contract_name',
        'contract_code',
      ],
    ),
  );
  final List<IssueFormOption> statuses = take(
    const <String>['issuesStatusList', 'statusList'],
    (dynamic row) => _record(
      row,
      idKeys: const <String>['status_fk', 'status', 'id'],
      labelKeys: const <String>['status', 'status_name'],
    ),
  );
  final List<IssueFormOption> priorities = take(
    const <String>['issuesPriorityList', 'priorityList'],
    (dynamic row) => _record(
      row,
      idKeys: const <String>['priority_fk', 'priority', 'id'],
      labelKeys: const <String>['priority', 'priority_name'],
    ),
  );
  final List<IssueFormOption> categories = take(
    const <String>['issuesCategoryList', 'categoryList'],
    (dynamic row) => _record(
      row,
      idKeys: const <String>['category_fk', 'category', 'id'],
      labelKeys: const <String>['category', 'category_name'],
    ),
  );
  final List<IssueFormOption> titles = take(
    const <String>['issueTitlesList', 'titlesList', 'titleList'],
    (dynamic row) => _record(
      row,
      idKeys: const <String>[
        'issue_title_fk',
        'title_fk',
        'id',
        'short_description',
      ],
      labelKeys: const <String>['short_description', 'title'],
    ),
  );
  final List<IssueFormOption> departments = take(
    const <String>['departmentList', 'departmentsList'],
    (dynamic row) => _record(
      row,
      idKeys: const <String>['department_fk', 'department_id'],
      labelKeys: const <String>['department_name', 'department'],
    ),
  );
  final List<IssueFormOption> railways = take(
    const <String>['railwayList', 'railways'],
    (dynamic row) => _record(
      row,
      idKeys: const <String>['railway_id', 'railway_id_fk', 'zonal_railway_fk'],
      labelKeys: const <String>['railway_name', 'railway'],
    ),
  );
  final List<IssueFormOption> reportedBy = take(
    const <String>['reportedByList', 'reported_by_list'],
    (dynamic row) => _record(
      row,
      idKeys: const <String>['reported_by_user_id', 'reported_by'],
      labelKeys: const <String>[
        'user_name',
        'reported_by',
        'reported_by_designation',
      ],
      joinLabels: true,
    ),
  );
  final List<IssueFormOption> responsiblePersons = take(
    const <String>['responsiblePersonList', 'responsible_person_list'],
    (dynamic row) => _record(
      row,
      idKeys: const <String>[
        'responsible_person_user_id',
        'responsible_person',
      ],
      labelKeys: const <String>[
        'responsible_person',
        'responsible_person_designation',
      ],
      joinLabels: true,
    ),
  );
  final List<IssueFormOption> escalatedTo = take(
    const <String>['escalatedToList', 'escalated_to_list'],
    (dynamic row) => _record(
      row,
      idKeys: const <String>['escalated_to_user_id', 'user_name'],
      labelKeys: const <String>['user_name', 'escalated_to_designation'],
      joinLabels: true,
    ),
  );
  final List<IssueFormOption> otherOrganizations = take(
    const <String>['otherOrganizations', 'other_organizations'],
    (dynamic row) => _record(
      row,
      idKeys: const <String>['other_organization_fk', 'other_organization'],
      labelKeys: const <String>['other_organization', 'organization_name'],
    ),
  );
  final List<IssueFormOption> fileTypes = take(
    const <String>['issueFileTypes', 'issue_file_types'],
    (dynamic row) => _record(
      row,
      idKeys: const <String>['issue_file_type_fk', 'issue_file_type'],
      labelKeys: const <String>['issue_file_type'],
    ),
  );
  final List<IssueFormOption> structures = take(
    const <String>['structures', 'structureList', 'structure_list'],
    (dynamic row) => _record(
      row,
      idKeys: const <String>['structure_id', 'structure_fk', 'structure'],
      labelKeys: const <String>['structure', 'structure_name'],
    ),
  );
  List<IssueFormOption> components = take(
    const <String>['components', 'componentList', 'component_list'],
    (dynamic row) => _record(
      row,
      idKeys: const <String>['component_id', 'component_fk', 'component'],
      labelKeys: const <String>['component', 'component_name'],
    ),
  );
  List<IssueFormOption> hods = take(
    const <String>['hodList', 'hods', 'issuesHodList', 'hod_list'],
    (dynamic row) => _record(
      row,
      idKeys: const <String>['hod_user_id_fk', 'hod', 'user_id'],
      labelKeys: const <String>['user_name', 'hod_name', 'designation'],
      joinLabels: true,
    ),
  );

  final Map<String, List<IssueFormOption>> extras =
      <String, List<IssueFormOption>>{};
  for (final MapEntry<String, dynamic> entry in root.entries) {
    if (used.contains(entry.key) || entry.value is! List) {
      continue;
    }
    final List<IssueFormOption> options = _readList(
      entry.value,
      _genericOption,
    );
    if (options.isEmpty) {
      continue;
    }
    extras[entry.key] = options;
  }
  if (hods.isEmpty) {
    hods = _pull(extras, const <String>['hod']);
  }
  if (components.isEmpty) {
    components = _pull(extras, const <String>['component']);
  }

  return IssueFormMaster(
    projects: projects,
    contracts: contracts,
    statuses: statuses,
    priorities: priorities,
    categories: categories,
    titles: titles,
    departments: departments,
    railways: railways,
    reportedBy: reportedBy,
    responsiblePersons: responsiblePersons,
    escalatedTo: escalatedTo,
    otherOrganizations: otherOrganizations,
    fileTypes: fileTypes,
    structures: structures,
    components: components,
    hods: hods,
    extras: Map<String, List<IssueFormOption>>.unmodifiable(extras),
  );
}

IssueDetail parseIssueDetail(dynamic data) {
  final Map<String, dynamic>? json = _issueMap(data);
  if (json == null) {
    return IssueDetail.empty;
  }
  const Set<String> known = <String>{
    'issue_id',
    'project_id_fk',
    'project_id',
    'contract_id_fk',
    'title',
    'short_description',
    'description',
    'date',
    'location',
    'priority_fk',
    'priority',
    'category_fk',
    'category',
    'status_fk',
    'status',
    'reported_by',
    'reported_by_user_id',
    'responsible_person',
    'responsible_person_user_id',
    'department_fk',
    'zonal_railway_fk',
    'railway_id',
    'other_organization',
    'other_org_resposible_person_name',
    'other_org_resposible_person_designation',
    'structure',
    'component',
    'corrective_measure',
    'escalated_to',
    'escalated_to_user_id',
    'remarks',
    'hod_user_id_fk',
    'hod',
  };
  final Map<String, String> additional = <String, String>{};
  json.forEach((String key, dynamic value) {
    if (known.contains(key) || value is Map || value is List) {
      return;
    }
    final String text = _scalar(value);
    if (text.isEmpty) {
      return;
    }
    additional[key] = text;
  });
  return IssueDetail(
    issueId: _pick(json, const <String>['issue_id']),
    projectIdFk: _pick(json, const <String>['project_id_fk', 'project_id']),
    contractIdFk: _pick(json, const <String>['contract_id_fk']),
    title: _pick(json, const <String>['title', 'short_description']),
    description: _pick(json, const <String>['description']),
    date: _pick(json, const <String>['date']),
    location: _pick(json, const <String>['location']),
    priorityFk: _pick(json, const <String>['priority_fk', 'priority']),
    categoryFk: _pick(json, const <String>['category_fk', 'category']),
    statusFk: _pick(json, const <String>['status_fk', 'status']),
    reportedBy: _pick(json, const <String>['reported_by']),
    reportedByUserId: _pick(json, const <String>['reported_by_user_id']),
    responsiblePerson: _pick(json, const <String>['responsible_person']),
    responsiblePersonUserId: _pick(json, const <String>[
      'responsible_person_user_id',
    ]),
    departmentFk: _pick(json, const <String>['department_fk']),
    zonalRailwayFk: _pick(json, const <String>[
      'zonal_railway_fk',
      'railway_id',
    ]),
    otherOrganization: _pick(json, const <String>['other_organization']),
    otherOrgResponsiblePersonName: _pick(json, const <String>[
      'other_org_resposible_person_name',
    ]),
    otherOrgResponsiblePersonDesignation: _pick(json, const <String>[
      'other_org_resposible_person_designation',
    ]),
    structure: _pick(json, const <String>['structure']),
    component: _pick(json, const <String>['component']),
    correctiveMeasure: _pick(json, const <String>['corrective_measure']),
    escalatedTo: _pick(json, const <String>['escalated_to']),
    escalatedToUserId: _pick(json, const <String>['escalated_to_user_id']),
    remarks: _pick(json, const <String>['remarks']),
    hodUserId: _pick(json, const <String>['hod_user_id_fk', 'hod']),
    additional: Map<String, String>.unmodifiable(additional),
  );
}

List<IssueFormOption> issueContractsForProject(
  List<IssueFormOption> contracts,
  String projectId,
) {
  if (projectId.isEmpty) {
    return const <IssueFormOption>[];
  }
  return contracts
      .where((IssueFormOption option) => option.projectId == projectId)
      .toList(growable: false);
}

List<IssueFormOption> issueStructuresForContract(
  List<IssueFormOption> structures,
  String contractId,
) {
  if (contractId.isEmpty) {
    return const <IssueFormOption>[];
  }
  final bool linked = structures.any(
    (IssueFormOption option) => option.contractId.isNotEmpty,
  );
  if (!linked) {
    return structures;
  }
  return structures
      .where((IssueFormOption option) => option.contractId == contractId)
      .toList(growable: false);
}

List<IssueFormOption> issueTitlesForCategory(
  List<IssueFormOption> titles, {
  required String categoryId,
  String categoryLabel = '',
}) {
  final bool linked = titles.any(
    (IssueFormOption option) => option.categoryId.isNotEmpty,
  );
  if (!linked) {
    return titles;
  }
  if (categoryId.isEmpty && categoryLabel.isEmpty) {
    return const <IssueFormOption>[];
  }
  return titles
      .where(
        (IssueFormOption option) =>
            option.categoryId == categoryId ||
            (categoryLabel.isNotEmpty && option.categoryId == categoryLabel),
      )
      .toList(growable: false);
}

List<IssueFormOption> issuePeopleForContract(
  List<IssueFormOption> people,
  String contractId,
) {
  final bool linked = people.any(
    (IssueFormOption option) => option.contractId.isNotEmpty,
  );
  if (!linked) {
    return people;
  }
  if (contractId.isEmpty) {
    return people
        .where((IssueFormOption option) => option.contractId.isEmpty)
        .toList(growable: false);
  }
  return people
      .where(
        (IssueFormOption option) =>
            option.contractId.isEmpty || option.contractId == contractId,
      )
      .toList(growable: false);
}

List<IssueFormOption> issueComponentsFor(
  List<IssueFormOption> components, {
  required String contractId,
  required String structureId,
}) {
  if (components.isEmpty) {
    return const <IssueFormOption>[];
  }
  final bool byStructure = components.any(
    (IssueFormOption option) => option.structureId.isNotEmpty,
  );
  final bool byContract = components.any(
    (IssueFormOption option) => option.contractId.isNotEmpty,
  );
  if (byStructure && structureId.isEmpty) {
    return const <IssueFormOption>[];
  }
  if (!byStructure && byContract && contractId.isEmpty) {
    return const <IssueFormOption>[];
  }
  if (!byStructure && !byContract) {
    return contractId.isEmpty ? const <IssueFormOption>[] : components;
  }
  return components
      .where((IssueFormOption option) {
        if (byStructure &&
            option.structureId.isNotEmpty &&
            option.structureId != structureId) {
          return false;
        }
        if (byContract &&
            option.contractId.isNotEmpty &&
            option.contractId != contractId) {
          return false;
        }
        return true;
      })
      .toList(growable: false);
}

String _scalar(Object? value) {
  if (value == null) {
    return '';
  }
  if (value is double) {
    if (value.isNaN || value.isInfinite) {
      return '';
    }
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
  }
  final String text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return '';
  }
  return text;
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

Map<String, dynamic>? _issueMap(dynamic data) {
  if (data is List) {
    Map<String, dynamic>? first;
    for (final dynamic item in data) {
      if (item is! Map) {
        continue;
      }
      final Map<String, dynamic> map = _asMap(item);
      first ??= map;
      if (_scalar(map['issue_id']).isNotEmpty) {
        return map;
      }
    }
    return first;
  }
  if (data is! Map) {
    return null;
  }
  final Map<String, dynamic> map = _asMap(data);
  final bool direct =
      map.containsKey('issue_id') ||
      map.containsKey('contract_id_fk') ||
      map.containsKey('title');
  if (direct && !_looksLikeCatalog(map)) {
    return map;
  }
  for (final String key in const <String>[
    'issue',
    'data',
    'model',
    'result',
    'body',
  ]) {
    final dynamic nested = map[key];
    if (nested == null) {
      continue;
    }
    final Map<String, dynamic>? found = _issueMap(nested);
    if (found != null) {
      return found;
    }
  }
  if (direct) {
    return map;
  }
  return null;
}

bool _looksLikeCatalog(Map<String, dynamic> map) {
  const Set<String> hints = <String>{
    'projectsList',
    'contractsList',
    'issuesStatusList',
    'issuesPriorityList',
    'issuesCategoryList',
    'issueTitlesList',
  };
  for (final String key in hints) {
    if (map.containsKey(key)) {
      return true;
    }
  }
  return false;
}

String? _findKey(Map<String, dynamic> map, List<String> keys) {
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

List<IssueFormOption> _readList(
  dynamic data,
  IssueFormOption? Function(dynamic row) read,
) {
  if (data is! List) {
    return const <IssueFormOption>[];
  }
  final Map<String, IssueFormOption> unique = <String, IssueFormOption>{};
  for (final dynamic row in data) {
    final IssueFormOption? option = read(row);
    if (option == null) {
      continue;
    }
    unique.putIfAbsent(option.id, () => option);
  }
  return unique.values.toList(growable: false);
}

IssueFormOption? _genericOption(dynamic row) {
  if (row is! Map) {
    return _record(row, idKeys: const <String>[], labelKeys: const <String>[]);
  }
  final Map<String, dynamic> json = _asMap(row);
  final List<String> idKeys = <String>[];
  final List<String> labelKeys = <String>[];
  for (final String key in json.keys) {
    if (key == 'id' || key.endsWith('_fk') || key.endsWith('_id')) {
      idKeys.add(key);
    } else {
      labelKeys.add(key);
    }
  }
  return _record(row, idKeys: idKeys, labelKeys: labelKeys);
}

IssueFormOption? _record(
  dynamic row, {
  required List<String> idKeys,
  required List<String> labelKeys,
  bool joinLabels = false,
}) {
  if (row is Map) {
    final Map<String, dynamic> json = _asMap(row);
    String id = _pick(json, idKeys);
    String label = joinLabels ? _join(json, labelKeys) : _pick(json, labelKeys);
    if (id.isEmpty) {
      id = label;
    }
    if (label.isEmpty) {
      label = id;
    }
    if (id.isEmpty) {
      return null;
    }
    return IssueFormOption(
      id: id,
      label: label,
      projectId: _pick(json, const <String>['project_id_fk', 'project_id']),
      contractId: _pick(json, const <String>['contract_id_fk', 'contract_id']),
      categoryId: _pick(json, const <String>[
        'category_fk',
        'category_id',
        'category',
      ]),
      structureId: _pick(json, const <String>[
        'structure_fk',
        'structure_id',
        'structure',
      ]),
      departmentId: _pick(json, const <String>['department_fk']),
    );
  }
  final String id = _scalar(row);
  if (id.isEmpty) {
    return null;
  }
  return IssueFormOption(id: id, label: id);
}

List<IssueFormOption> _pull(
  Map<String, List<IssueFormOption>> extras,
  List<String> hints,
) {
  String? found;
  for (final String key in extras.keys) {
    final String lower = key.toLowerCase();
    if (hints.any(lower.contains)) {
      found = key;
      break;
    }
  }
  if (found == null) {
    return const <IssueFormOption>[];
  }
  return extras.remove(found) ?? const <IssueFormOption>[];
}

String _join(Map<String, dynamic> json, List<String> keys) {
  final List<String> parts = <String>[];
  for (final String key in keys) {
    final String bit = _pick(json, <String>[key]);
    if (bit.isEmpty || parts.contains(bit)) {
      continue;
    }
    parts.add(bit);
  }
  return parts.join(' — ');
}

String _pick(Map<String, dynamic> json, List<String> keys) {
  for (final String key in keys) {
    final String text = _scalar(json[key]);
    if (text.isNotEmpty) {
      return text;
    }
  }
  return '';
}

Map<String, dynamic> _asMap(dynamic data) {
  final Map<Object?, Object?> source = data as Map<Object?, Object?>;
  return Map<String, dynamic>.fromEntries(
    source.entries.map(
      (MapEntry<Object?, Object?> entry) =>
          MapEntry<String, dynamic>(entry.key.toString(), entry.value),
    ),
  );
}
