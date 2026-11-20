class ContractDetailOption {
  const ContractDetailOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

bool isContractDetailReport({
  required String formId,
  required String formName,
  required String webFormUrl,
}) {
  final String id = formId.trim();
  if (id == '282') {
    return true;
  }
  final String url = webFormUrl.trim().toLowerCase();
  if (url.contains('contract-detail') ||
      url.contains('generate-contract-detail')) {
    return true;
  }
  final String name = formName.trim().toLowerCase();
  return name == 'contract detail' || name == 'contract detail report';
}

List<ContractDetailOption> parseContractDetailProjects(Object? data) {
  return _parseOptions(
    data,
    idKeys: const <String>['project_id', 'project_id_fk', 'id'],
    labelKeys: const <String>['project_name', 'name', 'work_name'],
  );
}

List<ContractDetailOption> parseContractDetailContracts(Object? data) {
  return _parseOptions(
    data,
    idKeys: const <String>['contract_id', 'contract_id_fk', 'id'],
    labelKeys: const <String>[
      'contract_short_name',
      'contract_name',
      'name',
      'contract_id',
    ],
  );
}

List<ContractDetailOption> parseContractDetailContractors(Object? data) {
  return _parseOptions(
    data,
    idKeys: const <String>[
      'contractor_id_fk',
      'contractor_id',
      'id',
    ],
    labelKeys: const <String>['contractor_name', 'name'],
  );
}

List<ContractDetailOption> parseContractDetailHods(Object? data) {
  return _parseOptions(
    data,
    idKeys: const <String>[
      'designation',
      'hod_designation',
      'hod_user_id_fk',
      'user_id',
      'id',
    ],
    labelKeys: const <String>[
      'user_name',
      'designation',
      'hod_designation',
      'name',
    ],
    preferIdAsValue: true,
  );
}

/// Status of Work on the web form maps to `contract_status_fk` on generate.
List<ContractDetailOption> parseContractDetailStatuses(Object? data) {
  return _parseOptions(
    data,
    idKeys: const <String>[
      'contract_status_fk',
      'contract_status',
      'status',
      'id',
      'name',
    ],
    labelKeys: const <String>[
      'contract_status_fk',
      'contract_status',
      'status',
      'name',
    ],
  );
}

List<ContractDetailOption> _parseOptions(
  Object? data, {
  required List<String> idKeys,
  required List<String> labelKeys,
  bool preferIdAsValue = false,
}) {
  final List<ContractDetailOption> out = <ContractDetailOption>[];
  final Set<String> seen = <String>{};
  for (final Map<String, dynamic> map in _asMaps(data)) {
    final String id = _firstText(map, idKeys);
    if (id.isEmpty || !seen.add(id)) {
      continue;
    }
    final String label = _firstText(map, labelKeys);
    out.add(
      ContractDetailOption(
        id: id,
        label: label.isEmpty ? id : (preferIdAsValue ? _hodLabel(map, id) : label),
      ),
    );
  }
  return out;
}

String _hodLabel(Map<String, dynamic> map, String id) {
  final String name = _text(map['user_name']);
  final String designation = _text(map['designation']);
  if (name.isNotEmpty && designation.isNotEmpty && name != designation) {
    return '$name ($designation)';
  }
  if (name.isNotEmpty) {
    return name;
  }
  if (designation.isNotEmpty) {
    return designation;
  }
  return id;
}

List<Map<String, dynamic>> _asMaps(Object? data) {
  if (data is List) {
    return data
        .whereType<Map>()
        .map((Map item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    for (final String key in const <String>[
      'data',
      'result',
      'content',
      'list',
      'records',
    ]) {
      final Object? nested = map[key];
      if (nested is List || nested is Map) {
        return _asMaps(nested);
      }
    }
    return <Map<String, dynamic>>[map];
  }
  return const <Map<String, dynamic>>[];
}

String _firstText(Map<String, dynamic> json, List<String> keys) {
  for (final String key in keys) {
    final String value = _text(json[key]);
    if (value.isNotEmpty) {
      return value;
    }
  }
  return '';
}

String _text(Object? value) {
  if (value == null) {
    return '';
  }
  return '$value'.trim();
}
