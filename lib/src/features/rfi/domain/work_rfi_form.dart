class WorkRfiOption {
  const WorkRfiOption({required this.id, required this.label});

  final String id;
  final String label;
}

class WorkRfiContractOption {
  const WorkRfiContractOption({
    required this.id,
    required this.label,
    required this.projectId,
  });

  final String id;
  final String label;
  final String projectId;

  WorkRfiOption toOption() {
    return WorkRfiOption(id: id, label: label);
  }
}

class WorkRfiProjectCatalog {
  const WorkRfiProjectCatalog({
    required this.projects,
    required this.contracts,
  });

  final List<WorkRfiOption> projects;
  final List<WorkRfiContractOption> contracts;

  static const WorkRfiProjectCatalog empty = WorkRfiProjectCatalog(
    projects: <WorkRfiOption>[],
    contracts: <WorkRfiContractOption>[],
  );
}

class WorkRfiMeasureFields {
  const WorkRfiMeasureFields({
    this.length = false,
    this.breadth = false,
    this.height = false,
    this.weight = false,
    this.no = false,
  });

  final bool length;
  final bool breadth;
  final bool height;
  final bool weight;
  final bool no;
}

class WorkRfiMeasurementDraft {
  const WorkRfiMeasurementDraft({
    required this.activityId,
    required this.activityName,
    this.measurementType = '',
    this.units = '',
    this.length = '',
    this.breadth = '',
    this.height = '',
    this.weight = '',
    this.no = '',
  });

  final String activityId;
  final String activityName;
  final String measurementType;
  final String units;
  final String length;
  final String breadth;
  final String height;
  final String weight;
  final String no;
}

class WorkRfiSubmitDraft {
  const WorkRfiSubmitDraft({
    required this.project,
    required this.contract,
    required this.structureType,
    required this.structure,
    required this.component,
    required this.element,
    required this.activities,
    required this.descriptionIds,
    required this.rfiRequired,
    required this.typeOfRfi,
    required this.contractorRepresentative,
    required this.progressDate,
    required this.dateOfSubmission,
    required this.timeOfInspection,
    required this.dateOfInspection,
    required this.enclosureIds,
    required this.description,
  });

  final String project;
  final String contract;
  final String structureType;
  final String structure;
  final String component;
  final String element;
  final List<WorkRfiMeasurementDraft> activities;
  final List<String> descriptionIds;
  final String rfiRequired;
  final String typeOfRfi;
  final String contractorRepresentative;
  final String progressDate;
  final String dateOfSubmission;
  final String timeOfInspection;
  final String dateOfInspection;
  final List<String> enclosureIds;
  final String description;
}

class WorkRfiDetail {
  const WorkRfiDetail({
    required this.id,
    required this.project,
    required this.contract,
    required this.structureType,
    required this.structure,
    required this.component,
    required this.element,
    required this.activity,
    required this.activityList,
    required this.rfiDescriptionList,
    required this.enclosuresList,
    required this.rfiRequired,
    required this.action,
    required this.typeOfRfi,
    required this.userIdOfRepresentative,
    required this.nameOfRepresentative,
    required this.timeOfInspection,
    required this.dateOfSubmission,
    required this.dateOfInspection,
    required this.progressDate,
    required this.description,
    required this.measurements,
  });

  final int? id;
  final String project;
  final String contract;
  final String structureType;
  final String structure;
  final String component;
  final String element;
  final String activity;
  final List<String> activityList;
  final List<String> rfiDescriptionList;
  final List<String> enclosuresList;
  final String rfiRequired;
  final String action;
  final String typeOfRfi;
  final String userIdOfRepresentative;
  final String nameOfRepresentative;
  final String timeOfInspection;
  final String dateOfSubmission;
  final String dateOfInspection;
  final String progressDate;
  final String description;
  final List<WorkRfiMeasurementDraft> measurements;
}

class WorkRfiEditActivities {
  const WorkRfiEditActivities({required this.selected, required this.rows});

  final List<WorkRfiOption> selected;
  final List<WorkRfiMeasurementDraft> rows;
}

const List<String> workRfiMeasurementTypes = <String>[
  'Area',
  'Length',
  'Volume',
  'Number',
  'Weight',
];

const List<WorkRfiOption> workRfiTypeOptions = <WorkRfiOption>[
  WorkRfiOption(id: 'Regular RFI', label: 'Regular RFI'),
  WorkRfiOption(id: 'Spot RFI', label: 'Spot RFI'),
];

