class RfiAssignProject {
  const RfiAssignProject({required this.projectId, required this.projectName});

  final String projectId;
  final String projectName;

  String get label => projectName.isEmpty ? projectId : projectName;

  factory RfiAssignProject.fromJson(Map<String, dynamic> json) {
    return RfiAssignProject(
      projectId: _text(json['projectId']),
      projectName: _text(json['projectName']),
    );
  }
}

class RfiAssignContract {
  const RfiAssignContract({
    required this.contractIdFk,
    required this.contractShortName,
  });

  final String contractIdFk;
  final String contractShortName;

  String get label =>
      contractShortName.isEmpty ? contractIdFk : contractShortName;

  factory RfiAssignContract.fromJson(Map<String, dynamic> json) {
    return RfiAssignContract(
      contractIdFk: _text(json['contractIdFk']),
      contractShortName: _text(json['contractShortName']),
    );
  }
}

class RfiAssignExecutiveLog {
  const RfiAssignExecutiveLog({
    required this.id,
    required this.contract,
    required this.structureType,
    required this.structure,
    required this.assignedExecutive,
  });

  final int? id;
  final String contract;
  final String structureType;
  final String structure;
  final String assignedExecutive;

  factory RfiAssignExecutiveLog.fromJson(Map<String, dynamic> json) {
    return RfiAssignExecutiveLog(
      id: _int(json['id']),
      contract: _text(json['contract']),
      structureType: _text(json['structureType']),
      structure: _text(json['structure']),
      assignedExecutive: _text(json['assignedExecutive']),
    );
  }
}

List<RfiAssignProject> parseRfiAssignProjects(dynamic data) {
  return _dedupe(
    _maps(data, _isProject)
        .map(RfiAssignProject.fromJson)
        .where((RfiAssignProject item) => item.projectId.isNotEmpty)
        .toList(growable: false),
    (RfiAssignProject item) => item.projectId,
  );
}

List<RfiAssignContract> parseRfiAssignContracts(dynamic data) {
  return _dedupe(
    _maps(data, _isContract)
        .map(RfiAssignContract.fromJson)
        .where((RfiAssignContract item) => item.contractIdFk.isNotEmpty)
        .toList(growable: false),
    (RfiAssignContract item) => item.contractIdFk,
  );
}

List<RfiAssignExecutiveLog> parseRfiAssignExecutiveLogs(dynamic data) {
  return _maps(
    data,
    _isLog,
  ).map(RfiAssignExecutiveLog.fromJson).toList(growable: false);
}

List<T> _dedupe<T>(List<T> items, String Function(T item) id) {
  final Set<String> seen = <String>{};
  final List<T> result = <T>[];
  for (final T item in items) {
    if (seen.add(id(item))) {
      result.add(item);
    }
  }
  return result;
}

List<Map<String, dynamic>> _maps(
  dynamic data,
  bool Function(Map<String, dynamic> map) isRow,
) {
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
      if (nested is List) {
        return _maps(nested, isRow);
      }
      if (nested is Map) {
        final Map<String, dynamic> child = Map<String, dynamic>.from(nested);
        if (isRow(child)) {
          return <Map<String, dynamic>>[child];
        }
      }
    }
    if (isRow(map)) {
      return <Map<String, dynamic>>[map];
    }
  }
  return const <Map<String, dynamic>>[];
}

bool _isProject(Map<String, dynamic> map) {
  return map.containsKey('projectId') || map.containsKey('projectName');
}

bool _isContract(Map<String, dynamic> map) {
  return map.containsKey('contractIdFk') ||
      map.containsKey('contractShortName');
}

bool _isLog(Map<String, dynamic> map) {
  return map.containsKey('assignedExecutive') ||
      map.containsKey('structureType') ||
      map.containsKey('id');
}

String _text(Object? value) {
  if (value == null) {
    return '';
  }
  final String text = value.toString().trim();
  if (text.toLowerCase() == 'null') {
    return '';
  }
  return text;
}

int? _int(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    final String text = value.trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }
    return int.tryParse(text);
  }
  return null;
}
