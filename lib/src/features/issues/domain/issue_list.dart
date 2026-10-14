class IssueOption {
  const IssueOption({required this.value, required this.label});

  final String value;
  final String label;
}

class IssueRow {
  const IssueRow({
    required this.issueId,
    required this.contract,
    required this.shortDescription,
    required this.location,
    required this.responsiblePerson,
    required this.department,
    required this.status,
    required this.lastUpdate,
  });

  final String issueId;
  final String contract;
  final String shortDescription;
  final String location;
  final String responsiblePerson;
  final String department;
  final String status;
  final String lastUpdate;
}

class IssueListQuery {
  const IssueListQuery({
    this.contractId = '',
    this.departmentId = '',
    this.categoryId = '',
    this.statusId = '',
    this.hodId = '',
  });

  final String contractId;
  final String departmentId;
  final String categoryId;
  final String statusId;
  final String hodId;

  Map<String, String> toJson() {
    return <String, String>{
      'contract_id_fk': contractId,
      'department_fk': departmentId,
      'category_fk': categoryId,
      'status_fk': statusId,
      'hod': hodId,
    };
  }

  IssueListQuery copyWith({
    String? contractId,
    String? departmentId,
    String? categoryId,
    String? statusId,
    String? hodId,
  }) {
    return IssueListQuery(
      contractId: contractId ?? this.contractId,
      departmentId: departmentId ?? this.departmentId,
      categoryId: categoryId ?? this.categoryId,
      statusId: statusId ?? this.statusId,
      hodId: hodId ?? this.hodId,
    );
  }
}

class IssueListSnapshot {
  const IssueListSnapshot({
    this.contracts = const <IssueOption>[],
    this.hods = const <IssueOption>[],
    this.departments = const <IssueOption>[],
    this.categories = const <IssueOption>[],
    this.statuses = const <IssueOption>[],
    this.issues = const <IssueRow>[],
  });

  static const IssueListSnapshot empty = IssueListSnapshot();

  final List<IssueOption> contracts;
  final List<IssueOption> hods;
  final List<IssueOption> departments;
  final List<IssueOption> categories;
  final List<IssueOption> statuses;
  final List<IssueRow> issues;

  IssueListSnapshot copyWith({
    List<IssueOption>? contracts,
    List<IssueOption>? hods,
    List<IssueOption>? departments,
    List<IssueOption>? categories,
    List<IssueOption>? statuses,
    List<IssueRow>? issues,
  }) {
    return IssueListSnapshot(
      contracts: contracts ?? this.contracts,
      hods: hods ?? this.hods,
      departments: departments ?? this.departments,
      categories: categories ?? this.categories,
      statuses: statuses ?? this.statuses,
      issues: issues ?? this.issues,
    );
  }
}

enum IssueFilterField { contract, hod, department, category, status }

enum IssueListCall {
  contracts,
  hods,
  departments,
  categories,
  statuses,
  issues,
}

const List<String> issueExportHeaders = <String>[
  'Contract',
  'Short Description',
  'Location',
  'Responsible Person',
  'Department',
  'Issue Status',
  'Last Update',
];

List<String> issueExportCells(IssueRow row) {
  return <String>[
    row.contract,
    row.shortDescription,
    row.location,
    row.responsiblePerson,
    row.department,
    row.status,
    row.lastUpdate,
  ];
}

List<IssueListCall> issueListCalls({IssueFilterField? changed}) {
  const List<IssueListCall> all = <IssueListCall>[
    IssueListCall.contracts,
    IssueListCall.hods,
    IssueListCall.departments,
    IssueListCall.categories,
    IssueListCall.statuses,
    IssueListCall.issues,
  ];
  if (changed == null) {
    return all;
  }
  final IssueListCall skipped = switch (changed) {
    IssueFilterField.contract => IssueListCall.contracts,
    IssueFilterField.hod => IssueListCall.hods,
    IssueFilterField.department => IssueListCall.departments,
    IssueFilterField.category => IssueListCall.categories,
    IssueFilterField.status => IssueListCall.statuses,
  };
  return all
      .where((IssueListCall call) => call != skipped)
      .toList(growable: false);
}