const String workRfiFixedAction = 'Create';

WorkRfiMeasureFields workRfiFieldsFor(String type) {
  return switch (type) {
    'Area' => const WorkRfiMeasureFields(length: true, breadth: true, no: true),
    'Length' => const WorkRfiMeasureFields(length: true, no: true),
    'Volume' => const WorkRfiMeasureFields(
      length: true,
      breadth: true,
      height: true,
      no: true,
    ),
    'Number' => const WorkRfiMeasureFields(no: true),
    'Weight' => const WorkRfiMeasureFields(weight: true, no: true),
    _ => const WorkRfiMeasureFields(),
  };
}

List<String> workRfiUnitsFor(String type) {
  return switch (type) {
    'Area' => const <String>['cm²', 'm²'],
    'Length' => const <String>['cm', 'm'],
    'Volume' => const <String>['cm³', 'm³'],
    'Number' => const <String>['Nos'],
    'Weight' => const <String>['kg', 'MT'],
    _ => const <String>[],
  };
}

num? workRfiTotalQty({
  required String measurementType,
  required String length,
  required String breadth,
  required String height,
  required String weight,
  required String no,
}) {
  final WorkRfiMeasureFields fields = workRfiFieldsFor(measurementType);
  final List<(bool, String)> factors = <(bool, String)>[
    (fields.length, length),
    (fields.breadth, breadth),
    (fields.height, height),
    (fields.weight, weight),
    (fields.no, no),
  ];
  num product = 1;
  var included = 0;
  for (final (bool enabled, String raw) in factors) {
    if (!enabled) {
      continue;
    }
    final String text = raw.trim();
    if (text.isEmpty) {
      return null;
    }
    final num? parsed = num.tryParse(text);
    if (parsed == null) {
      return null;
    }
    product *= parsed;
    included++;
  }
  if (included == 0) {
    return null;
  }
  return _whole(product);
}

String? workRfiValidationMessage(WorkRfiSubmitDraft draft) {
  final List<String> missing = <String>[];
  void requireText(String value, String label) {
    if (value.trim().isEmpty) {
      missing.add(label);
    }
  }

  requireText(draft.project, 'Project');
  requireText(draft.contract, 'Contract');
  requireText(draft.structureType, 'Structure Type');
  requireText(draft.structure, 'Structure');
  requireText(draft.component, 'Component');
  requireText(draft.element, 'Element');
  if (draft.activities.isEmpty) {
    missing.add('Activity');
  }
  if (draft.descriptionIds.where((String id) => id.trim().isNotEmpty).isEmpty) {
    missing.add('RFI Description');
  }
  if (draft.rfiRequired != 'Yes' && draft.rfiRequired != 'No') {
    missing.add('RFI Required');
  }
  for (final WorkRfiMeasurementDraft row in draft.activities) {
    final String name = row.activityName.trim().isEmpty
        ? 'activity'
        : row.activityName.trim();
    if (!workRfiMeasurementTypes.contains(row.measurementType)) {
      missing.add('Type of Measurement for $name');
      continue;
    }
    final List<String> units = workRfiUnitsFor(row.measurementType);
    if (!units.contains(row.units)) {
      missing.add('Units for $name');
    }
    final WorkRfiMeasureFields fields = workRfiFieldsFor(row.measurementType);
    void requireNumber(bool enabled, String raw, String label) {
      if (!enabled) {
        return;
      }
      final String text = raw.trim();
      if (text.isEmpty || num.tryParse(text) == null) {
        missing.add('$label for $name');
      }
    }

    requireNumber(fields.length, row.length, 'Length');
    requireNumber(fields.breadth, row.breadth, 'Breadth');
    requireNumber(fields.height, row.height, 'Height');
    requireNumber(fields.weight, row.weight, 'Weight');
    requireNumber(fields.no, row.no, 'No.');
  }
  if (draft.rfiRequired == 'Yes') {
    requireText(draft.typeOfRfi, 'Type of RFI');
    requireText(
      draft.contractorRepresentative,
      "Name of Contractor's Representative",
    );
    if (workRfiApiTime(draft.timeOfInspection).isEmpty) {
      missing.add('Time of Inspection');
    }
    if (workRfiApiDate(draft.dateOfInspection).isEmpty) {
      missing.add('Date of Inspection');
    }
    if (workRfiApiDate(draft.dateOfSubmission).isEmpty) {
      missing.add('Date of Submission of RFI');
    }
    if (draft.enclosureIds.where((String id) => id.trim().isNotEmpty).isEmpty) {
      missing.add('Enclosures');
    }
  } else if (draft.rfiRequired == 'No') {
    if (workRfiApiDate(draft.progressDate).isEmpty) {
      missing.add('Progress Date');
    }
  }
  if (missing.isEmpty) {
    return null;
  }
  return 'Missing ${missing.join(', ')}.';
}

