import 'package:swr_pmis_mobile/src/features/projects/domain/project_form.dart';
import 'package:swr_pmis_mobile/src/features/projects/domain/project_list.dart';

List<ProjectOption> parseProjectTypes(dynamic data) {
  return _options(data, (Map<String, dynamic> json) {
    final String id = _first(json, const <String>[
      'project_type_id',
      'project_type_id_fk',
      'id',
    ]);
    final String name = _first(json, const <String>[
      'project_type_name',
      'project_type',
      'name',
      'label',
    ]);
    if (id.isEmpty && name.isEmpty) {
      return null;
    }
    return ProjectOption(
      value: id.isEmpty ? name : id,
      label: name.isEmpty ? id : name,
    );
  });
}

List<ProjectOption> parseRailwayZones(dynamic data) {
  return _options(data, (Map<String, dynamic> json) {
    final String id = _first(json, const <String>[
      'railway_zone',
      'railway_id',
      'railway',
      'id',
      'value',
    ]);
    final String label = _first(json, const <String>[
      'railway_zone',
      'railway_name',
      'name',
      'label',
      'railway_id',
    ]);
    if (id.isEmpty && label.isEmpty) {
      return null;
    }
    return ProjectOption(
      value: id.isEmpty ? label : id,
      label: label.isEmpty ? id : label,
    );
  });
}

List<ProjectOption> parseYearList(dynamic data) {
  return _options(data, (Map<String, dynamic> json) {
    final String year = _first(json, const <String>[
      'financial_year',
      'sanctioned_year',
      'year',
      'label',
      'value',
    ]);
    if (year.isEmpty) {
      return null;
    }
    return ProjectOption(value: year, label: year);
  });
}

List<ProjectOption> parseDivisions(dynamic data) {
  return _options(data, (Map<String, dynamic> json) {
    final String id = _first(json, const <String>[
      'division_id',
      'division_id_fk',
      'id',
    ]);
    final String name = _first(json, const <String>[
      'division_name',
      'division',
      'name',
      'label',
    ]);
    if (id.isEmpty && name.isEmpty) {
      return null;
    }
    return ProjectOption(
      value: id.isEmpty ? name : id,
      label: name.isEmpty ? id : name,
    );
  }, listKeys: const <String>['divisionsList', 'divisions', 'data', 'result']);
}

List<ProjectOption> parseSections(dynamic data) {
  return _options(data, (Map<String, dynamic> json) {
    final String id = _first(json, const <String>[
      'section_id',
      'section_id_fk',
      'id',
    ]);
    final String name = _first(json, const <String>[
      'section_name',
      'section',
      'name',
      'label',
    ]);
    final String divisionId = _first(json, const <String>[
      'division_id',
      'division_id_fk',
    ]);
    if (id.isEmpty && name.isEmpty) {
      return null;
    }
    return ProjectOption(
      value: id.isEmpty ? name : id,
      label: name.isEmpty ? id : name,
      meta: divisionId.isEmpty ? null : divisionId,
    );
  });
}

bool parseProjectNameExists(dynamic data) {
  if (data is bool) {
    return data;
  }
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    final Object? exists = map['exists'] ?? map['Exists'];
    if (exists is bool) {
      return exists;
    }
    final String text = exists?.toString().trim().toLowerCase() ?? '';
    if (text == 'true' || text == '1' || text == 'yes') {
      return true;
    }
    if (text == 'false' || text == '0' || text == 'no') {
      return false;
    }
  }
  return false;
}

String parseProjectMutationMessage(dynamic data, {required String fallback}) {
  if (data == null) {
    return fallback;
  }
  if (data is String) {
    final String text = data.trim();
    return text.isEmpty ? fallback : text;
  }
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    final String? error = _text(map['error']) ?? _text(map['Error']);
    if (error != null) {
      throw StateError(error);
    }
    final Object? success = map['success'];
    if (success == false || success?.toString().toLowerCase() == 'false') {
      final String message =
          _text(map['message']) ?? _text(map['msg']) ?? fallback;
      throw StateError(message);
    }
    for (final String key in const <String>[
      'message',
      'msg',
      'result',
      'success',
    ]) {
      final String? text = _text(map[key]);
      if (text != null && text.toLowerCase() != 'true') {
        return text;
      }
    }
  }
  return fallback;
}

