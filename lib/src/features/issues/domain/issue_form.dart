class IssueFormOption {
  const IssueFormOption({required this.id, required this.label, this.raw});

  final String id;
  final String label;
  final Map<String, dynamic>? raw;
}

List<IssueFormOption> issueFormProjects(dynamic data) {
  return _fromMaps(
    _rows(data, const <String>['projectsList', 'projectList']),
    idKeys: const <String>['project_id_fk', 'project_id', 'projectId'],
    labelKeys: const <String>['project_name', 'projectName', 'name'],
  );
}

List<IssueFormOption> issueFormPriorities(dynamic data) {
  return _fromMaps(
    _rows(data, const <String>['issuesPriorityList', 'priorityList']),
    idKeys: const <String>['priority_fk', 'priority', 'id'],
    labelKeys: const <String>['priority', 'priority_name', 'name'],
  );
}

List<IssueFormOption> issueFormRailways(dynamic data) {
  return _railways(
    _rows(data, const <String>[
      'railwayList',
      'railway_list',
      'railways',
      'railway_name',
    ]),
  );
}

List<IssueFormOption> issueFormOtherOrganizations(dynamic data) {
  return _otherOrganizations(
    _rows(data, const <String>[
      'other_organization',
      'other_organizations',
      'otherOrganizations',
      'otherOrganizationList',
      'other_organization_list',
    ]),
  );
}

List<IssueFormOption> issueFormContracts(dynamic data) {
  final List<IssueFormOption> options = <IssueFormOption>[];
  final Set<String> seen = <String>{};
  for (final dynamic row in _rows(data, const <String>[
    'contractsList',
    'contractList',
    'contracts',
    'data',
  ])) {
    if (row is! Map) {
      continue;
    }
    final Map<String, dynamic> json = _map(row);
    final String id = _pick(json, const <String>[
      'contract_id_fk',
      'contract_id',
    ]);
    if (id.isEmpty || !seen.add(id)) {
      continue;
    }
    final String label = _pick(json, const <String>[
      'contract_short_name',
      'contract_name',
      'contract_code',
    ]);
    options.add(
      IssueFormOption(id: id, label: label.isEmpty ? id : label, raw: json),
    );
  }
  return options;
}

List<IssueFormOption> issueFormCategories(dynamic data) {
  final List<IssueFormOption> options = <IssueFormOption>[];
  final Set<String> seen = <String>{};
  for (final dynamic row in _rows(data, const <String>[
    'categoryList',
    'categories',
    'data',
  ])) {
    if (row is! Map) {
      continue;
    }
    final Map<String, dynamic> json = _map(row);
    String id = _pick(json, const <String>['category_fk', 'category_id', 'id']);
    if (id.isEmpty) {
      final String category = _pick(json, const <String>['category']);
      final String related = _pick(json, const <String>['issues_related_to']);
      id = related.isNotEmpty ? '$category|$related' : category;
    }
    if (id.isEmpty || !seen.add(id)) {
      continue;
    }
    final String category = _pick(json, const <String>['category']);
    final String related = _pick(json, const <String>['issues_related_to']);
    final String label = related.isNotEmpty ? '$category — $related' : category;
    options.add(
      IssueFormOption(
        id: id,
        label: label.isEmpty ? id : label,
        raw: json,
      ),
    );
  }
  return options;
}

List<IssueFormOption> issueFormTitles(dynamic data) {
  final List<IssueFormOption> options = <IssueFormOption>[];
  final Set<String> seen = <String>{};
  for (final dynamic row in _rows(data, const <String>[
    'titlesList',
    'titleList',
    'titles',
    'data',
  ])) {
    if (row is! Map) {
      continue;
    }
    final Map<String, dynamic> json = _map(row);
    String id = _pick(json, const <String>[
      'issue_title_fk',
      'title_fk',
      'short_description_fk',
      'id',
    ]);
    if (id.isEmpty) {
      id = _pick(json, const <String>[
        'short_description',
        'title',
        'description',
      ]);
    }
    if (id.isEmpty || !seen.add(id)) {
      continue;
    }
    final String label = _pick(json, const <String>[
      'short_description',
      'title',
      'description',
    ]);
    options.add(
      IssueFormOption(
        id: id,
        label: label.isEmpty ? id : label,
        raw: json,
      ),
    );
  }
  return options;
}

