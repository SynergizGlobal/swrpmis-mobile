import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';

/// Reports → Land Acquisition (formId 1316 / la-report).
///
/// UI title: "Land Acquisition Report".
bool isLandAcquisitionReport({
  required String formId,
  required String formName,
  required String webFormUrl,
}) {
  final String id = formId.trim();
  if (id == '1316') {
    return true;
  }

  final String url = webFormUrl.trim().toLowerCase();
  if (url.contains('la-report') ||
      url.contains('land-report') ||
      url.contains('/api/land-report')) {
    return true;
  }

  final String name = formName.trim().toLowerCase();
  return name.contains('land acquisition');
}

/// Projects from `GET /api/land-report/project-list`.
List<ContractDetailOption> parseLandAcquisitionProjects(Object? data) {
  return _parseOptions(
    data,
    idKeys: const <String>['project_id', 'project_id_fk', 'id', 'value'],
    labelKeys: const <String>['project_name', 'name', 'label'],
  );
}

/// Type Of Land from `GET /api/land-report/type-list` (`category_fk`).
List<ContractDetailOption> parseLandAcquisitionTypes(Object? data) {
  return _parseOptions(
    data,
    idKeys: const <String>['category_fk', 'category', 'id', 'value'],
    labelKeys: const <String>[
      'category_fk',
      'category',
      'category_name',
      'label',
      'name',
    ],
  );
}

/// Sub Category from `GET /api/land-report/sub-category-list`.
List<ContractDetailOption> parseLandAcquisitionSubCategories(Object? data) {
  return _parseOptions(
    data,
    idKeys: const <String>[
      'la_sub_category_fk',
      'sub_category_fk',
      'id',
      'value',
    ],
    labelKeys: const <String>[
      'la_sub_category',
      'sub_category',
      'label',
      'name',
    ],
  );
}

/// Query params for project-list (omit empty).
Map<String, dynamic> buildLandAcquisitionProjectListQuery({
  String categoryFk = '',
}) {
  return _optionalQuery(<String, String>{
    'category_fk': categoryFk,
  });
}

/// Query params for type-list (omit empty).
Map<String, dynamic> buildLandAcquisitionTypeListQuery({
  String projectId = '',
}) {
  return _optionalQuery(<String, String>{
    'project_id_fk': projectId,
  });
}

/// Query params for sub-category-list (omit empty).
Map<String, dynamic> buildLandAcquisitionSubCategoryListQuery({
  String projectId = '',
  String categoryFk = '',
}) {
  return _optionalQuery(<String, String>{
    'project_id_fk': projectId,
    'category_fk': categoryFk,
  });
}

/// POST `/api/land-report/generate` body.
Map<String, dynamic> buildLandAcquisitionGenerateBody({
  required String projectId,
  required String categoryFk,
  required String subCategoryFk,
}) {
  return <String, dynamic>{
    'project_id_fk': projectId.trim(),
    'category_fk': categoryFk.trim(),
    'la_sub_category_fk': subCategoryFk.trim(),
  };
}

Map<String, dynamic> _optionalQuery(Map<String, String> raw) {
  final Map<String, dynamic> out = <String, dynamic>{};
  raw.forEach((String key, String value) {
    final String trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      out[key] = trimmed;
    }
  });
  return out;
}

List<ContractDetailOption> _parseOptions(
  Object? data, {
  required List<String> idKeys,
  required List<String> labelKeys,
}) {
  final List<ContractDetailOption> out = <ContractDetailOption>[];
  final Set<String> seen = <String>{};
  for (final Map<String, dynamic> map in _asMaps(data)) {
    final String id = _firstText(map, idKeys);
    if (id.isEmpty || !seen.add(id)) {
      continue;
    }
    final String label = _firstText(map, labelKeys);
    out.add(ContractDetailOption(id: id, label: label.isEmpty ? id : label));
  }
  return out;
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
      'options',
    ]) {
      final Object? nested = map[key];
      if (nested is List || nested is Map) {
        return _asMaps(nested);
      }
    }
    if (_firstText(map, const <String>[
      'project_id',
      'project_id_fk',
      'project_name',
      'category_fk',
      'la_sub_category_fk',
      'la_sub_category',
      'id',
      'name',
    ]).isNotEmpty) {
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
  final String text = '$value'.trim();
  if (text.toLowerCase() == 'null') {
    return '';
  }
  return text;
}