Map<String, dynamic> buildWorkRfiPayload(WorkRfiSubmitDraft draft) {
  final bool yes = draft.rfiRequired == 'Yes';
  final bool no = draft.rfiRequired == 'No';
  final List<String> activityIds = <String>[
    for (final WorkRfiMeasurementDraft row in draft.activities)
      if (row.activityId.trim().isNotEmpty) row.activityId.trim(),
  ];
  final List<String> descriptionIds = <String>[
    for (final String id in draft.descriptionIds)
      if (id.trim().isNotEmpty) id.trim(),
  ];
  final List<String> enclosureIds = yes
      ? <String>[
          for (final String id in draft.enclosureIds)
            if (id.trim().isNotEmpty) id.trim(),
        ]
      : <String>[];
  return <String, dynamic>{
    'project': draft.project,
    'contract': draft.contract,
    'structureType': draft.structureType,
    'structure': draft.structure,
    'component': draft.component,
    'element': draft.element,
    'chainageFrom': '',
    'chainageTo': '',
    'layer': '',
    'activity': activityIds.isEmpty ? '' : activityIds.first,
    'selectedActivities': activityIds,
    'rfiDescription': '',
    'selectedRfiDescriptions': descriptionIds,
    'rfiRequired': draft.rfiRequired,
    'action': workRfiFixedAction,
    'typeOfRfi': yes ? draft.typeOfRfi : '',
    'contractorRepresentative': yes ? draft.contractorRepresentative : '',
    'progressDate': no ? workRfiApiDate(draft.progressDate) : '',
    'dateOfSubmission': yes ? workRfiApiDate(draft.dateOfSubmission) : '',
    'timeOfInspection': yes ? workRfiApiTime(draft.timeOfInspection) : '',
    'dateOfInspection': yes ? workRfiApiDate(draft.dateOfInspection) : '',
    'boqItemRequired': yes ? 'No' : '',
    'boqItem': '',
    'selectedEnclosures': enclosureIds,
    'description': draft.description,
    'activities': <Map<String, dynamic>>[
      for (final WorkRfiMeasurementDraft row in draft.activities)
        _activityPayload(row),
    ],
    'rfiDescriptions': descriptionIds,
    'enclosures': enclosureIds,
    'projectId': draft.project,
    'structureId': draft.structure,
  };
}

WorkRfiProjectCatalog parseWorkRfiProjectCatalog(dynamic data) {
  if (data is! Map) {
    return WorkRfiProjectCatalog.empty;
  }
  final Map<String, dynamic> map = Map<String, dynamic>.from(data);
  final List<WorkRfiOption> projects = _dedupeOptions(<WorkRfiOption>[
    for (final Map<String, dynamic> row in _rows(
      map['projectsList'] ?? map['projects'],
      isRecord: (Map<String, dynamic> row) =>
          row.containsKey('project_id_fk') ||
          row.containsKey('project_name') ||
          row.containsKey('projectId'),
    ))
      if (_projectOption(row) case final WorkRfiOption option) option,
  ]);
  return WorkRfiProjectCatalog(
    projects: projects,
    contracts: parseWorkRfiContracts(map['contractsList'] ?? map['contracts']),
  );
}

List<WorkRfiContractOption> parseWorkRfiContracts(
  dynamic data, {
  String projectId = '',
}) {
  final List<Map<String, dynamic>> rows;
  if (data is Map &&
      (data.containsKey('contractsList') || data.containsKey('contracts'))) {
    final Map<dynamic, dynamic> map = data;
    rows = _rows(
      map['contractsList'] ?? map['contracts'],
      isRecord: _isContract,
    );
  } else {
    rows = _rows(data, isRecord: _isContract);
  }
  final List<WorkRfiContractOption> contracts = <WorkRfiContractOption>[];
  final Set<String> seen = <String>{};
  for (final Map<String, dynamic> row in rows) {
    final WorkRfiContractOption? option = _contractOption(
      row,
      fallbackProjectId: projectId,
    );
    if (option == null || !seen.add(option.id)) {
      continue;
    }
    contracts.add(option);
  }
  return contracts;
}

