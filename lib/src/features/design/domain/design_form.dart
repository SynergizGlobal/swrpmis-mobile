import 'package:swr_pmis_mobile/src/features/design/domain/design_list.dart';

class DesignFormOption {
  const DesignFormOption({required this.id, required this.label});

  final String id;
  final String label;
}

class DesignFormMaster {
  const DesignFormMaster({
    this.projects = const <DesignFormOption>[],
    this.contracts = const <DesignFormOption>[],
    this.structureTypes = const <DesignFormOption>[],
    this.drawingTypes = const <DesignFormOption>[],
  });

  static const DesignFormMaster empty = DesignFormMaster();

  final List<DesignFormOption> projects;
  final List<DesignFormOption> contracts;
  final List<DesignFormOption> structureTypes;
  final List<DesignFormOption> drawingTypes;
}

/// Prefill for edit mode from the designs list row (no detail API yet).
class DesignFormPrefill {
  const DesignFormPrefill({
    this.designId = '',
    this.structureType = '',
    this.structure = '',
    this.title = '',
    this.drawingType = '',
    this.drawingNo = '',
  });

  factory DesignFormPrefill.fromRow(DesignRow row) {
    return DesignFormPrefill(
      designId: row.designId.trim(),
      structureType: row.structureType.trim(),
      structure: row.structure.trim(),
      title: row.title.trim(),
      drawingType: row.drawingType.trim(),
      drawingNo: row.drawingNo.trim(),
    );
  }

  static const DesignFormPrefill empty = DesignFormPrefill();

  final String designId;
  final String structureType;
  final String structure;
  final String title;
  final String drawingType;
  final String drawingNo;

  bool get isEmpty => designId.isEmpty && title.isEmpty && drawingNo.isEmpty;
}

class DesignStatusRowDraft {
  const DesignStatusRowDraft({
    this.drawingNo = '',
    this.stageId = '',
    this.submittedByOrg = '',
    this.submittedByDept = '',
    this.submittedByOfficial = '',
    this.submittedToOrg = '',
    this.submittedToDept = '',
    this.submittedToOfficial = '',
    this.purpose = '',
    this.correspondence = '',
    this.remarks = '',
    this.submittedDate,
    this.localFilePath = '',
    this.localFileName = '',
    this.isLatest = false,
  });

  final String drawingNo;
  final String stageId;
  final String submittedByOrg;
  final String submittedByDept;
  final String submittedByOfficial;
  final String submittedToOrg;
  final String submittedToDept;
  final String submittedToOfficial;
  final String purpose;
  final String correspondence;
  final String remarks;
  final DateTime? submittedDate;
  final String localFilePath;
  final String localFileName;
  final bool isLatest;

  DesignStatusRowDraft copyWith({
    String? drawingNo,
    String? stageId,
    String? submittedByOrg,
    String? submittedByDept,
    String? submittedByOfficial,
    String? submittedToOrg,
    String? submittedToDept,
    String? submittedToOfficial,
    String? purpose,
    String? correspondence,
    String? remarks,
    DateTime? submittedDate,
    bool clearSubmittedDate = false,
    String? localFilePath,
    String? localFileName,
    bool? isLatest,
  }) {
    return DesignStatusRowDraft(
      drawingNo: drawingNo ?? this.drawingNo,
      stageId: stageId ?? this.stageId,
      submittedByOrg: submittedByOrg ?? this.submittedByOrg,
      submittedByDept: submittedByDept ?? this.submittedByDept,
      submittedByOfficial: submittedByOfficial ?? this.submittedByOfficial,
      submittedToOrg: submittedToOrg ?? this.submittedToOrg,
      submittedToDept: submittedToDept ?? this.submittedToDept,
      submittedToOfficial: submittedToOfficial ?? this.submittedToOfficial,
      purpose: purpose ?? this.purpose,
      correspondence: correspondence ?? this.correspondence,
      remarks: remarks ?? this.remarks,
      submittedDate: clearSubmittedDate
          ? null
          : (submittedDate ?? this.submittedDate),
      localFilePath: localFilePath ?? this.localFilePath,
      localFileName: localFileName ?? this.localFileName,
      isLatest: isLatest ?? this.isLatest,
    );
  }
}

/// Static Approving Railway options (no design-specific lookup API yet).
const List<DesignFormOption> designApprovingRailways = <DesignFormOption>[
  DesignFormOption(id: 'SWR', label: 'SWR'),
  DesignFormOption(id: 'CR', label: 'CR'),
];

