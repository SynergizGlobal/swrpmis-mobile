import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';

/// Reports → Utility / Utility Shifting Report (formId 1317 / 1401).
///
/// UI title: "Utility Shifting Report".
/// Filter load: `GET /utility-report` (all four dropdowns in one response).
bool isUtilityShiftingReport({
  required String formId,
  required String formName,
  required String webFormUrl,
}) {
  final String id = formId.trim();
  if (id == '1317' || id == '1401') {
    return true;
  }

  final String url = webFormUrl.trim().toLowerCase();
  if (url.contains('utility-report') ||
      url.contains('utilityshiftingreport') ||
      url.contains('utility-shifting-report')) {
    return true;
  }

  final String name = formName.trim().toLowerCase();
  if (name.contains('utility shifting report') ||
      name == 'utility report' ||
      name == 'utility shifting') {
    return true;
  }
  return name.contains('utility') &&
      (name.contains('shifting') || name.contains('report'));
}

/// Snapshot of all filter option lists from `GET /utility-report`.
class UtilityShiftingReportFilters {
  const UtilityShiftingReportFilters({
    this.projects = const <ContractDetailOption>[],
    this.executionAgencies = const <ContractDetailOption>[],
    this.impactedContracts = const <ContractDetailOption>[],
    this.hods = const <ContractDetailOption>[],
  });

  static const UtilityShiftingReportFilters empty =
      UtilityShiftingReportFilters();

  final List<ContractDetailOption> projects;
  final List<ContractDetailOption> executionAgencies;
  final List<ContractDetailOption> impactedContracts;
  final List<ContractDetailOption> hods;
}

/// Parses the full `GET /utility-report` payload into four option lists.
UtilityShiftingReportFilters parseUtilityShiftingReportFilters(Object? data) {
  final Map<String, dynamic>? root = _asRootMap(data);
  if (root == null) {
    return UtilityShiftingReportFilters.empty;
  }
  return UtilityShiftingReportFilters(
    projects: parseUtilityShiftingProjects(
      _pickList(root, const <String>[
        'projectsList',
        'projects',
        'projectList',
      ]),
    ),
    executionAgencies: parseUtilityShiftingExecutionAgencies(
      _pickList(root, const <String>[
        'executionAgency',
        'executionAgencies',
        'execution_agency',
        'executionAgencyList',
      ]),
    ),
    impactedContracts: parseUtilityShiftingImpactedContracts(
      _pickList(root, const <String>[
        'impactedContractsList',
        'impactedContracts',
        'impacted_contracts',
        'contracts',
      ]),
    ),
    hods: parseUtilityShiftingHods(
      _pickList(root, const <String>[
        'utilityHODList',
        'utilityHodList',
        'hods',
        'hodList',
      ]),
    ),
  );
}

/// Projects: `project_id_fk`, `project_name` → label `P26 - {project_name}`.
List<ContractDetailOption> parseUtilityShiftingProjects(Object? data) {
  final List<ContractDetailOption> out = <ContractDetailOption>[];
  final Set<String> seen = <String>{};
  for (final Map<String, dynamic> map in _asMaps(data)) {
    final String id = _firstText(map, const <String>[
      'project_id_fk',
      'project_id',
      'id',
      'value',
    ]);
    if (id.isEmpty || !seen.add(id)) {
      continue;
    }
    final String name = _firstText(map, const <String>[
      'project_name',
      'name',
      'label',
    ]);
    out.add(
      ContractDetailOption(
        id: id,
        label: buildUtilityShiftingProjectLabel(id: id, projectName: name),
      ),
    );
  }
  return out;
}

/// Execution Agency: `execution_agency_fk` → label = same value.
List<ContractDetailOption> parseUtilityShiftingExecutionAgencies(Object? data) {
  final List<ContractDetailOption> out = <ContractDetailOption>[];
  final Set<String> seen = <String>{};
  for (final Map<String, dynamic> map in _asMaps(data)) {
    final String id = _firstText(map, const <String>[
      'execution_agency_fk',
      'execution_agency',
      'agency',
      'id',
      'value',
      'name',
      'label',
    ]);
    if (id.isEmpty || !seen.add(id)) {
      continue;
    }
    out.add(
      ContractDetailOption(
        id: id,
        label: buildUtilityShiftingExecutionAgencyLabel(id),
      ),
    );
  }
  return out;
}