List<WorkRfiContractOption> workRfiContractsForProject(
  List<WorkRfiContractOption> contracts,
  String projectId,
) {
  return contracts
      .where(
        (WorkRfiContractOption contract) => contract.projectId == projectId,
      )
      .toList(growable: false);
}

List<WorkRfiOption> parseWorkRfiStructureTypes(dynamic data) {
  return _dedupeOptions(<WorkRfiOption>[
    for (final Map<String, dynamic> row in _rows(
      data,
      isRecord: (Map<String, dynamic> row) => row.containsKey('structure_type'),
    ))
      if (_sameOption(row['structure_type']) case final WorkRfiOption option)
        option,
  ]);
}

List<WorkRfiOption> parseWorkRfiStructures(dynamic data) {
  return _dedupeOptions(<WorkRfiOption>[
    for (final Map<String, dynamic> row in _rows(
      data,
      isRecord: (Map<String, dynamic> row) =>
          row.containsKey('structure_id') ||
          row.containsKey('strip_chart_structure_id_fk'),
    ))
      if (_labeledOption(
            row['structure_id'],
            row['strip_chart_structure_id_fk'],
          )
          case final WorkRfiOption option)
        option,
  ]);
}

List<WorkRfiOption> parseWorkRfiComponents(dynamic data) {
  return _dedupeOptions(<WorkRfiOption>[
    for (final Map<String, dynamic> row in _rows(
      data,
      isRecord: (Map<String, dynamic> row) =>
          row.containsKey('strip_chart_component'),
    ))
      if (_sameOption(row['strip_chart_component'])
          case final WorkRfiOption option)
        option,
  ]);
}

List<WorkRfiOption> parseWorkRfiElements(dynamic data) {
  return _dedupeOptions(<WorkRfiOption>[
    for (final Map<String, dynamic> row in _rows(
      data,
      isRecord: (Map<String, dynamic> row) =>
          row.containsKey('strip_chart_component_id'),
    ))
      if (_sameOption(row['strip_chart_component_id'])
          case final WorkRfiOption option)
        option,
  ]);
}

List<WorkRfiOption> parseWorkRfiActivities(dynamic data) {
  return _dedupeOptions(<WorkRfiOption>[
    for (final Map<String, dynamic> row in _rows(
      data,
      isRecord: (Map<String, dynamic> row) =>
          row.containsKey('strip_chart_activity_id') ||
          row.containsKey('strip_chart_activity_name'),
    ))
      if (_labeledOption(
            row['strip_chart_activity_id'],
            row['strip_chart_activity_name'],
          )
          case final WorkRfiOption option)
        option,
  ]);
}

List<WorkRfiOption> parseWorkRfiDescriptions(dynamic data) {
  final List<WorkRfiOption> options = <WorkRfiOption>[];
  for (final Map<String, dynamic> row in _rows(
    data,
    isRecord: (Map<String, dynamic> row) =>
        row.containsKey('rfiDescription') || row.containsKey('id'),
  )) {
    if (_text(row['rfiDescription']).isEmpty) {
      continue;
    }
    final WorkRfiOption? option = _labeledOption(
      row['id'],
      row['rfiDescription'],
    );
    if (option != null) {
      options.add(option);
    }
  }
  return _dedupeOptions(options);
}

List<WorkRfiOption> parseWorkRfiEnclosures(dynamic data) {
  return _dedupeOptions(<WorkRfiOption>[
    for (final Map<String, dynamic> row in _rows(
      data,
      isRecord: (Map<String, dynamic> row) =>
          row.containsKey('encloserName') ||
          row.containsKey('enclosureName') ||
          row.containsKey('id'),
    ))
      if (_labeledOption(
            row['id'],
            row['encloserName'] ?? row['enclosureName'] ?? row['name'],
          )
          case final WorkRfiOption option)
        option,
  ]);
}