/// Static Prepared By options (no design-specific lookup API yet).
const List<DesignFormOption> designPreparedByOptions = <DesignFormOption>[
  DesignFormOption(id: 'Consultant', label: 'Consultant'),
  DesignFormOption(id: 'Contractor', label: 'Contractor'),
  DesignFormOption(id: 'Design Consultant', label: 'Design Consultant'),
];

/// Static drawing status stage options.
const List<DesignFormOption> designStageOptions = <DesignFormOption>[
  DesignFormOption(id: 'Select', label: 'Select'),
  DesignFormOption(id: 'Review', label: 'Review'),
  DesignFormOption(id: 'Approval', label: 'Approval'),
];

/// Sample Approval Authority options from web UI (lookup API TBD).
const List<DesignFormOption> designApprovalAuthorities = <DesignFormOption>[
  DesignFormOption(id: 'CRS', label: 'CRS'),
  DesignFormOption(id: 'Indian Railways CRS', label: 'Indian Railways CRS'),
  DesignFormOption(id: 'Con. HQ', label: 'Con. HQ'),
  DesignFormOption(id: 'PMS/PSSA/PMC', label: 'PMS/PSSA/PMC'),
  DesignFormOption(
    id: 'Construction Site Office',
    label: 'Construction Site Office',
  ),
  DesignFormOption(
    id: 'RDSO Drawing Approval Agency',
    label: 'RDSO Drawing Approval Agency',
  ),
  DesignFormOption(id: 'Site Office', label: 'Site Office'),
];

List<DesignFormOption> designFormOptionsFromDesign(
  List<DesignOption> options,
) {
  return options
      .map(
        (DesignOption option) =>
            DesignFormOption(id: option.value, label: option.label),
      )
      .toList(growable: false);
}

List<DesignFormOption> parseDesignFormProjects(dynamic data) {
  final Map<String, DesignFormOption> unique = <String, DesignFormOption>{};
  for (final Map<String, dynamic> json in _projectRecords(data)) {
    final String id = _scalar(
      json['project_id'] ?? json['projectId'] ?? json['project_id_fk'],
    );
    if (id.isEmpty) {
      continue;
    }
    final String name = _scalar(
      json['project_name'] ?? json['projectName'] ?? json['name'],
    );
    unique.putIfAbsent(
      id,
      () => DesignFormOption(id: id, label: name.isEmpty ? id : name),
    );
  }
  final List<DesignFormOption> values = unique.values.toList()
    ..sort(
      (DesignFormOption a, DesignFormOption b) =>
          a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );
  return values;
}

/// Validates required design form fields. Returns the first error message.
String? validateDesignForm({
  required String projectId,
  required String approvingRailwayId,
  required String structureTypeId,
  required String structureId,
  required String drawingTypeId,
  required String approvalAuthorityId,
  required String drawingTitle,
  required List<DesignStatusRowDraft> statusRows,
}) {
  if (projectId.trim().isEmpty) {
    return 'Please select a project.';
  }
  if (approvingRailwayId.trim().isEmpty) {
    return 'Please select an approving railway.';
  }
  if (structureTypeId.trim().isEmpty) {
    return 'Please select a structure type.';
  }
  if (structureId.trim().isEmpty) {
    return 'Please select a structure.';
  }
  if (drawingTypeId.trim().isEmpty) {
    return 'Please select a drawing type.';
  }
  if (approvalAuthorityId.trim().isEmpty) {
    return 'Please select an approval authority.';
  }
  if (drawingTitle.trim().isEmpty) {
    return 'Please enter a drawing title.';
  }
  if (drawingTitle.trim().length > 200) {
    return 'Drawing title must be at most 200 characters.';
  }
  if (statusRows.isEmpty) {
    return 'Please add at least one drawing status row.';
  }
  for (int i = 0; i < statusRows.length; i++) {
    if (statusRows[i].drawingNo.trim().isEmpty) {
      return 'Please enter Drawing No. for status row ${i + 1}.';
    }
  }
  return null;
}

List<Map<String, dynamic>> _projectRecords(dynamic data) {
  if (data is List) {
    return data
        .whereType<Map>()
        .map((Map item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    for (final String key in const <String>[
      'data',
      'result',
      'content',
      'list',
      'records',
      'projectList',
      'projectsList',
    ]) {
      final Object? nested = map[key];
      if (nested is List) {
        return _projectRecords(nested);
      }
    }
  }
  return const <Map<String, dynamic>>[];
}

String _scalar(Object? value) {
  if (value == null) {
    return '';
  }
  if (value is double) {
    if (value.isNaN || value.isInfinite) {
      return '';
    }
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
  }
  final String text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return '';
  }
  return text;
}
