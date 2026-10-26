class NcrOption {
  const NcrOption({required this.value, required this.label});

  final String value;
  final String label;
}

class NcrObservationRow {
  const NcrObservationRow({
    required this.id,
    required this.ncrCode,
    required this.ncrType,
    required this.severity,
    required this.description,
    required this.location,
    required this.testObligationId,
    required this.sourceType,
    required this.status,
    required this.overdue,
    required this.raisedDate,
    required this.targetClosureDate,
    required this.projectId,
    required this.projectName,
    required this.sectionId,
    required this.contractId,
    required this.contractName,
    required this.materialReceiptId,
    required this.responsibleContractorId,
  });

  final int id;
  final String ncrCode;
  final String ncrType;
  final String severity;
  final String description;
  final String location;
  final int? testObligationId;
  final String sourceType;
  final String status;
  final bool overdue;
  final String raisedDate;
  final String targetClosureDate;
  final String projectId;
  final String projectName;
  final String sectionId;
  final String contractId;
  final String contractName;
  final String materialReceiptId;
  final String responsibleContractorId;

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

  String get sourceLabel {
    final String raw = sourceType.trim();
    if (raw.isEmpty) {
      return '';
    }
    return raw.replaceAll('_', ' ');
  }

  String get referenceLabel {
    final int? obligationId = testObligationId;
    if (obligationId == null || obligationId < 1) {
      return '';
    }
    return 'Test Obligation #$obligationId';
  }
}

/// UI page is 1-based; API `page` is 0-based.
class NcrObservationListQuery {
  const NcrObservationListQuery({
    this.projectId = '',
    this.sectionId = '',
    this.contractId = '',
    this.ncrType = '',
    this.status = '',
    this.dateFrom = '',
    this.dateTo = '',
    this.search = '',
    this.page = 1,
    this.pageSize = 10,
  });

  final String projectId;
  final String sectionId;
  final String contractId;
  final String ncrType;
  final String status;
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
    put('ncrType', ncrType);
    put('status', status);
    put('dateFrom', dateFrom);
    put('dateTo', dateTo);
    put('q', search);
    return params;
  }

  NcrObservationListQuery copyWith({
    String? projectId,
    String? sectionId,
    String? contractId,
    String? ncrType,
    String? status,
    String? dateFrom,
    String? dateTo,
    String? search,
    int? page,
    int? pageSize,
  }) {
    return NcrObservationListQuery(
      projectId: projectId ?? this.projectId,
      sectionId: sectionId ?? this.sectionId,
      contractId: contractId ?? this.contractId,
      ncrType: ncrType ?? this.ncrType,
      status: status ?? this.status,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      search: search ?? this.search,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

class NcrObservationSnapshot {
  const NcrObservationSnapshot({
    this.projects = const <NcrOption>[],
    this.sections = const <NcrOption>[],
    this.contracts = const <NcrOption>[],
    this.rows = const <NcrObservationRow>[],
    this.total = 0,
  });

  static const NcrObservationSnapshot empty = NcrObservationSnapshot();

  final List<NcrOption> projects;
  final List<NcrOption> sections;
  final List<NcrOption> contracts;
  final List<NcrObservationRow> rows;
  final int total;

  NcrObservationSnapshot copyWith({
    List<NcrOption>? projects,
    List<NcrOption>? sections,
    List<NcrOption>? contracts,
    List<NcrObservationRow>? rows,
    int? total,
  }) {
    return NcrObservationSnapshot(
      projects: projects ?? this.projects,
      sections: sections ?? this.sections,
      contracts: contracts ?? this.contracts,
      rows: rows ?? this.rows,
      total: total ?? this.total,
    );
  }
}

const List<NcrOption> ncrTypeFilterOptions = <NcrOption>[
  NcrOption(value: 'NCR', label: 'NCR'),
  NcrOption(value: 'OBSERVATION', label: 'Observation'),
];

const List<NcrOption> ncrStatusFilterOptions = <NcrOption>[
  NcrOption(value: 'OPEN', label: 'Open'),
  NcrOption(value: 'ACTION_SUBMITTED', label: 'Action Submitted'),
  NcrOption(value: 'RETURNED', label: 'Returned'),
  NcrOption(value: 'CLOSED', label: 'Closed'),
];