List<ProjectRow> parseProjectRows(dynamic data) {
  final List<ProjectRow> rows = <ProjectRow>[];
  for (final Map<String, dynamic> json in _projectRecords(data)) {
    final String id = _first(json, const <String>[
      'project_id',
      'project_id_fk',
      'id',
    ]);
    final String name = _first(json, const <String>[
      'project_name',
      'project_code',
      'name',
    ]);
    if (id.isEmpty && name.isEmpty) {
      continue;
    }
    final String typeId = _first(json, const <String>[
      'project_type_id',
      'project_type_id_fk',
    ]);
    final String typeName = _first(json, const <String>[
      'project_type_name',
      'project_type',
      'work_type',
    ]);
    rows.add(
      ProjectRow(
        projectId: id,
        projectName: name,
        projectStatus: _first(json, const <String>[
          'project_status',
          'status',
        ]),
        projectTypeId: typeId,
        projectTypeName: typeName.isEmpty ? typeId : typeName,
        railwayZone: _first(json, const <String>[
          'railway_zone',
          'railway',
          'railway_id',
        ]),
        planHeadNumber: _first(json, const <String>[
          'plan_head_number',
          'plan_head_no',
        ]),
        sanctionedAmount: _display(json['sanctioned_amount']),
        sanctionedYear: _first(json, const <String>[
          'sanctioned_year',
          'sanctioned_year_fk',
          'financial_year',
        ]),
        sanctionedCommissioningDate: _formatDate(
          json['sanctioned_commissioning_date'] ?? json['date_of_sanction'],
        ),
        divisionId: _first(json, const <String>[
          'division_id',
          'division_id_fk',
        ]),
        divisionName: _first(json, const <String>[
          'division_name',
          'division',
        ]),
        sectionId: _first(json, const <String>[
          'section_id',
          'section_id_fk',
        ]),
        sectionName: _first(json, const <String>[
          'section_name',
          'section',
          'sections',
        ]),
        pbItemNumber: _first(json, const <String>[
          'pb_item_number',
          'pb_item_no',
          'pink_book_item_number',
        ]),
        fromChainage: _display(json['from_chainage']),
        toChainage: _display(json['to_chainage']),
        proposedLength: _display(json['proposed_length']),
        actualCompletionCost: _display(json['actual_completion_cost']),
        actualCompletionDate: _formatDate(json['actual_completion_date']),
        benefits: _display(json['benefits']),
        remarks: _display(json['remarks']),
        blockSections: _parseBlockSections(json),
        completionCosts: _parseCompletionCosts(json),
      ),
    );
  }
  return rows;
}

List<ProjectBlockSectionRow> _parseBlockSections(Map<String, dynamic> json) {
  final Object? nested = json['blockSections'] ?? json['block_sections'];
  if (nested is List && nested.isNotEmpty) {
    final List<ProjectBlockSectionRow> rows = <ProjectBlockSectionRow>[];
    for (final Object? item in nested) {
      if (item is! Map) {
        continue;
      }
      final Map<String, dynamic> map = Map<String, dynamic>.from(item);
      final String name = _first(map, const <String>[
        'section',
        'block_section_name',
        'name',
      ]);
      rows.add(
        ProjectBlockSectionRow(
          name: name,
          fromChainage: _display(map['from_chainage']),
          toChainage: _display(map['to_chainage']),
          commissioningDate: _nullableDate(map['commissioning_date']),
        ),
      );
    }
    if (rows.isNotEmpty) {
      return rows;
    }
  }
  final List<String> names = _stringList(json['block_section_names']);
  final List<String> from = _stringList(json['block_from_chainages']);
  final List<String> to = _stringList(json['block_to_chainages']);
  final List<String?> dates = _nullableStringList(
    json['block_commissioning_dates'],
  );
  final int count = <int>[
    names.length,
    from.length,
    to.length,
    dates.length,
  ].fold<int>(0, (int max, int value) => value > max ? value : max);
  if (count == 0) {
    return const <ProjectBlockSectionRow>[];
  }
  return <ProjectBlockSectionRow>[
    for (int i = 0; i < count; i++)
      ProjectBlockSectionRow(
        name: i < names.length ? names[i] : '',
        fromChainage: i < from.length ? from[i] : '',
        toChainage: i < to.length ? to[i] : '',
        commissioningDate: i < dates.length ? dates[i] : null,
      ),
  ];
}

List<ProjectCompletionCostRow> _parseCompletionCosts(Map<String, dynamic> json) {
  final Object? nested = json['completionCosts'] ?? json['completion_costs'];
  if (nested is List && nested.isNotEmpty) {
    final List<ProjectCompletionCostRow> rows = <ProjectCompletionCostRow>[];
    for (final Object? item in nested) {
      if (item is! Map) {
        continue;
      }
      final Map<String, dynamic> map = Map<String, dynamic>.from(item);
      rows.add(
        ProjectCompletionCostRow(
          date: _nullableDate(
            map['completion_date'] ?? map['date'] ?? map['completion_dates'],
          ),
          estimatedCost: _nullableText(
            map['estimated_completion_cost'] ??
                map['estimated_cost'] ??
                map['estimated_completion_costs'],
          ),
          revisedDate: _nullableDate(
            map['revised_completion_date'] ?? map['revised_date'],
          ),
        ),
      );
    }
    if (rows.isNotEmpty) {
      return rows;
    }
  }
  final List<String?> dates = _nullableStringList(json['completion_dates']);
  final List<String?> costs = _nullableStringList(
    json['estimated_completion_costs'],
  );
  final List<String?> revised = _nullableStringList(
    json['revised_completion_dates'],
  );
  final int count = <int>[
    dates.length,
    costs.length,
    revised.length,
  ].fold<int>(0, (int max, int value) => value > max ? value : max);
  if (count == 0) {
    return const <ProjectCompletionCostRow>[];
  }
  return <ProjectCompletionCostRow>[
    for (int i = 0; i < count; i++)
      ProjectCompletionCostRow(
        date: i < dates.length ? dates[i] : null,
        estimatedCost: i < costs.length ? costs[i] : null,
        revisedDate: i < revised.length ? revised[i] : null,
      ),
  ];
}