List<WorkRfiOption> parseWorkRfiRepresentatives(dynamic data) {
  return _dedupeOptions(<WorkRfiOption>[
    for (final Map<String, dynamic> row in _rows(
      data,
      extraKeys: const <String>[
        'representatives',
        'users',
        'workRepresentatives',
      ],
      isRecord: (Map<String, dynamic> row) =>
          row.containsKey('userId') ||
          row.containsKey('user_id') ||
          row.containsKey('userName') ||
          row.containsKey('nameOfRepresentative') ||
          row.containsKey('name') ||
          row.containsKey('id'),
    ))
      if (_labeledOption(
            row['userId'] ?? row['user_id'] ?? row['id'],
            row['userName'] ?? row['name'] ?? row['nameOfRepresentative'],
          )
          case final WorkRfiOption option)
        option,
  ]);
}

WorkRfiDetail? parseWorkRfiDetail(dynamic data) {
  final Map<String, dynamic>? map = _detailMap(data);
  if (map == null) {
    return null;
  }
  final WorkRfiDetail detail = WorkRfiDetail(
    id: _readId(map['id']),
    project: _firstText(map, const <String>['project', 'projectId']),
    contract: _text(map['contract']),
    structureType: _text(map['structureType']),
    structure: _firstText(map, const <String>['structure', 'structureId']),
    component: _text(map['component']),
    element: _text(map['element']),
    activity: _text(map['activity']),
    activityList: _idList(map['activityList']),
    rfiDescriptionList: _idList(
      map['rfiDescriptionList'] ?? map['selectedRfiDescriptions'],
    ),
    enclosuresList: _idList(map['enclosuresList'] ?? map['enclosures']),
    rfiRequired: _text(map['rfiRequired']),
    action: _text(map['action']),
    typeOfRfi: _firstText(map, const <String>['typeOfRFI', 'typeOfRfi']),
    userIdOfRepresentative: _firstText(map, const <String>[
      'userIdOfRepresentative',
      'userId',
      'user_id',
    ]),
    nameOfRepresentative: _text(map['nameOfRepresentative']),
    timeOfInspection: _text(map['timeOfInspection']),
    dateOfSubmission: _text(map['dateOfSubmission']),
    dateOfInspection: _text(map['dateOfInspection']),
    progressDate: _firstText(map, const <String>[
      'progressDate',
      'progress_date',
    ]),
    description: _text(map['description']),
    measurements: _measurements(map['measurements']),
  );
  if (detail.id == null && detail.project.isEmpty && detail.contract.isEmpty) {
    return null;
  }
  return detail;
}

WorkRfiEditActivities resolveWorkRfiEditActivities({
  required List<WorkRfiOption> options,
  required List<String> activityList,
  required String activityId,
  required List<WorkRfiMeasurementDraft> measurements,
}) {
  final Map<String, WorkRfiOption> byId = <String, WorkRfiOption>{
    for (final WorkRfiOption option in options) option.id: option,
  };
  final List<String> ids = <String>[];
  void addExisting(String id) {
    final String key = id.trim();
    if (key.isEmpty || ids.contains(key) || !byId.containsKey(key)) {
      return;
    }
    ids.add(key);
  }

  for (final String id in activityList) {
    addExisting(id);
  }
  if (activityList.isEmpty) {
    addExisting(activityId);
  }
  for (final WorkRfiMeasurementDraft row in measurements) {
    addExisting(row.activityId);
  }

  WorkRfiMeasurementDraft? savedFor(String id) {
    for (final WorkRfiMeasurementDraft row in measurements) {
      if (row.activityId == id) {
        return row;
      }
    }
    return null;
  }

  final List<WorkRfiOption> selected = <WorkRfiOption>[
    for (final String id in ids) byId[id]!,
  ];
  final List<WorkRfiMeasurementDraft> rows = <WorkRfiMeasurementDraft>[
    for (final String id in ids) _draftForOption(byId[id]!, savedFor(id)),
  ];
  for (final WorkRfiMeasurementDraft row in measurements) {
    final String id = row.activityId.trim();
    if (id.isNotEmpty && byId.containsKey(id)) {
      continue;
    }
    if (id.isEmpty && row.activityName.trim().isEmpty) {
      continue;
    }
    final String key = id.isEmpty ? 'missing-${row.activityName.trim()}' : id;
    if (selected.any((WorkRfiOption option) => option.id == key)) {
      continue;
    }
    final String name = row.activityName.trim().isEmpty
        ? key
        : row.activityName.trim();
    selected.add(WorkRfiOption(id: key, label: name));
    rows.add(
      WorkRfiMeasurementDraft(
        activityId: key,
        activityName: name,
        measurementType: row.measurementType,
        units: row.units,
        length: row.length,
        breadth: row.breadth,
        height: row.height,
        weight: row.weight,
        no: row.no,
      ),
    );
  }
  return WorkRfiEditActivities(selected: selected, rows: rows);
}

