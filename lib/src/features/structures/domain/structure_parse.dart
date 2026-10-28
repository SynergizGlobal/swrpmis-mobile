import 'package:swr_pmis_mobile/src/features/structures/domain/structure_form.dart';
import 'package:swr_pmis_mobile/src/features/structures/domain/structure_list.dart';

List<StructureSummaryRow> parseStructureSummaries(dynamic data) {
  final List<StructureSummaryRow> rows = <StructureSummaryRow>[];
  for (final Map<String, dynamic> json in _maps(data)) {
    final String projectId = _first(json, const <String>[
      'projectId',
      'project_id',
      'project',
    ]);
    if (projectId.isEmpty) {
      continue;
    }
    final List<StructureTypeCount> types = <StructureTypeCount>[];
    final dynamic rawTypes =
        json['structureTypes'] ?? json['structure_types'] ?? json['types'];
    for (final Map<String, dynamic> typeJson in _maps(rawTypes)) {
      final String type = _first(typeJson, const <String>[
        'structureType',
        'structure_type',
        'type',
        'name',
      ]);
      final int count = _int(
        typeJson['count'] ?? typeJson['structureCount'] ?? typeJson['total'],
      );
      if (type.isEmpty && count == 0) {
        continue;
      }
      types.add(StructureTypeCount(structureType: type, count: count));
    }
    rows.add(
      StructureSummaryRow(projectId: projectId, structureTypes: types),
    );
  }
  return rows;
}

List<StructureProjectOption> parseStructureProjects(dynamic data) {
  final List<StructureProjectOption> out = <StructureProjectOption>[];
  for (final Map<String, dynamic> json in _maps(
    data,
    listKeys: const <String>[
      'projects',
      'projectList',
      'data',
      'result',
      'items',
    ],
  )) {
    final String id = _first(json, const <String>[
      'project_id',
      'projectId',
      'id',
      'value',
    ]);
    final String name = _first(json, const <String>[
      'project_name',
      'projectName',
      'name',
      'label',
    ]);
    if (id.isEmpty && name.isEmpty) {
      continue;
    }
    out.add(
      StructureProjectOption(
        projectId: id.isEmpty ? name : id,
        projectName: name,
      ),
    );
  }
  return out;
}

List<String> parseStructureTypeNames(dynamic data) {
  if (data is List) {
    final List<String> out = <String>[];
    for (final dynamic item in data) {
      if (item is String) {
        final String text = item.trim();
        if (text.isNotEmpty) {
          out.add(text);
        }
        continue;
      }
      if (item is Map) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(item);
        final String name = _first(map, const <String>[
          'structureType',
          'structure_type',
          'type',
          'name',
          'label',
          'value',
        ]);
        if (name.isNotEmpty) {
          out.add(name);
        }
      }
    }
    return out;
  }
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    for (final String key in const <String>[
      'types',
      'structureTypes',
      'data',
      'result',
    ]) {
      if (map.containsKey(key)) {
        return parseStructureTypeNames(map[key]);
      }
    }
  }
  return const <String>[];
}

StructureProjectChainage parseStructureProjectChainage(dynamic data) {
  if (data is! Map) {
    return StructureProjectChainage.empty;
  }
  final Map<String, dynamic> map = Map<String, dynamic>.from(data);
  return StructureProjectChainage(
    fromChainage: _doubleOrNull(
      map['fromChainage'] ?? map['from_chainage'] ?? map['from'],
    ),
    toChainage: _doubleOrNull(
      map['toChainage'] ?? map['to_chainage'] ?? map['to'],
    ),
  );
}

