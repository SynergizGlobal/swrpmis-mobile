class MaterialReceiptOption {
  const MaterialReceiptOption({required this.value, required this.label});

  final String value;
  final String label;
}

class MaterialReceiptRow {
  const MaterialReceiptRow({
    required this.receiptId,
    required this.projectId,
    required this.projectName,
    required this.sectionId,
    required this.sectionName,
    required this.contractId,
    required this.contractShortName,
    required this.materialName,
    required this.batchLotNo,
    required this.quantity,
    required this.unit,
    required this.deliveryDate,
    required this.invoiceNo,
    required this.status,
    required this.createdOn,
  });

  final String receiptId;
  final String projectId;
  final String projectName;
  final String sectionId;
  final String sectionName;
  final String contractId;
  final String contractShortName;
  final String materialName;
  final String batchLotNo;
  final String quantity;
  final String unit;
  final String deliveryDate;
  final String invoiceNo;
  final String status;
  final String createdOn;

  String get projectLabel {
    final String id = projectId.trim();
    final String name = projectName.trim();
    if (id.isEmpty) {
      return name;
    }
    if (name.isEmpty) {
      return id;
    }
    return '$id - $name';
  }

  String get sectionLabel {
    final String id = sectionId.trim();
    final String name = sectionName.trim();
    if (id.isEmpty && name.isEmpty) {
      return '';
    }
    if (id.isEmpty) {
      return name;
    }
    if (name.isEmpty) {
      return id;
    }
    return '$id - $name';
  }

  String get contractLabel {
    final String id = contractId.trim();
    final String name = contractShortName.trim();
    if (id.isEmpty) {
      return name;
    }
    if (name.isEmpty) {
      return id;
    }
    return '$id - $name';
  }
}

class MaterialReceiptListQuery {
  const MaterialReceiptListQuery({
    this.projectId = '',
    this.sectionId = '',
    this.contractId = '',
    this.materialId = '',
    this.deliveryDateFrom = '',
    this.deliveryDateTo = '',
    this.search = '',
    this.page = 1,
    this.pageSize = 10,
  });

  final String projectId;
  final String sectionId;
  final String contractId;
  final String materialId;
  final String deliveryDateFrom;
  final String deliveryDateTo;
  final String search;
  final int page;
  final int pageSize;

  Map<String, dynamic> listQueryParameters() {
    final Map<String, dynamic> params = <String, dynamic>{
      'page': page < 1 ? 1 : page,
      'pageSize': pageSize < 1 ? 10 : pageSize,
    };
    void put(String key, String value) {
      final String trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        params[key] = trimmed;
      }
    }

    put('project_id', projectId);
    put('section_id', sectionId);
    put('contract_id', contractId);
    put('material_id', materialId);
    put('delivery_date_from', deliveryDateFrom);
    put('delivery_date_to', deliveryDateTo);
    put('search', search);
    return params;
  }

  MaterialReceiptListQuery copyWith({
    String? projectId,
    String? sectionId,
    String? contractId,
    String? materialId,
    String? deliveryDateFrom,
    String? deliveryDateTo,
    String? search,
    int? page,
    int? pageSize,
  }) {
    return MaterialReceiptListQuery(
      projectId: projectId ?? this.projectId,
      sectionId: sectionId ?? this.sectionId,
      contractId: contractId ?? this.contractId,
      materialId: materialId ?? this.materialId,
      deliveryDateFrom: deliveryDateFrom ?? this.deliveryDateFrom,
      deliveryDateTo: deliveryDateTo ?? this.deliveryDateTo,
      search: search ?? this.search,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

class MaterialReceiptListSnapshot {
  const MaterialReceiptListSnapshot({
    this.projects = const <MaterialReceiptOption>[],
    this.sections = const <MaterialReceiptOption>[],
    this.contracts = const <MaterialReceiptOption>[],
    this.materials = const <MaterialReceiptOption>[],
    this.rows = const <MaterialReceiptRow>[],
    this.total = 0,
  });

  static const MaterialReceiptListSnapshot empty = MaterialReceiptListSnapshot();

  final List<MaterialReceiptOption> projects;
  final List<MaterialReceiptOption> sections;
  final List<MaterialReceiptOption> contracts;
  final List<MaterialReceiptOption> materials;
  final List<MaterialReceiptRow> rows;
  final int total;

  MaterialReceiptListSnapshot copyWith({
    List<MaterialReceiptOption>? projects,
    List<MaterialReceiptOption>? sections,
    List<MaterialReceiptOption>? contracts,
    List<MaterialReceiptOption>? materials,
    List<MaterialReceiptRow>? rows,
    int? total,
  }) {
    return MaterialReceiptListSnapshot(
      projects: projects ?? this.projects,
      sections: sections ?? this.sections,
      contracts: contracts ?? this.contracts,
      materials: materials ?? this.materials,
      rows: rows ?? this.rows,
      total: total ?? this.total,
    );
  }
}