DateTime? parseWorkRfiDate(String raw) {
  final String text = raw.trim();
  if (text.isEmpty) {
    return null;
  }
  final RegExpMatch? iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(text);
  if (iso != null) {
    return _date(iso.group(1), iso.group(2), iso.group(3));
  }
  final RegExpMatch? local = RegExp(
    r'^(\d{2})[/-](\d{2})[/-](\d{4})',
  ).firstMatch(text);
  if (local != null) {
    return _date(local.group(3), local.group(2), local.group(1));
  }
  return null;
}

String workRfiApiDate(String raw) {
  final DateTime? date = parseWorkRfiDate(raw);
  if (date == null) {
    return '';
  }
  return _formatApiDate(date);
}

String workRfiDisplayDate(String raw) {
  final DateTime? date = parseWorkRfiDate(raw);
  if (date == null) {
    return '';
  }
  return _formatDisplayDate(date);
}

String workRfiFormatApiDate(DateTime date) {
  return _formatApiDate(date);
}

String workRfiFormatDisplayDate(DateTime date) {
  return _formatDisplayDate(date);
}

String workRfiApiTime(String raw) {
  final String text = raw.trim();
  if (text.isEmpty) {
    return '';
  }
  final RegExpMatch? twelve = RegExp(
    r'^(\d{1,2}):(\d{2})\s*([AP]M)$',
    caseSensitive: false,
  ).firstMatch(text);
  if (twelve != null) {
    final int? hour = int.tryParse(twelve.group(1)!);
    final int? minute = int.tryParse(twelve.group(2)!);
    if (hour == null ||
        minute == null ||
        hour < 1 ||
        hour > 12 ||
        minute > 59) {
      return '';
    }
    final bool pm = twelve.group(3)!.toUpperCase() == 'PM';
    final int normalized = pm ? (hour % 12) + 12 : hour % 12;
    return _formatApiTime(normalized, minute);
  }
  final RegExpMatch? twentyFour = RegExp(
    r'^(\d{1,2}):(\d{2})(?::\d{2})?$',
  ).firstMatch(text);
  if (twentyFour == null) {
    return '';
  }
  final int? hour = int.tryParse(twentyFour.group(1)!);
  final int? minute = int.tryParse(twentyFour.group(2)!);
  if (hour == null || minute == null || hour > 23 || minute > 59) {
    return '';
  }
  return _formatApiTime(hour, minute);
}

String workRfiDisplayTime(String raw) {
  final String api = workRfiApiTime(raw);
  if (api.isEmpty) {
    return '';
  }
  final List<String> parts = api.split(':');
  final int hour = int.parse(parts[0]);
  final String minute = parts[1];
  final String period = hour >= 12 ? 'PM' : 'AM';
  final int hour12 = hour % 12 == 0 ? 12 : hour % 12;
  return '${hour12.toString().padLeft(2, '0')}:$minute $period';
}

String workRfiNumberText(Object? value) {
  if (value == null) {
    return '';
  }
  if (value is num) {
    return _whole(value).toString();
  }
  return _text(value);
}

Map<String, dynamic> _activityPayload(WorkRfiMeasurementDraft row) {
  final WorkRfiMeasureFields fields = workRfiFieldsFor(row.measurementType);
  final num? total = workRfiTotalQty(
    measurementType: row.measurementType,
    length: row.length,
    breadth: row.breadth,
    height: row.height,
    weight: row.weight,
    no: row.no,
  );
  return <String, dynamic>{
    'id': row.activityId,
    'activityId': row.activityId,
    'activity': row.activityId,
    'activityName': row.activityName,
    'measurementType': row.measurementType,
    'units': row.units,
    'length': _jsonNumber(row.length, enabled: fields.length),
    'breadth': _jsonNumber(row.breadth, enabled: fields.breadth),
    'height': _jsonNumber(row.height, enabled: fields.height),
    'weight': _jsonNumber(row.weight, enabled: fields.weight),
    'no': _jsonNumber(row.no, enabled: fields.no),
    'totalQty': total ?? '',
  };
}