List<ProjectOption> _options(
  dynamic data,
  ProjectOption? Function(Map<String, dynamic> json) read, {
  List<String> listKeys = const <String>[
    'data',
    'result',
    'content',
    'items',
    'list',
    'rows',
    'aaData',
  ],
}) {
  final Map<String, ProjectOption> unique = <String, ProjectOption>{};
  for (final Map<String, dynamic> json in _records(data, listKeys: listKeys)) {
    final ProjectOption? option = read(json);
    if (option == null) {
      continue;
    }
    unique.putIfAbsent(option.value, () => option);
  }
  final List<ProjectOption> values = unique.values.toList()
    ..sort(
      (ProjectOption a, ProjectOption b) =>
          a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );
  return values;
}

List<Map<String, dynamic>> _projectRecords(dynamic data) {
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    for (final String key in const <String>[
      'aaData',
      'projects',
      'projectList',
      'data',
      'result',
      'rows',
    ]) {
      final Object? nested = map[key];
      if (nested is List) {
        return _maps(nested);
      }
      if (nested is Map) {
        final List<Map<String, dynamic>> nestedList = _projectRecords(nested);
        if (nestedList.isNotEmpty) {
          return nestedList;
        }
      }
    }
  }
  return _records(data);
}

List<Map<String, dynamic>> _records(
  dynamic data, {
  List<String> listKeys = const <String>[
    'data',
    'result',
    'content',
    'items',
    'list',
    'rows',
    'aaData',
  ],
}) {
  if (data is List) {
    return _maps(data);
  }
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    for (final String key in listKeys) {
      final Object? nested = map[key];
      if (nested is List) {
        return _maps(nested);
      }
    }
    if (_looksLikeOption(map) || _looksLikeProject(map)) {
      return <Map<String, dynamic>>[map];
    }
  }
  return const <Map<String, dynamic>>[];
}

bool _looksLikeOption(Map<String, dynamic> map) {
  return map.containsKey('project_type_id') ||
      map.containsKey('project_type_name') ||
      map.containsKey('railway_zone') ||
      map.containsKey('railway_id') ||
      map.containsKey('financial_year') ||
      map.containsKey('division_id') ||
      map.containsKey('section_id') ||
      map.containsKey('division_name') ||
      map.containsKey('section_name');
}

bool _looksLikeProject(Map<String, dynamic> map) {
  return map.containsKey('project_id') || map.containsKey('project_name');
}

List<Map<String, dynamic>> _maps(List<dynamic> raw) {
  final List<Map<String, dynamic>> maps = <Map<String, dynamic>>[];
  for (final Object? item in raw) {
    if (item is Map) {
      maps.add(Map<String, dynamic>.from(item));
    } else if (item is String && item.trim().isNotEmpty) {
      maps.add(<String, dynamic>{'value': item.trim(), 'label': item.trim()});
    }
  }
  return maps;
}

List<String> _stringList(dynamic raw) {
  if (raw is! List) {
    return const <String>[];
  }
  return raw
      .map((Object? item) => _display(item))
      .where((String value) => value.isNotEmpty)
      .toList(growable: false);
}

List<String?> _nullableStringList(dynamic raw) {
  if (raw is! List) {
    return const <String?>[];
  }
  return raw.map<String?>((Object? item) {
    if (item == null) {
      return null;
    }
    final String text = _display(item);
    return text.isEmpty ? null : text;
  }).toList(growable: false);
}

String? _nullableDate(dynamic raw) {
  if (raw == null) {
    return null;
  }
  final String formatted = _formatDate(raw);
  return formatted.isEmpty ? null : formatted;
}

String? _nullableText(dynamic raw) {
  if (raw == null) {
    return null;
  }
  final String text = _display(raw);
  return text.isEmpty ? null : text;
}

String _first(Map<String, dynamic> json, List<String> keys) {
  for (final String key in keys) {
    final String text = _display(json[key]);
    if (text.isNotEmpty) {
      return text;
    }
  }
  return '';
}

String _display(dynamic value) {
  if (value == null) {
    return '';
  }
  if (value is String) {
    return value.trim();
  }
  if (value is num || value is bool) {
    return value.toString();
  }
  return value.toString().trim();
}

String? _text(dynamic value) {
  final String text = _display(value);
  return text.isEmpty ? null : text;
}

String _formatDate(dynamic value) {
  if (value == null) {
    return '';
  }
  if (value is DateTime) {
    return formatProjectApiDate(value);
  }
  final String text = _display(value);
  if (text.isEmpty) {
    return '';
  }
  final DateTime? parsed = parseProjectFormDate(text);
  if (parsed != null) {
    return formatProjectApiDate(parsed);
  }
  return text;
}
