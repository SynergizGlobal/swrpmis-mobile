class ProjectOption {
  const ProjectOption({required this.value, required this.label, this.meta});

  final String value;
  final String label;

  /// Optional secondary key (e.g. section → division_id).
  final String? meta;
}

class ProjectBlockSectionRow {
  const ProjectBlockSectionRow({
    required this.name,
    required this.fromChainage,
    required this.toChainage,
    this.commissioningDate,
  });

  final String name;
  final String fromChainage;
  final String toChainage;
  final String? commissioningDate;
}

class ProjectCompletionCostRow {
  const ProjectCompletionCostRow({
    this.date,
    this.estimatedCost,
    this.revisedDate,
  });

  final String? date;
  final String? estimatedCost;
  final String? revisedDate;
}

class ProjectRow {
  const ProjectRow({
    required this.projectId,
    required this.projectName,
    required this.projectStatus,
    required this.projectTypeId,
    required this.projectTypeName,
    required this.railwayZone,
    required this.planHeadNumber,
    required this.sanctionedAmount,
    required this.sanctionedYear,
    required this.sanctionedCommissioningDate,
    required this.divisionId,
    required this.divisionName,
    required this.sectionId,
    required this.sectionName,
    this.pbItemNumber = '',
    this.fromChainage = '',
    this.toChainage = '',
    this.proposedLength = '',
    this.actualCompletionCost = '',
    this.actualCompletionDate = '',
    this.benefits = '',
    this.remarks = '',
    this.blockSections = const <ProjectBlockSectionRow>[],
    this.completionCosts = const <ProjectCompletionCostRow>[],
  });

  final String projectId;
  final String projectName;
  final String projectStatus;
  final String projectTypeId;
  final String projectTypeName;
  final String railwayZone;
  final String planHeadNumber;
  final String sanctionedAmount;
  final String sanctionedYear;
  final String sanctionedCommissioningDate;
  final String divisionId;
  final String divisionName;
  final String sectionId;
  final String sectionName;
  final String pbItemNumber;
  final String fromChainage;
  final String toChainage;
  final String proposedLength;
  final String actualCompletionCost;
  final String actualCompletionDate;
  final String benefits;
  final String remarks;
  final List<ProjectBlockSectionRow> blockSections;
  final List<ProjectCompletionCostRow> completionCosts;
}

class ProjectListQuery {
  const ProjectListQuery({
    this.projectStatus = '',
    this.projectTypeId = '',
    this.search = '',
  });

  final String projectStatus;
  final String projectTypeId;
  final String search;

  ProjectListQuery copyWith({
    String? projectStatus,
    String? projectTypeId,
    String? search,
  }) {
    return ProjectListQuery(
      projectStatus: projectStatus ?? this.projectStatus,
      projectTypeId: projectTypeId ?? this.projectTypeId,
      search: search ?? this.search,
    );
  }
}

class ProjectListSnapshot {
  const ProjectListSnapshot({
    this.projectTypes = const <ProjectOption>[],
    this.rows = const <ProjectRow>[],
  });

  static const ProjectListSnapshot empty = ProjectListSnapshot();

  final List<ProjectOption> projectTypes;
  final List<ProjectRow> rows;

  ProjectListSnapshot copyWith({
    List<ProjectOption>? projectTypes,
    List<ProjectRow>? rows,
  }) {
    return ProjectListSnapshot(
      projectTypes: projectTypes ?? this.projectTypes,
      rows: rows ?? this.rows,
    );
  }
}

const List<ProjectOption> projectStatusOptions = <ProjectOption>[
  ProjectOption(value: 'Open', label: 'Open'),
  ProjectOption(value: 'Closed', label: 'Closed'),
];

const List<String> projectExportHeaders = <String>[
  'ID',
  'Name',
  'Status',
  'Type',
  'Railway Zone',
  'Plan Head No.',
  'Sanctioned Amount',
  'Sanctioned Year',
  'Sanctioned Date',
  'Division',
  'Section',
];

List<String> projectExportCells(ProjectRow row) {
  return <String>[
    row.projectId,
    row.projectName,
    row.projectStatus,
    row.projectTypeName,
    row.railwayZone,
    row.planHeadNumber,
    row.sanctionedAmount,
    row.sanctionedYear,
    row.sanctionedCommissioningDate,
    row.divisionName,
    row.sectionName,
  ];
}

bool projectRowMatches(ProjectRow row, ProjectListQuery query) {
  final String status = query.projectStatus.trim();
  if (status.isNotEmpty &&
      row.projectStatus.toLowerCase() != status.toLowerCase()) {
    return false;
  }
  final String typeId = query.projectTypeId.trim();
  if (typeId.isNotEmpty && row.projectTypeId != typeId) {
    final String typeName = row.projectTypeName.toLowerCase();
    if (typeName != typeId.toLowerCase()) {
      return false;
    }
  }
  final String search = query.search.trim().toLowerCase();
  if (search.isEmpty) {
    return true;
  }
  final String haystack = <String>[
    row.projectId,
    row.projectName,
    row.projectStatus,
    row.projectTypeName,
    row.railwayZone,
    row.planHeadNumber,
    row.sanctionedAmount,
    row.sanctionedYear,
    row.sanctionedCommissioningDate,
    row.divisionName,
    row.sectionName,
  ].join(' ').toLowerCase();
  return haystack.contains(search);
}
