class P6Option {
  const P6Option({required this.value, required this.label});

  final String value;
  final String label;
}

enum P6UploadKind { baseline, revisedBaseline, update }

extension P6UploadKindX on P6UploadKind {
  String get title {
    switch (this) {
      case P6UploadKind.baseline:
        return 'Baseline';
      case P6UploadKind.revisedBaseline:
        return 'Revised Baseline';
      case P6UploadKind.update:
        return 'Update';
    }
  }

  String get uploadType {
    switch (this) {
      case P6UploadKind.baseline:
        return 'Baseline';
      case P6UploadKind.revisedBaseline:
        return 'Revised Baseline';
      case P6UploadKind.update:
        return 'Update';
    }
  }

  String get actionLabel {
    switch (this) {
      case P6UploadKind.revisedBaseline:
        return 'Update';
      case P6UploadKind.baseline:
      case P6UploadKind.update:
        return 'Upload';
    }
  }
}

class P6HistoryRow {
  const P6HistoryRow({
    required this.contractId,
    required this.dataType,
    required this.dataDate,
    required this.status,
    required this.uploadedFile,
    required this.uploadedBy,
    required this.uploadedDate,
  });

  final String contractId;
  final String dataType;
  final String dataDate;
  final String status;
  final String uploadedFile;
  final String uploadedBy;
  final String uploadedDate;
}

class P6HistoryQuery {
  const P6HistoryQuery({
    this.contractId = '',
    this.uploadType = '',
    this.status = '',
  });

  final String contractId;
  final String uploadType;
  final String status;

  Map<String, String> toJson() {
    return <String, String>{
      'contract_id_fk': contractId,
      'upload_type': uploadType,
      'status_fk': status,
    };
  }

  P6HistoryQuery copyWith({
    String? contractId,
    String? uploadType,
    String? status,
  }) {
    return P6HistoryQuery(
      contractId: contractId ?? this.contractId,
      uploadType: uploadType ?? this.uploadType,
      status: status ?? this.status,
    );
  }
}

class P6HistorySnapshot {
  const P6HistorySnapshot({
    this.contracts = const <P6Option>[],
    this.uploadTypes = const <P6Option>[],
    this.statuses = const <P6Option>[],
    this.rows = const <P6HistoryRow>[],
  });

  static const P6HistorySnapshot empty = P6HistorySnapshot();

  final List<P6Option> contracts;
  final List<P6Option> uploadTypes;
  final List<P6Option> statuses;
  final List<P6HistoryRow> rows;

  P6HistorySnapshot copyWith({
    List<P6Option>? contracts,
    List<P6Option>? uploadTypes,
    List<P6Option>? statuses,
    List<P6HistoryRow>? rows,
  }) {
    return P6HistorySnapshot(
      contracts: contracts ?? this.contracts,
      uploadTypes: uploadTypes ?? this.uploadTypes,
      statuses: statuses ?? this.statuses,
      rows: rows ?? this.rows,
    );
  }
}

class P6FormMaster {
  const P6FormMaster({
    this.projects = const <P6Option>[],
    this.contracts = const <P6Option>[],
  });

  static const P6FormMaster empty = P6FormMaster();

  final List<P6Option> projects;
  final List<P6Option> contracts;
}

enum P6HistoryFilterField { contract, uploadType, status }

enum P6HistoryListCall { contracts, uploadTypes, statuses, rows }

List<P6HistoryListCall> p6HistoryListCalls({P6HistoryFilterField? changed}) {
  const List<P6HistoryListCall> all = <P6HistoryListCall>[
    P6HistoryListCall.contracts,
    P6HistoryListCall.uploadTypes,
    P6HistoryListCall.statuses,
    P6HistoryListCall.rows,
  ];
  if (changed == null) {
    return all;
  }
  return const <P6HistoryListCall>[P6HistoryListCall.rows];
}

const List<String> p6HistoryExportHeaders = <String>[
  'Contract ID',
  'Data Type',
  'Data Date',
  'Status',
  'Uploaded File',
  'Uploaded By',
  'Uploaded Date',
];

List<String> p6HistoryExportCells(P6HistoryRow row) {
  return <String>[
    row.contractId,
    row.dataType,
    row.dataDate,
    row.status,
    row.uploadedFile,
    row.uploadedBy,
    row.uploadedDate,
  ];
}
