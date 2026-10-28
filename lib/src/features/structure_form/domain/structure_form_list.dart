class StructureFormOption {
  const StructureFormOption({required this.value, required this.label});

  final String value;
  final String label;
}

class StructureFormRow {
  const StructureFormRow({
    required this.structureId,
    required this.projectIdFk,
    required this.structureTypeFk,
    required this.structure,
    required this.structureName,
    required this.contractIdFk,
    required this.contractShortName,
    required this.workStatusFk,
  });

  final String structureId;
  final String projectIdFk;
  final String structureTypeFk;
  final String structure;
  final String structureName;
  final String contractIdFk;
  final String contractShortName;
  final String workStatusFk;

  String get structureDisplay {
    final String name = structureName.trim();
    if (name.isNotEmpty) {
      return name;
    }
    return structure.trim();
  }
}

class StructureFormListQuery {
  const StructureFormListQuery({
    this.contractIdFk = '',
    this.structureTypeFk = '',
    this.workStatusFk = '',
    this.search = '',
    this.page = 1,
    this.pageSize = 10,
  });

  final String contractIdFk;
  final String structureTypeFk;
  final String workStatusFk;
  final String search;
  final int page;
  final int pageSize;

  int get displayStart {
    final int size = pageSize < 1 ? 10 : pageSize;
    final int safePage = page < 1 ? 1 : page;
    return (safePage - 1) * size;
  }

  Map<String, dynamic> filterQueryParameters({
    bool includeContract = true,
    bool includeStructureType = true,
    bool includeWorkStatus = true,
  }) {
    final Map<String, dynamic> params = <String, dynamic>{};
    if (includeContract) {
      params['contract_id_fk'] = contractIdFk;
    }
    if (includeStructureType) {
      params['structure_type_fk'] = structureTypeFk;
    }
    if (includeWorkStatus) {
      params['work_status_fk'] = workStatusFk;
    }
    return params;
  }

  Map<String, dynamic> listQueryParameters() {
    return <String, dynamic>{
      'iDisplayStart': displayStart,
      'iDisplayLength': pageSize < 1 ? 10 : pageSize,
      'sSearch': search,
      'contract_id_fk': contractIdFk,
      'structure_type_fk': structureTypeFk,
      'work_status_fk': workStatusFk,
    };
  }

  StructureFormListQuery copyWith({
    String? contractIdFk,
    String? structureTypeFk,
    String? workStatusFk,
    String? search,
    int? page,
    int? pageSize,
  }) {
    return StructureFormListQuery(
      contractIdFk: contractIdFk ?? this.contractIdFk,
      structureTypeFk: structureTypeFk ?? this.structureTypeFk,
      workStatusFk: workStatusFk ?? this.workStatusFk,
      search: search ?? this.search,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

class StructureFormListSnapshot {
  const StructureFormListSnapshot({
    this.contracts = const <StructureFormOption>[],
    this.structureTypes = const <StructureFormOption>[],
    this.workStatuses = const <StructureFormOption>[],
    this.rows = const <StructureFormRow>[],
    this.total = 0,
  });

  static const StructureFormListSnapshot empty = StructureFormListSnapshot();

  final List<StructureFormOption> contracts;
  final List<StructureFormOption> structureTypes;
  final List<StructureFormOption> workStatuses;
  final List<StructureFormRow> rows;
  final int total;

  StructureFormListSnapshot copyWith({
    List<StructureFormOption>? contracts,
    List<StructureFormOption>? structureTypes,
    List<StructureFormOption>? workStatuses,
    List<StructureFormRow>? rows,
    int? total,
  }) {
    return StructureFormListSnapshot(
      contracts: contracts ?? this.contracts,
      structureTypes: structureTypes ?? this.structureTypes,
      workStatuses: workStatuses ?? this.workStatuses,
      rows: rows ?? this.rows,
      total: total ?? this.total,
    );
  }
}

enum StructureFormFilterField { contract, structureType, workStatus }

enum StructureFormListCall { contracts, structureTypes, workStatuses, list }

List<StructureFormListCall> structureFormListCalls({
  StructureFormFilterField? changed,
}) {
  const List<StructureFormListCall> all = <StructureFormListCall>[
    StructureFormListCall.contracts,
    StructureFormListCall.structureTypes,
    StructureFormListCall.workStatuses,
    StructureFormListCall.list,
  ];
  if (changed == null) {
    return all;
  }
  final StructureFormListCall skipped = switch (changed) {
    StructureFormFilterField.contract => StructureFormListCall.contracts,
    StructureFormFilterField.structureType =>
      StructureFormListCall.structureTypes,
    StructureFormFilterField.workStatus => StructureFormListCall.workStatuses,
  };
  return all
      .where((StructureFormListCall call) => call != skipped)
      .toList(growable: false);
}