/// Impacted contracts: `{contract_id_fk} - {contract_short_name|contract_name}`.
List<ContractDetailOption> parseUtilityShiftingImpactedContracts(Object? data) {
  final List<ContractDetailOption> out = <ContractDetailOption>[];
  final Set<String> seen = <String>{};
  for (final Map<String, dynamic> map in _asMaps(data)) {
    final String id = _firstText(map, const <String>[
      'contract_id_fk',
      'contract_id',
      'id',
      'value',
    ]);
    if (id.isEmpty || !seen.add(id)) {
      continue;
    }
    final String shortName = _firstText(map, const <String>[
      'contract_short_name',
    ]);
    final String fullName = _firstText(map, const <String>[
      'contract_name',
      'name',
      'label',
    ]);
    out.add(
      ContractDetailOption(
        id: id,
        label: buildUtilityShiftingImpactedContractLabel(
          contractId: id,
          shortName: shortName,
          contractName: fullName,
        ),
      ),
    );
  }
  return out;
}

/// HOD: `{user_name} - {designation}` (id = `hod_user_id_fk`).
List<ContractDetailOption> parseUtilityShiftingHods(Object? data) {
  final List<ContractDetailOption> out = <ContractDetailOption>[];
  final Set<String> seen = <String>{};
  for (final Map<String, dynamic> map in _asMaps(data)) {
    final String id = _firstText(map, const <String>[
      'hod_user_id_fk',
      'user_id',
      'userId',
      'id',
      'value',
    ]);
    final String name = _firstText(map, const <String>[
      'user_name',
      'hod_name',
      'name',
      'label',
    ]);
    if (id.isEmpty && name.isEmpty) {
      continue;
    }
    final String key = id.isNotEmpty ? id : name;
    if (!seen.add(key)) {
      continue;
    }
    final String designation = _firstText(map, const <String>[
      'designation',
      'hod_designation',
    ]);
    out.add(
      ContractDetailOption(
        id: key,
        label: buildUtilityShiftingHodLabel(
          userName: name.isEmpty ? key : name,
          designation: designation,
        ),
      ),
    );
  }
  return out;
}

String buildUtilityShiftingProjectLabel({
  required String id,
  required String projectName,
}) {
  final String trimmedId = id.trim();
  final String trimmedName = projectName.trim();
  if (trimmedName.isEmpty) {
    return trimmedId;
  }
  if (trimmedId.isEmpty) {
    return trimmedName;
  }
  final String lowerName = trimmedName.toLowerCase();
  final String lowerId = trimmedId.toLowerCase();
  if (lowerName == lowerId || lowerName.startsWith('$lowerId -')) {
    return trimmedName;
  }
  return '$trimmedId - $trimmedName';
}

String buildUtilityShiftingExecutionAgencyLabel(String agency) {
  return agency.trim();
}

String buildUtilityShiftingImpactedContractLabel({
  required String contractId,
  String shortName = '',
  String contractName = '',
}) {
  final String id = contractId.trim();
  final String name = shortName.trim().isNotEmpty
      ? shortName.trim()
      : contractName.trim();
  if (name.isEmpty) {
    return id;
  }
  if (id.isEmpty) {
    return name;
  }
  final String lowerName = name.toLowerCase();
  final String lowerId = id.toLowerCase();
  if (lowerName == lowerId || lowerName.startsWith('$lowerId -')) {
    return name;
  }
  return '$id - $name';
}

String buildUtilityShiftingHodLabel({
  required String userName,
  String designation = '',
}) {
  final String name = userName.trim();
  final String role = designation.trim();
  if (name.isEmpty) {
    return role;
  }
  if (role.isEmpty || name == role) {
    return name;
  }
  return '$name - $role';
}

/// Documented body shape for when the generate API arrives.
///
/// Expected filter values:
/// - project: [projectId] → `project_id_fk` (e.g. P26)
/// - execution agency: [executionAgency] → `execution_agency_fk` (e.g. MPPKVVCL)
/// - impacted contract: [contractId] → `contract_id_fk` (e.g. P01EN02)
/// - hod: [hodUserId] → `hod_user_id_fk` (e.g. PMIS_IU_039)
Map<String, dynamic> buildUtilityShiftingGenerateBody({
  required String projectId,
  required String executionAgency,
  required String contractId,
  required String hodUserId,
}) {
  return <String, dynamic>{
    'project_id_fk': projectId.trim(),
    'execution_agency_fk': executionAgency.trim(),
    'contract_id_fk': contractId.trim(),
    'hod_user_id_fk': hodUserId.trim(),
  };
}

Object? _pickList(Map<String, dynamic> root, List<String> keys) {
  for (final String key in keys) {
    final Object? value = root[key];
    if (value is List) {
      return value;
    }
    if (value is Map) {
      return value;
    }
  }
  return null;
}

Map<String, dynamic>? _asRootMap(Object? data) {
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    for (final String key in const <String>['data', 'result', 'content']) {
      final Object? nested = map[key];
      if (nested is Map) {
        return Map<String, dynamic>.from(nested);
      }
    }
    return map;
  }
  return null;
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
      'project_id_fk',
      'project_id',
      'project_name',
      'execution_agency_fk',
      'contract_id_fk',
      'contract_id',
      'hod_user_id_fk',
      'user_name',
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