Object _jsonNumber(String raw, {required bool enabled}) {
  if (!enabled) {
    return '';
  }
  final String text = raw.trim();
  if (text.isEmpty) {
    return '';
  }
  final num? parsed = num.tryParse(text);
  if (parsed == null) {
    return '';
  }
  return _whole(parsed);
}

num _whole(num value) {
  if (value is int) {
    return value;
  }
  if (value == value.roundToDouble()) {
    return value.toInt();
  }
  return value;
}

WorkRfiMeasurementDraft _draftForOption(
  WorkRfiOption option,
  WorkRfiMeasurementDraft? saved,
) {
  if (saved == null) {
    return WorkRfiMeasurementDraft(
      activityId: option.id,
      activityName: option.label,
    );
  }
  final String type = workRfiMeasurementTypes.contains(saved.measurementType)
      ? saved.measurementType
      : '';
  final List<String> units = workRfiUnitsFor(type);
  return WorkRfiMeasurementDraft(
    activityId: option.id,
    activityName: option.label,
    measurementType: type,
    units: units.contains(saved.units)
        ? saved.units
        : units.length == 1
        ? units.first
        : '',
    length: saved.length,
    breadth: saved.breadth,
    height: saved.height,
    weight: saved.weight,
    no: saved.no,
  );
}

List<WorkRfiMeasurementDraft> _measurements(Object? value) {
  return <WorkRfiMeasurementDraft>[
    for (final Map<String, dynamic> row in _rows(
      value,
      isRecord: (Map<String, dynamic> row) =>
          row.containsKey('measurementType') ||
          row.containsKey('activityIdFk') ||
          row.containsKey('activityName') ||
          row.containsKey('totalQty') ||
          row.containsKey('noOfItems'),
    ))
      WorkRfiMeasurementDraft(
        activityId: _firstText(row, const <String>[
          'activityIdFk',
          'activityId',
          'activity',
        ]),
        activityName: _text(row['activityName']),
        measurementType: _text(row['measurementType']),
        units: _text(row['units']),
        length: workRfiNumberText(row['length']),
        breadth: workRfiNumberText(row['breadth']),
        height: workRfiNumberText(row['height']),
        weight: workRfiNumberText(row['weight']),
        no: workRfiNumberText(row['noOfItems'] ?? row['no']),
      ),
  ];
}

Map<String, dynamic>? _detailMap(dynamic data) {
  if (data is! Map) {
    return null;
  }
  final Map<String, dynamic> map = Map<String, dynamic>.from(data);
  if (map.isEmpty) {
    return null;
  }
  final bool looksLikeDetail =
      map.containsKey('project') ||
      map.containsKey('id') ||
      map.containsKey('rfiRequired') ||
      map.containsKey('measurements');
  if (looksLikeDetail) {
    return map;
  }
  for (final String key in const <String>['data', 'result', 'content']) {
    final Map<String, dynamic>? nested = _detailMap(map[key]);
    if (nested != null) {
      return nested;
    }
  }
  return null;
}