List<IssueFormOption> issueFormStructures(dynamic data) {
  return _fieldOptions(
    _rows(data, const <String>[
      'structure',
      'structures',
      'structureList',
      'structure_list',
      'data',
    ]),
    'structure',
  );
}

List<IssueFormOption> issueFormComponents(dynamic data) {
  return _fieldOptions(
    _rows(data, const <String>[
      'component',
      'components',
      'componentList',
      'component_list',
      'data',
    ]),
    'component',
  );
}

String issueCategoryFk(IssueFormOption option) {
  final String fromRaw = _pick(
    option.raw ?? const <String, dynamic>{},
    const <String>['category_fk', 'category'],
  );
  if (fromRaw.isNotEmpty) {
    return fromRaw;
  }
  final String id = option.id;
  if (id.contains('|')) {
    return id.split('|').first;
  }
  return id;
}

String issueZonalRailwayFk(IssueFormOption option) {
  final String fromRaw = _pick(
    option.raw ?? const <String, dynamic>{},
    const <String>[
      'zonal_railway_fk',
      'railway_id',
      'railway_fk',
      'railway_id_fk',
    ],
  );
  if (fromRaw.isNotEmpty) {
    return fromRaw;
  }
  return option.id;
}

String issueContractTypeFk(IssueFormOption option) {
  return _pick(
    option.raw ?? const <String, dynamic>{},
    const <String>['contract_type_fk'],
  );
}

List<IssueFormOption> _fromMaps(
  List<dynamic> rows, {
  required List<String> idKeys,
  required List<String> labelKeys,
}) {
  final List<IssueFormOption> options = <IssueFormOption>[];
  final Set<String> seen = <String>{};
  for (final dynamic row in rows) {
    if (row is! Map) {
      continue;
    }
    final Map<String, dynamic> json = _map(row);
    final String id = _pick(json, idKeys);
    if (id.isEmpty || !seen.add(id)) {
      continue;
    }
    final StringBuffer buffer = StringBuffer();
    for (final String key in labelKeys) {
      final String bit = _pick(json, <String>[key]);
      if (bit.isEmpty) {
        continue;
      }
      if (buffer.isEmpty) {
        buffer.write(bit);
      } else if (!buffer.toString().contains(bit)) {
        buffer.write(' — ');
        buffer.write(bit);
      }
    }
    final String label = buffer.toString();
    options.add(
      IssueFormOption(id: id, label: label.isEmpty ? id : label, raw: json),
    );
  }
  return options;
}

List<IssueFormOption> _fieldOptions(List<dynamic> rows, String field) {
  final List<IssueFormOption> options = <IssueFormOption>[];
  final Set<String> seen = <String>{};
  for (final dynamic row in rows) {
    if (row is String) {
      final String value = row.trim();
      if (value.isEmpty || value.toLowerCase() == 'null' || !seen.add(value)) {
        continue;
      }
      options.add(IssueFormOption(id: value, label: value));
      continue;
    }
    if (row is! Map) {
      continue;
    }
    final Map<String, dynamic> json = _map(row);
    final String value = _pick(json, <String>[field, '${field}_name']);
    if (value.isEmpty || !seen.add(value)) {
      continue;
    }
    options.add(IssueFormOption(id: value, label: value, raw: json));
  }
  return options;
}

