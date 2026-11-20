class ActivitiesExportProject {
  const ActivitiesExportProject({
    required this.projectId,
    required this.projectName,
  });

  final String projectId;
  final String projectName;

  String get label {
    final String name = projectName.trim();
    if (name.isEmpty) {
      return projectId;
    }
    return name;
  }

  factory ActivitiesExportProject.fromJson(Map<String, dynamic> json) {
    return ActivitiesExportProject(
      projectId: _text(json['project_id']),
      projectName: _text(json['project_name']),
    );
  }
}

class ActivitiesExportContract {
  const ActivitiesExportContract({
    required this.contractId,
    required this.contractName,
    required this.projectId,
    required this.projectName,
  });

  final String contractId;
  final String contractName;
  final String projectId;
  final String projectName;

  String get label {
    final String name = contractName.trim();
    if (name.isEmpty) {
      return contractId;
    }
    return name;
  }

  factory ActivitiesExportContract.fromJson(Map<String, dynamic> json) {
    return ActivitiesExportContract(
      contractId: _firstText(json, const <String>[
        'contract_id_fk',
        'contract_id',
      ]),
      contractName: _firstText(json, const <String>[
        'contract_short_name',
        'contract_name',
      ]),
      projectId: _firstText(json, const <String>[
        'project_id_fk',
        'project_id',
      ]),
      projectName: _text(json['project_name']),
    );
  }
}

bool isActivitiesExportReport({
  required String formId,
  required String formName,
  required String webFormUrl,
}) {
  final String url = webFormUrl.trim().toLowerCase();
  // Exclude sibling Progress Report downloads that share the activities-export
  // API prefix (TPC / Station Improvements).
  if (url.contains('tpc-status') || url.contains('station-improvement')) {
    return false;
  }
  if (url.contains('activities-export')) {
    return true;
  }
  if (formId.trim() == '1319') {
    return true;
  }
  final String name = formName.trim().toLowerCase();
  return name.contains('contract-wise activit') ||
      name.contains('activities export');
}

List<ActivitiesExportProject> parseActivitiesExportProjects(Object? data) {
  return _asMaps(data)
      .map(ActivitiesExportProject.fromJson)
      .where((ActivitiesExportProject item) => item.projectId.isNotEmpty)
      .toList(growable: false);
}

List<ActivitiesExportContract> parseActivitiesExportContracts(Object? data) {
  return _asMaps(data)
      .map(ActivitiesExportContract.fromJson)
      .where((ActivitiesExportContract item) => item.contractId.isNotEmpty)
      .toList(growable: false);
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
      'projects',
      'contracts',
    ]) {
      final Object? nested = map[key];
      if (nested is List || nested is Map) {
        return _asMaps(nested);
      }
    }
    if (_text(map['project_id']).isNotEmpty ||
        _text(map['contract_id_fk']).isNotEmpty ||
        _text(map['contract_id']).isNotEmpty) {
      return <Map<String, dynamic>>[map];
    }
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
