class QualityTestOption {
  const QualityTestOption({required this.value, required this.label});

  final String value;
  final String label;
}

class QualityTestObligationRow {
  const QualityTestObligationRow({
    required this.id,
    required this.obligationCode,
    required this.projectId,
    required this.projectName,
    required this.sectionName,
    required this.contractId,
    required this.contractName,
    required this.materialCode,
    required this.materialName,
    required this.testName,
    required this.frequencyBasis,
    required this.generatedFrom,
    required this.obligationBasisCoverage,
    required this.batchLotNo,
    required this.requiredByDate,
    required this.contractorStatus,
    required this.engineerStatus,
  });

  final int id;
  final String obligationCode;
  final String projectId;
  final String projectName;
  final String sectionName;
  final String contractId;
  final String contractName;
  final String materialCode;
  final String materialName;
  final String testName;
  final String frequencyBasis;
  final String generatedFrom;
  final String obligationBasisCoverage;
  final String batchLotNo;
  final String requiredByDate;
  final String contractorStatus;
  final String engineerStatus;

  String get projectLabel {
    final String name = projectName.trim();
    if (name.isNotEmpty) {
      return name;
    }
    return projectId.trim();
  }

  String get contractLabel {
    final String name = contractName.trim();
    if (name.isNotEmpty) {
      return name;
    }
    return contractId.trim();
  }

  String get materialLabel {
    final String name = materialName.trim();
    if (name.isNotEmpty) {
      return name;
    }
    return materialCode.trim();
  }
}

/// UI page is 1-based; API `page` is 0-based (see [listQueryParameters]).
class QualityTestRegisterListQuery {
  const QualityTestRegisterListQuery({
    this.projectId = '',
    this.sectionId = '',
    this.contractId = '',
    this.materialCode = '',
    this.testStatus = '',
    this.dateFrom = '',
    this.dateTo = '',
    this.search = '',
    this.page = 1,
    this.pageSize = 10,
  });

  final String projectId;
  final String sectionId;
  final String contractId;
  final String materialCode;
  final String testStatus;
  final String dateFrom;
  final String dateTo;
  final String search;
  final int page;
  final int pageSize;

  Map<String, dynamic> listQueryParameters() {
    final int apiPage = page < 1 ? 0 : page - 1;
    final Map<String, dynamic> params = <String, dynamic>{
      'page': apiPage,
      'size': pageSize < 1 ? 10 : pageSize,
    };
    void put(String key, String value) {
      final String trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        params[key] = trimmed;
      }
    }

    put('projectId', projectId);
    put('sectionId', sectionId);
    put('contractId', contractId);
    put('materialCode', materialCode);
    put('testStatus', testStatus);
    put('dateFrom', dateFrom);
    put('dateTo', dateTo);
    put('q', search);
    return params;
  }

  QualityTestRegisterListQuery copyWith({
    String? projectId,
    String? sectionId,
    String? contractId,
    String? materialCode,
    String? testStatus,
    String? dateFrom,
    String? dateTo,
    String? search,
    int? page,
    int? pageSize,
  }) {
    return QualityTestRegisterListQuery(
      projectId: projectId ?? this.projectId,
      sectionId: sectionId ?? this.sectionId,
      contractId: contractId ?? this.contractId,
      materialCode: materialCode ?? this.materialCode,
      testStatus: testStatus ?? this.testStatus,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      search: search ?? this.search,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

class QualityTestRegisterSnapshot {
  const QualityTestRegisterSnapshot({
    this.projects = const <QualityTestOption>[],
    this.sections = const <QualityTestOption>[],
    this.contracts = const <QualityTestOption>[],
    this.materials = const <QualityTestOption>[],
    this.rows = const <QualityTestObligationRow>[],
    this.total = 0,
  });

  static const QualityTestRegisterSnapshot empty =
      QualityTestRegisterSnapshot();

  final List<QualityTestOption> projects;
  final List<QualityTestOption> sections;
  final List<QualityTestOption> contracts;
  final List<QualityTestOption> materials;
  final List<QualityTestObligationRow> rows;
  final int total;

  QualityTestRegisterSnapshot copyWith({
    List<QualityTestOption>? projects,
    List<QualityTestOption>? sections,
    List<QualityTestOption>? contracts,
    List<QualityTestOption>? materials,
    List<QualityTestObligationRow>? rows,
    int? total,
  }) {
    return QualityTestRegisterSnapshot(
      projects: projects ?? this.projects,
      sections: sections ?? this.sections,
      contracts: contracts ?? this.contracts,
      materials: materials ?? this.materials,
      rows: rows ?? this.rows,
      total: total ?? this.total,
    );
  }
}

/// Static Test Status filter options (web "All" + known statuses).
const List<QualityTestOption> qualityTestStatusOptions = <QualityTestOption>[
  QualityTestOption(value: 'PENDING', label: 'PENDING'),
  QualityTestOption(value: 'SUBMITTED', label: 'SUBMITTED'),
  QualityTestOption(value: 'APPROVED', label: 'APPROVED'),
  QualityTestOption(value: 'NCR_RAISED', label: 'NCR RAISED'),
  QualityTestOption(value: 'RETURNED', label: 'RETURNED'),
];