List<IssueFormOption> _railways(List<dynamic> rows) {
  final List<IssueFormOption> options = <IssueFormOption>[];
  final Set<String> seen = <String>{};
  for (final dynamic row in rows) {
    if (row is String) {
      final String value = row.trim();
      if (value.isEmpty || !seen.add(value)) {
        continue;
      }
      options.add(IssueFormOption(id: value, label: value));
      continue;
    }
    if (row is! Map) {
      continue;
    }
    final Map<String, dynamic> json = _map(row);
    final String label = _pick(json, const <String>[
      'railway_name',
      'railway',
      'name',
      'railway_full_name',
    ]);
    String id = _pick(json, const <String>[
      'railway_id',
      'railway_id_fk',
      'railway_fk',
      'zonal_railway_fk',
      'zonal_railway',
      'id',
    ]);
    if (id.isEmpty) {
      id = label;
    }
    if (id.isEmpty || !seen.add(id)) {
      continue;
    }
    options.add(
      IssueFormOption(id: id, label: label.isEmpty ? id : label, raw: json),
    );
  }
  return options;
}

List<IssueFormOption> _otherOrganizations(List<dynamic> rows) {
  final List<IssueFormOption> options = <IssueFormOption>[];
  final Set<String> seen = <String>{};
  for (final dynamic row in rows) {
    if (row is String) {
      final String value = row.trim();
      if (value.isEmpty || !seen.add(value)) {
        continue;
      }
      options.add(IssueFormOption(id: value, label: value));
      continue;
    }
    if (row is! Map) {
      continue;
    }
    final Map<String, dynamic> json = _map(row);
    final String label = _pick(json, const <String>[
      'other_organization',
      'other_org_name',
      'organization_name',
      'name',
    ]);
    String id = _pick(json, const <String>[
      'other_organization_fk',
      'organization_fk',
      'other_org_fk',
      'id',
    ]);
    if (id.isEmpty) {
      id = label;
    }
    if (id.isEmpty || !seen.add(id)) {
      continue;
    }
    options.add(
      IssueFormOption(id: id, label: label.isEmpty ? id : label, raw: json),
    );
  }
  return options;
}

List<dynamic> _rows(dynamic data, List<String> keys) {
  if (data is List) {
    return data;
  }
  if (data is! Map) {
    return const <dynamic>[];
  }
  final Map<String, dynamic> merged = _root(_map(data));
  for (final String key in keys) {
    final dynamic value = merged[key];
    if (value is List && value.isNotEmpty) {
      return value;
    }
  }
  for (final MapEntry<String, dynamic> entry in merged.entries) {
    final dynamic value = entry.value;
    if (value is! List || value.isEmpty) {
      continue;
    }
    final String name = entry.key.toLowerCase();
    for (final String key in keys) {
      if (name == key.toLowerCase()) {
        return value;
      }
    }
  }
  for (final dynamic value in merged.values) {
    if (value is List && value.isNotEmpty) {
      return value;
    }
  }
  return const <dynamic>[];
}

Map<String, dynamic> _root(Map<String, dynamic> root) {
  final Map<String, dynamic> merged = Map<String, dynamic>.from(root);
  for (final String key in const <String>['data', 'model', 'result', 'body']) {
    final dynamic node = merged[key];
    if (node is! Map) {
      continue;
    }
    _map(node).forEach((String childKey, dynamic value) {
      merged.putIfAbsent(childKey, () => value);
    });
  }
  return merged;
}

Map<String, dynamic> _map(dynamic data) {
  final Map<Object?, Object?> source = data as Map<Object?, Object?>;
  return Map<String, dynamic>.fromEntries(
    source.entries.map(
      (MapEntry<Object?, Object?> entry) =>
          MapEntry<String, dynamic>(entry.key.toString(), entry.value),
    ),
  );
}

String _pick(Map<String, dynamic> json, List<String> keys) {
  for (final String key in keys) {
    final dynamic value = json[key];
    final String text = value?.toString().trim() ?? '';
    if (text.isNotEmpty && text.toLowerCase() != 'null') {
      return text;
    }
  }
  return '';
}
