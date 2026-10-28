class ContractOption {
  const ContractOption({required this.value, required this.label});

  final String value;
  final String label;
}

class ContractRow {
  const ContractRow({
    required this.contractId,
    required this.projectIdFk,
    required this.projectName,
    required this.contractName,
    required this.contractShortName,
    required this.contractorName,
    required this.department,
    required this.hod,
    required this.dyHod,
    required this.contractStatus,
    required this.workStatus,
    required this.lastUpdate,
  });

  final String contractId;
  final String projectIdFk;
  final String projectName;
  final String contractName;
  final String contractShortName;
  final String contractorName;
  final String department;
  final String hod;
  final String dyHod;
  final String contractStatus;
  final String workStatus;
  final String lastUpdate;

  String get projectDisplay {
    final String name = projectName.trim();
    final String id = projectIdFk.trim();
    if (id.isNotEmpty && name.isNotEmpty && name != id) {
      return '$id - $name';
    }
    if (name.isNotEmpty) {
      return name;
    }
    return id;
  }

  String get nameDisplay {
    final String shortName = contractShortName.trim();
    if (shortName.isNotEmpty) {
      return shortName;
    }
    return contractName.trim();
  }
}

class ContractListQuery {
  const ContractListQuery({
    this.projectIdFk = '',
    this.designation = '',
    this.dyHod = '',
    this.contractorIdFk = '',
    this.contractStatus = '',
    this.status = '',
    this.search = '',
    this.page = 1,
    this.pageSize = 10,
  });

  final String projectIdFk;
  final String designation;
  final String dyHod;
  final String contractorIdFk;
  final String contractStatus;
  final String status;
  final String search;
  final int page;
  final int pageSize;

  int get displayStart {
    final int size = pageSize < 1 ? 10 : pageSize;
    final int safePage = page < 1 ? 1 : page;
    return (safePage - 1) * size;
  }

  Map<String, dynamic> filterQueryParameters({
    bool includeProject = true,
    bool includeDesignation = true,
    bool includeDyHod = true,
    bool includeContractor = true,
    bool includeContractStatus = true,
    bool includeStatus = true,
  }) {
    final Map<String, dynamic> params = <String, dynamic>{};
    if (includeProject) {
      params['project_id_fk'] = projectIdFk;
    }
    if (includeDesignation) {
      params['designation'] = designation;
    }
    if (includeDyHod) {
      params['dy_hod'] = dyHod;
    }
    if (includeContractor) {
      params['contractor_id_fk'] = contractorIdFk;
    }
    if (includeContractStatus) {
      params['contract_status'] = contractStatus;
    }
    if (includeStatus) {
      params['status'] = status;
    }
    return params;
  }

  Map<String, String> filterBody() {
    return <String, String>{
      'project_id_fk': projectIdFk,
      'designation': designation,
      'dy_hod': dyHod,
      'contractor_id_fk': contractorIdFk,
      'contract_status': contractStatus,
      'status': status,
    };
  }

  Map<String, dynamic> listQueryParameters() {
    return <String, dynamic>{
      'iDisplayStart': displayStart,
      'iDisplayLength': pageSize < 1 ? 10 : pageSize,
      'sSearch': search,
    };
  }

  ContractListQuery copyWith({
    String? projectIdFk,
    String? designation,
    String? dyHod,
    String? contractorIdFk,
    String? contractStatus,
    String? status,
    String? search,
    int? page,
    int? pageSize,
  }) {
    return ContractListQuery(
      projectIdFk: projectIdFk ?? this.projectIdFk,
      designation: designation ?? this.designation,
      dyHod: dyHod ?? this.dyHod,
      contractorIdFk: contractorIdFk ?? this.contractorIdFk,
      contractStatus: contractStatus ?? this.contractStatus,
      status: status ?? this.status,
      search: search ?? this.search,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

class ContractListSnapshot {
  const ContractListSnapshot({
    this.projects = const <ContractOption>[],
    this.hods = const <ContractOption>[],
    this.dyHods = const <ContractOption>[],
    this.contractors = const <ContractOption>[],
    this.contractStatuses = const <ContractOption>[],
    this.workStatuses = const <ContractOption>[],
    this.rows = const <ContractRow>[],
    this.total = 0,
  });

  static const ContractListSnapshot empty = ContractListSnapshot();

  final List<ContractOption> projects;
  final List<ContractOption> hods;
  final List<ContractOption> dyHods;
  final List<ContractOption> contractors;
  final List<ContractOption> contractStatuses;
  final List<ContractOption> workStatuses;
  final List<ContractRow> rows;
  final int total;

  ContractListSnapshot copyWith({
    List<ContractOption>? projects,
    List<ContractOption>? hods,
    List<ContractOption>? dyHods,
    List<ContractOption>? contractors,
    List<ContractOption>? contractStatuses,
    List<ContractOption>? workStatuses,
    List<ContractRow>? rows,
    int? total,
  }) {
    return ContractListSnapshot(
      projects: projects ?? this.projects,
      hods: hods ?? this.hods,
      dyHods: dyHods ?? this.dyHods,
      contractors: contractors ?? this.contractors,
      contractStatuses: contractStatuses ?? this.contractStatuses,
      workStatuses: workStatuses ?? this.workStatuses,
      rows: rows ?? this.rows,
      total: total ?? this.total,
    );
  }
}

enum ContractFilterField {
  project,
  hod,
  dyHod,
  contractor,
  contractStatus,
  workStatus,
}

enum ContractListCall {
  projects,
  hods,
  dyHods,
  contractors,
  contractStatuses,
  workStatuses,
  list,
}

List<ContractListCall> contractListCalls({ContractFilterField? changed}) {
  const List<ContractListCall> all = <ContractListCall>[
    ContractListCall.projects,
    ContractListCall.hods,
    ContractListCall.dyHods,
    ContractListCall.contractors,
    ContractListCall.contractStatuses,
    ContractListCall.workStatuses,
    ContractListCall.list,
  ];
  if (changed == null) {
    return all;
  }
  final ContractListCall skipped = switch (changed) {
    ContractFilterField.project => ContractListCall.projects,
    ContractFilterField.hod => ContractListCall.hods,
    ContractFilterField.dyHod => ContractListCall.dyHods,
    ContractFilterField.contractor => ContractListCall.contractors,
    ContractFilterField.contractStatus => ContractListCall.contractStatuses,
    ContractFilterField.workStatus => ContractListCall.workStatuses,
  };
  return all
      .where((ContractListCall call) => call != skipped)
      .toList(growable: false);
}