List<Map<String, dynamic>> _rows(
  dynamic data, {
  bool Function(Map<String, dynamic> map)? isRecord,
  List<String> extraKeys = const <String>[],
}) {
  if (data == null) {
    return <Map<String, dynamic>>[];
  }
  if (data is List) {
    return <Map<String, dynamic>>[
      for (final Object? item in data)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    if (map.isEmpty) {
      return <Map<String, dynamic>>[];
    }
    if (isRecord != null && isRecord(map)) {
      return <Map<String, dynamic>>[map];
    }
    for (final String key in <String>[
      ...extraKeys,
      'data',
      'result',
      'content',
      'list',
      'records',
      'items',
      'response',
    ]) {
      final Object? nested = map[key];
      if (nested is List || nested is Map) {
        return _rows(nested, isRecord: isRecord, extraKeys: extraKeys);
      }
    }
    if (isRecord == null) {
      return <Map<String, dynamic>>[map];
    }
    return <Map<String, dynamic>>[];
  }
  return <Map<String, dynamic>>[];
}

bool _isContract(Map<String, dynamic> row) {
  return row.containsKey('contract_id') ||
      row.containsKey('contract_short_name') ||
      row.containsKey('contract_name');
}

WorkRfiOption? _projectOption(Map<String, dynamic> row) {
  final String id = _firstText(row, const <String>[
    'project_id_fk',
    'projectId',
    'project_id',
    'id',
  ]);
  if (id.isEmpty) {
    return null;
  }
  final String name = _firstText(row, const <String>[
    'project_name',
    'projectName',
    'name',
  ]);
  return WorkRfiOption(id: id, label: name.isEmpty ? id : name);
}

WorkRfiContractOption? _contractOption(
  Map<String, dynamic> row, {
  required String fallbackProjectId,
}) {
  final String id = _firstText(row, const <String>[
    'contract_id',
    'contractId',
    'id',
  ]);
  if (id.isEmpty) {
    return null;
  }
  final String shortName = _text(row['contract_short_name']);
  final String name = _firstText(row, const <String>[
    'contract_name',
    'contractName',
  ]);
  final String label = shortName.isNotEmpty
      ? shortName
      : name.isNotEmpty
      ? name
      : id;
  final String projectId = _firstText(row, const <String>[
    'project_id_fk',
    'projectId',
    'project_id',
  ]);
  return WorkRfiContractOption(
    id: id,
    label: label,
    projectId: projectId.isEmpty ? fallbackProjectId : projectId,
  );
}

WorkRfiOption? _sameOption(Object? value) {
  final String text = workRfiIdText(value);
  if (text.isEmpty) {
    return null;
  }
  return WorkRfiOption(id: text, label: text);
}

WorkRfiOption? _labeledOption(Object? idValue, Object? labelValue) {
  final String id = workRfiIdText(idValue);
  if (id.isEmpty) {
    return null;
  }
  final String label = _text(labelValue);
  return WorkRfiOption(id: id, label: label.isEmpty ? id : label);
}

List<WorkRfiOption> _dedupeOptions(List<WorkRfiOption> options) {
  final Set<String> seen = <String>{};
  return <WorkRfiOption>[
    for (final WorkRfiOption option in options)
      if (option.id.isNotEmpty && seen.add(option.id)) option,
  ];
}

List<String> _idList(Object? value) {
  if (value is List) {
    return <String>[
      for (final Object? item in value)
        if (workRfiIdText(item).isNotEmpty) workRfiIdText(item),
    ];
  }
  final String one = workRfiIdText(value);
  if (one.isEmpty) {
    return <String>[];
  }
  return <String>[one];
}

String workRfiIdText(Object? value) {
  if (value == null) {
    return '';
  }
  if (value is num) {
    return _whole(value).toString();
  }
  return _text(value);
}

String _firstText(Map<String, dynamic> json, List<String> keys) {
  for (final String key in keys) {
    final String text = key == 'id'
        ? workRfiIdText(json[key])
        : _text(json[key]);
    if (text.isNotEmpty) {
      return key == 'structure' ||
              key == 'structureId' ||
              key == 'activity' ||
              key == 'activityIdFk' ||
              key == 'activityId' ||
              key == 'project' ||
              key == 'projectId' ||
              key.endsWith('Id') ||
              key.endsWith('_id') ||
              key.endsWith('_fk') ||
              key == 'id'
          ? workRfiIdText(json[key])
          : text;
    }
  }
  return '';
}

int? _readId(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim());
  }
  return null;
}

String _text(Object? value) {
  if (value == null) {
    return '';
  }
  final String text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return '';
  }
  return text;
}

DateTime? _date(String? year, String? month, String? day) {
  final int? y = int.tryParse(year ?? '');
  final int? m = int.tryParse(month ?? '');
  final int? d = int.tryParse(day ?? '');
  if (y == null ||
      m == null ||
      d == null ||
      m < 1 ||
      m > 12 ||
      d < 1 ||
      d > 31) {
    return null;
  }
  final DateTime date = DateTime(y, m, d);
  if (date.year != y || date.month != m || date.day != d) {
    return null;
  }
  return date;
}

String _formatApiDate(DateTime date) {
  final String year = date.year.toString().padLeft(4, '0');
  final String month = date.month.toString().padLeft(2, '0');
  final String day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String _formatDisplayDate(DateTime date) {
  final String day = date.day.toString().padLeft(2, '0');
  final String month = date.month.toString().padLeft(2, '0');
  final String year = date.year.toString().padLeft(4, '0');
  return '$day/$month/$year';
}

String _formatApiTime(int hour, int minute) {
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
