import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_filter_option.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_validation_row.dart';

class RfiValidationCatalog {
  const RfiValidationCatalog({
    this.categories = const <RfiFilterOption>[],
    this.projects = const <RfiFilterOption>[],
    this.contracts = const <RfiFilterOption>[],
    this.rows = const <RfiValidationRow>[],
  });

  final List<RfiFilterOption> categories;
  final List<RfiFilterOption> projects;
  final List<RfiFilterOption> contracts;
  final List<RfiValidationRow> rows;

  factory RfiValidationCatalog.fromResponses({
    required dynamic categories,
    required dynamic projects,
    required dynamic contracts,
    required dynamic projectList,
    required dynamic validations,
  }) {
    final List<RfiValidationRow> rows = parseRfiValidationRows(validations);
    final List<RfiFilterOption> categoryOptions = parseRfiValidationOptions(
      categories,
      idKeys: const <String>[
        'rfiCategory',
        'category',
        'name',
        'label',
        'value',
        'id',
      ],
      labelKeys: const <String>[
        'rfiCategory',
        'category',
        'name',
        'label',
        'value',
      ],
    );
    final List<RfiFilterOption> projectOptions = parseRfiValidationOptions(
      projects,
      idKeys: const <String>['projectId', 'project_id', 'id', 'value'],
      labelKeys: const <String>[
        'projectName',
        'project_name',
        'name',
        'label',
        'title',
      ],
    );
    return RfiValidationCatalog(
      categories: categoryOptions.isNotEmpty
          ? categoryOptions
          : _categoriesFromRows(rows),
      projects: projectOptions.isNotEmpty
          ? projectOptions
          : parseRfiValidationOptions(
              projectList,
              idKeys: const <String>['projectId', 'project_id', 'id', 'value'],
              labelKeys: const <String>[
                'projectName',
                'project_name',
                'name',
                'label',
                'title',
              ],
            ),
      contracts: parseRfiValidationOptions(
        contracts,
        idKeys: const <String>['contractId', 'contract_id', 'id', 'value'],
        labelKeys: const <String>[
          'contractName',
          'contract_name',
          'name',
          'label',
          'title',
        ],
      ),
      rows: rows,
    );
  }
}

List<RfiFilterOption> parseRfiValidationOptions(
  dynamic data, {
  required List<String> idKeys,
  required List<String> labelKeys,
}) {
  final List<RfiFilterOption> options = <RfiFilterOption>[];
  final Set<String> seen = <String>{};
  for (final dynamic item in _items(data)) {
    final String? id;
    final String? label;
    if (item is String || item is num) {
      id = _clean(item);
      label = id;
    } else if (item is Map) {
      final Map<String, dynamic> json = Map<String, dynamic>.from(item);
      id = _first(json, idKeys) ?? _first(json, labelKeys);
      label = _first(json, labelKeys) ?? id;
    } else {
      continue;
    }
    if (id == null || label == null || !seen.add(id)) {
      continue;
    }
    options.add(RfiFilterOption(id: id, label: label));
  }
  return options;
}

List<RfiFilterOption> _categoriesFromRows(List<RfiValidationRow> rows) {
  final List<RfiFilterOption> options = <RfiFilterOption>[];
  final Set<String> seen = <String>{};
  for (final RfiValidationRow row in rows) {
    final String? category = row.rfiCategory?.trim();
    if (category == null || category.isEmpty || !seen.add(category)) {
      continue;
    }
    options.add(RfiFilterOption(id: category, label: category));
  }
  return options;
}

List<dynamic> _items(dynamic data, [int depth = 0]) {
  if (data == null) {
    return const <dynamic>[];
  }
  if (data is List) {
    return data;
  }
  if (data is String || data is num) {
    return <dynamic>[data];
  }
  if (data is Map && depth < 3) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    for (final String key in _wrapperKeys) {
      final Object? nested = map[key];
      if (nested is List) {
        return nested;
      }
    }
    for (final String key in _wrapperKeys) {
      final Object? nested = map[key];
      if (nested is Map || nested is String || nested is num) {
        return _items(nested, depth + 1);
      }
    }
    return <dynamic>[map];
  }
  return const <dynamic>[];
}

const List<String> _wrapperKeys = <String>[
  'data',
  'result',
  'content',
  'list',
  'records',
  'projects',
  'contracts',
  'categories',
];

String? _first(Map<String, dynamic> json, List<String> keys) {
  for (final String key in keys) {
    final String? text = _clean(json[key]);
    if (text != null) {
      return text;
    }
  }
  return null;
}

String? _clean(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num && value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  final String text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }
  return text;
}
