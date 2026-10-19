class UtilityShiftingOption {
  const UtilityShiftingOption({required this.value, required this.label});

  final String value;
  final String label;
}

class UtilityShiftingRow {
  const UtilityShiftingRow({
    required this.utilityShiftingId,
    required this.project,
    required this.executionAgency,
    required this.hod,
    required this.utilityType,
    required this.description,
    required this.location,
    required this.custodian,
    required this.identificationDate,
    required this.referenceNo,
    required this.chainage,
    required this.executedBy,
    required this.impactedContract,
    required this.requirementStage,
    required this.impactedElement,
    required this.affectedStructures,
    required this.targetDate,
    required this.scope,
    required this.completed,
    required this.unit,
    required this.startDate,
    required this.status,
    required this.completionDate,
    required this.remarks,
    required this.lastUpdate,
  });

  final String utilityShiftingId;
  final String project;
  final String executionAgency;
  final String hod;
  final String utilityType;
  final String description;
  final String location;
  final String custodian;
  final String identificationDate;
  final String referenceNo;
  final String chainage;
  final String executedBy;
  final String impactedContract;
  final String requirementStage;
  final String impactedElement;
  final String affectedStructures;
  final String targetDate;
  final String scope;
  final String completed;
  final String unit;
  final String startDate;
  final String status;
  final String completionDate;
  final String remarks;
  final String lastUpdate;
}

class UtilityShiftingUploadRow {
  const UtilityShiftingUploadRow({
    required this.utilityDataId,
    required this.uploadedFile,
    required this.status,
    required this.remarks,
    required this.uploadedBy,
    required this.uploadedOn,
  });

  final String utilityDataId;
  final String uploadedFile;
  final String status;
  final String remarks;
  final String uploadedBy;
  final String uploadedOn;
}

class UtilityShiftingListQuery {
  const UtilityShiftingListQuery({
    this.locationName = '',
    this.utilityCategory = '',
    this.utilityType = '',
    this.status = '',
    this.search = '',
    this.page = 1,
    this.pageSize = 10,
  });

  final String locationName;
  final String utilityCategory;
  final String utilityType;
  final String status;
  final String search;
  final int page;
  final int pageSize;

  int get displayStart {
    final int size = pageSize < 1 ? 10 : pageSize;
    final int safePage = page < 1 ? 1 : page;
    return (safePage - 1) * size;
  }

  Map<String, String> filterBody() {
    return <String, String>{
      'location_name': locationName,
      'utility_category_fk': utilityCategory,
      'utility_type_fk': utilityType,
      'shifting_status_fk': status,
    };
  }

  Map<String, dynamic> listQueryParameters() {
    return <String, dynamic>{
      'iDisplayStart': displayStart,
      'iDisplayLength': pageSize < 1 ? 10 : pageSize,
      'sSearch': search,
    };
  }

  UtilityShiftingListQuery copyWith({
    String? locationName,
    String? utilityCategory,
    String? utilityType,
    String? status,
    String? search,
    int? page,
    int? pageSize,
  }) {
    return UtilityShiftingListQuery(
      locationName: locationName ?? this.locationName,
      utilityCategory: utilityCategory ?? this.utilityCategory,
      utilityType: utilityType ?? this.utilityType,
      status: status ?? this.status,
      search: search ?? this.search,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

class UtilityShiftingListSnapshot {
  const UtilityShiftingListSnapshot({
    this.locations = const <UtilityShiftingOption>[],
    this.categories = const <UtilityShiftingOption>[],
    this.utilityTypes = const <UtilityShiftingOption>[],
    this.statuses = const <UtilityShiftingOption>[],
    this.rows = const <UtilityShiftingRow>[],
    this.total = 0,
  });

  static const UtilityShiftingListSnapshot empty = UtilityShiftingListSnapshot();

  final List<UtilityShiftingOption> locations;
  final List<UtilityShiftingOption> categories;
  final List<UtilityShiftingOption> utilityTypes;
  final List<UtilityShiftingOption> statuses;
  final List<UtilityShiftingRow> rows;
  final int total;

  UtilityShiftingListSnapshot copyWith({
    List<UtilityShiftingOption>? locations,
    List<UtilityShiftingOption>? categories,
    List<UtilityShiftingOption>? utilityTypes,
    List<UtilityShiftingOption>? statuses,
    List<UtilityShiftingRow>? rows,
    int? total,
  }) {
    return UtilityShiftingListSnapshot(
      locations: locations ?? this.locations,
      categories: categories ?? this.categories,
      utilityTypes: utilityTypes ?? this.utilityTypes,
      statuses: statuses ?? this.statuses,
      rows: rows ?? this.rows,
      total: total ?? this.total,
    );
  }
}

enum UtilityShiftingFilterField {
  location,
  category,
  utilityType,
  status,
}

enum UtilityShiftingListCall {
  locations,
  categories,
  utilityTypes,
  statuses,
  list,
}

const List<String> utilityShiftingExportHeaders = <String>[
  'Utility ID',
  'Project',
  'Execution Agency',
  'HOD',
  'Utility Type',
  'Utility Description',
  'Location',
  'Custodian',
  'Identification Date',
  'Reference No.',
  'Chainage',
  'Executed By',
  'Impacted Contract',
  'Requirement stage',
  'Impacted Element',
  'Affected Structures',
  'Target Date',
  'Scope',
  'Completed',
  'Unit',
  'Start Date',
  'Status',
  'Completetion Date',
  'Remarks',
];

List<String> utilityShiftingExportCells(UtilityShiftingRow row) {
  return <String>[
    row.utilityShiftingId,
    row.project,
    row.executionAgency,
    row.hod,
    row.utilityType,
    row.description,
    row.location,
    row.custodian,
    row.identificationDate,
    row.referenceNo,
    row.chainage,
    row.executedBy,
    row.impactedContract,
    row.requirementStage,
    row.impactedElement,
    row.affectedStructures,
    row.targetDate,
    row.scope,
    row.completed,
    row.unit,
    row.startDate,
    row.status,
    row.completionDate,
    row.remarks,
  ];
}

List<UtilityShiftingListCall> utilityShiftingListCalls({
  UtilityShiftingFilterField? changed,
}) {
  const List<UtilityShiftingListCall> all = <UtilityShiftingListCall>[
    UtilityShiftingListCall.locations,
    UtilityShiftingListCall.categories,
    UtilityShiftingListCall.utilityTypes,
    UtilityShiftingListCall.statuses,
    UtilityShiftingListCall.list,
  ];
  if (changed == null) {
    return all;
  }
  final UtilityShiftingListCall skipped = switch (changed) {
    UtilityShiftingFilterField.location => UtilityShiftingListCall.locations,
    UtilityShiftingFilterField.category => UtilityShiftingListCall.categories,
    UtilityShiftingFilterField.utilityType =>
      UtilityShiftingListCall.utilityTypes,
    UtilityShiftingFilterField.status => UtilityShiftingListCall.statuses,
  };
  return all
      .where((UtilityShiftingListCall call) => call != skipped)
      .toList(growable: false);
}