StructureFullDetail parseStructureFullDetail(dynamic data) {
  if (data is! Map) {
    return StructureFullDetail.empty;
  }
  final Map<String, dynamic> map = Map<String, dynamic>.from(data);
  final String projectId = _first(map, const <String>[
    'projectId',
    'project_id',
    'project',
  ]);
  final String projectName = _first(map, const <String>[
    'projectName',
    'project_name',
    'name',
  ]);
  final List<StructureTypeGroupDraft> groups = <StructureTypeGroupDraft>[];
  final dynamic rawTypes =
      map['structureTypes'] ?? map['structure_types'] ?? map['types'];
  for (final Map<String, dynamic> typeJson in _maps(rawTypes)) {
    final String type = _first(typeJson, const <String>[
      'type',
      'structureType',
      'structure_type',
      'name',
    ]);
    final List<StructureRowDraft> rows = <StructureRowDraft>[];
    final dynamic rawRows = typeJson['rows'] ?? typeJson['structures'];
    for (final Map<String, dynamic> rowJson in _maps(rawRows)) {
      rows.add(
        StructureRowDraft(
          structureId: _first(rowJson, const <String>[
            'structureId',
            'structure_id',
            'id',
          ]),
          structure: _first(rowJson, const <String>[
            'structure',
            'structureCode',
            'structure_code',
          ]),
          structureName: _first(rowJson, const <String>[
            'structureName',
            'structure_name',
            'name',
          ]),
          structureDetails: _first(rowJson, const <String>[
            'structureDetails',
            'structure_details',
            'details',
          ]),
          fromChainage: _chainageText(
            rowJson['fromChainage'] ?? rowJson['from_chainage'],
          ),
          toChainage: _chainageText(
            rowJson['toChainage'] ?? rowJson['to_chainage'],
          ),
        ),
      );
    }
    groups.add(
      StructureTypeGroupDraft(
        type: type,
        rows: rows.isEmpty ? const <StructureRowDraft>[StructureRowDraft()] : rows,
      ),
    );
  }
  return StructureFullDetail(
    projectId: projectId,
    projectName: projectName,
    structureTypes: groups,
  );
}

String? structureApiMessage(dynamic data) {
  if (data == null) {
    return null;
  }
  if (data is String) {
    final String text = data.trim();
    return text.isEmpty ? null : text;
  }
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    for (final String key in const <String>[
      'message',
      'error',
      'Error',
      'msg',
      'detail',
      'title',
    ]) {
      final String? text = _text(map[key]);
      if (text != null && text.isNotEmpty) {
        return text;
      }
    }
  }
  return null;
}

String parseStructureSaveMessage(dynamic data, {required String fallback}) {
  final String? message = structureApiMessage(data);
  if (message == null || message.isEmpty) {
    return fallback;
  }
  final String lower = message.toLowerCase();
  if (lower.contains('not found') ||
      lower.contains('error') ||
      lower.contains('fail') ||
      lower.contains('invalid')) {
    final bool looksSuccess =
        lower == 'success' ||
        lower.startsWith('success') ||
        lower.contains('saved') ||
        lower.contains('updated');
    if (!looksSuccess) {
      throw StateError(message);
    }
  }
  return message;
}

String _chainageText(dynamic value) {
  if (value == null) {
    return '';
  }
  if (value is num) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }
  return value.toString().trim();
}

double? _doubleOrNull(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  final String text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }
  return double.tryParse(text);
}

int _int(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return int.tryParse(value?.toString().trim() ?? '') ?? 0;
}

String? _text(dynamic value) {
  if (value == null) {
    return null;
  }
  final String text = value.toString().trim();
  return text.isEmpty ? null : text;
}

String _first(Map<String, dynamic> json, List<String> keys) {
  for (final String key in keys) {
    final String? text = _text(json[key]);
    if (text != null) {
      return text;
    }
  }
  return '';
}

Iterable<Map<String, dynamic>> _maps(
  dynamic data, {
  List<String> listKeys = const <String>['data', 'result', 'items', 'aaData'],
}) sync* {
  if (data == null) {
    return;
  }
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
    for (final String key in listKeys) {
      if (map.containsKey(key)) {
        yield* _maps(map[key], listKeys: listKeys);
        return;
      }
    }
    yield map;
  }
}
