class DesignOption {
  const DesignOption({required this.value, required this.label});

  final String value;
  final String label;
}

class DesignRow {
  const DesignRow({
    required this.designId,
    required this.pmisDrawingNo,
    required this.structureType,
    required this.structure,
    required this.title,
    required this.drawingType,
    required this.drawingNo,
    required this.lastUpdate,
  });

  final String designId;
  final String pmisDrawingNo;
  final String structureType;
  final String structure;
  final String title;
  final String drawingType;
  final String drawingNo;
  final String lastUpdate;
}

class DesignUploadRow {
  const DesignUploadRow({
    required this.designDataId,
    required this.uploadedFile,
    required this.status,
    required this.remarks,
    required this.uploadedBy,
    required this.uploadedOn,
  });

  final String designDataId;
  final String uploadedFile;
  final String status;
  final String remarks;
  final String uploadedBy;
  final String uploadedOn;
}

class DesignListQuery {
  const DesignListQuery({
    this.contractId = '',
    this.structureType = '',
    this.drawingType = '',
    this.search = '',
    this.page = 1,
    this.pageSize = 10,
  });

  final String contractId;
  final String structureType;
  final String drawingType;
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
      'contract_id_fk': contractId,
      'structure_type_fk': structureType,
      'drawing_type_fk': drawingType,
    };
  }

  Map<String, dynamic> listQueryParameters() {
    return <String, dynamic>{
      'iDisplayStart': displayStart,
      'iDisplayLength': pageSize < 1 ? 10 : pageSize,
      'sSearch': search,
      'contract_id_fk': contractId,
      'structure_type_fk': structureType,
      'drawing_type_fk': drawingType,
    };
  }

  DesignListQuery copyWith({
    String? contractId,
    String? structureType,
    String? drawingType,
    String? search,
    int? page,
    int? pageSize,
  }) {
    return DesignListQuery(
      contractId: contractId ?? this.contractId,
      structureType: structureType ?? this.structureType,
      drawingType: drawingType ?? this.drawingType,
      search: search ?? this.search,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

class DesignListSnapshot {
  const DesignListSnapshot({
    this.contracts = const <DesignOption>[],
    this.structureTypes = const <DesignOption>[],
    this.drawingTypes = const <DesignOption>[],
    this.rows = const <DesignRow>[],
    this.total = 0,
  });

  static const DesignListSnapshot empty = DesignListSnapshot();

  final List<DesignOption> contracts;
  final List<DesignOption> structureTypes;
  final List<DesignOption> drawingTypes;
  final List<DesignRow> rows;
  final int total;

  DesignListSnapshot copyWith({
    List<DesignOption>? contracts,
    List<DesignOption>? structureTypes,
    List<DesignOption>? drawingTypes,
    List<DesignRow>? rows,
    int? total,
  }) {
    return DesignListSnapshot(
      contracts: contracts ?? this.contracts,
      structureTypes: structureTypes ?? this.structureTypes,
      drawingTypes: drawingTypes ?? this.drawingTypes,
      rows: rows ?? this.rows,
      total: total ?? this.total,
    );
  }
}

enum DesignFilterField { contract, structureType, drawingType }

enum DesignListCall {
  contracts,
  structureTypes,
  drawingTypes,
  designs,
}

const List<String> designExportHeaders = <String>[
  'PMIS Drawing No.',
  'Structure Type',
  'Structure',
  'Title',
  'Drawing Type',
  'Drawing No.',
  'Last Update',
];

List<String> designExportCells(DesignRow row) {
  return <String>[
    row.pmisDrawingNo,
    row.structureType,
    row.structure,
    row.title,
    row.drawingType,
    row.drawingNo,
    row.lastUpdate,
  ];
}

List<DesignListCall> designListCalls({DesignFilterField? changed}) {
  const List<DesignListCall> all = <DesignListCall>[
    DesignListCall.contracts,
    DesignListCall.structureTypes,
    DesignListCall.drawingTypes,
    DesignListCall.designs,
  ];
  if (changed == null) {
    return all;
  }
  final DesignListCall skipped = switch (changed) {
    DesignFilterField.contract => DesignListCall.contracts,
    DesignFilterField.structureType => DesignListCall.structureTypes,
    DesignFilterField.drawingType => DesignListCall.drawingTypes,
  };
  return all
      .where((DesignListCall call) => call != skipped)
      .toList(growable: false);
}
