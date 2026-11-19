import 'dart:convert';

import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_log_links.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_stored_file.dart';

/// Parsed `GET /api/validation/getRfiReportDetail/{longRfiId}` payload.
class RfiValidationReport {
  const RfiValidationReport({
    required this.details,
    required this.checklistGroups,
    required this.enclosures,
    required this.measurementDetails,
    required this.materialDetails,
    required this.workDetails,
    required this.validationList,
  });

  final RfiValidationReportDetails details;
  final List<RfiValidationChecklistGroup> checklistGroups;
  final List<RfiValidationEnclosureFile> enclosures;
  final List<RfiValidationMeasurement> measurementDetails;
  final List<RfiValidationMaterialDetail> materialDetails;
  final List<RfiValidationWorkDetail> workDetails;
  final List<RfiValidationHistoryRow> validationList;

  String get reportFileName {
    final String id = details.rfiId.trim();
    if (id.isEmpty) {
      return 'RfiReport.pdf';
    }
    return '${id}_RfiReport.pdf';
  }

  factory RfiValidationReport.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> root = _unwrapMap(json);
    final Map<String, dynamic> details = _asMap(
      root['reportDetails'] ?? root['reportDetail'],
    );
    return RfiValidationReport(
      details: RfiValidationReportDetails.fromJson(
        details.isEmpty ? root : details,
      ),
      checklistGroups: _checklistGroups(
        root['checklistItems'] ?? details['checklistItems'],
      ),
      enclosures: _enclosures(root['enclosures'] ?? details['enclosures']),
      measurementDetails: _measurements(
        root['measurementDetails'] ?? details['measurementDetails'],
      ),
      materialDetails: _materials(
        root['materialDetails'] ?? details['materialDetails'],
      ),
      workDetails: _workDetails(root['workDetails'] ?? details['workDetails']),
      validationList: _validationList(
        root['validationList'] ?? details['validationList'],
      ),
    );
  }
}

class RfiValidationReportDetails {
  const RfiValidationReportDetails({
    required this.project,
    required this.consultant,
    required this.contract,
    required this.rfiCategory,
    required this.contractor,
    required this.contractId,
    required this.rfiId,
    required this.rfiStatus,
    required this.conInspectedOn,
    required this.enggInspectedOn,
    required this.location,
    required this.proposedInspectionDate,
    required this.proposedInspectionTime,
    required this.rfiDescription,
    required this.enclosures,
    required this.item,
    required this.material,
    required this.rfiRequired,
    required this.fddTestPitNos,
    required this.fieldCompactionPercentage,
    required this.manpowerDeployment,
    required this.mpDeploymentDetails,
    required this.contractorRepresentative,
    required this.clientRepresentative,
    required this.descriptionByContractor,
    required this.validationStatus,
    required this.remarks,
    required this.validationComments,
    required this.selfieClient,
    required this.selfieContractor,
    required this.imagesUploadedByClient,
    required this.imagesUploadedByContractor,
    required this.testType,
    required this.testStatus,
    required this.testSiteDocumentsContractor,
    required this.testResultContractor,
    required this.testResultEngineer,
    required this.conSupportFilePaths,
    required this.enggSupportFilePaths,
    required this.attachments,
  });

  final String project;
  final String consultant;
  final String contract;
  final String rfiCategory;
  final String contractor;
  final String contractId;
  final String rfiId;
  final String rfiStatus;
  final String conInspectedOn;
  final String enggInspectedOn;
  final String location;
  final String proposedInspectionDate;
  final String proposedInspectionTime;
  final String rfiDescription;
  final String enclosures;
  final String item;
  final String material;
  final String rfiRequired;
  final String fddTestPitNos;
  final String fieldCompactionPercentage;
  final String manpowerDeployment;
  final String mpDeploymentDetails;
  final String contractorRepresentative;
  final String clientRepresentative;
  final String descriptionByContractor;
  final String validationStatus;
  final String remarks;
  final String validationComments;
  final String selfieClient;
  final String selfieContractor;
  final String imagesUploadedByClient;
  final String imagesUploadedByContractor;
  final String testType;
  final String testStatus;
  final String testSiteDocumentsContractor;
  final String testResultContractor;
  final String testResultEngineer;
  final String conSupportFilePaths;
  final String enggSupportFilePaths;
  final List<RfiValidationAttachment> attachments;

  List<String> get contractorSelfiePaths => splitRfiValidationPaths(selfieContractor);

  List<String> get clientSelfiePaths => splitRfiValidationPaths(selfieClient);

  List<String> get contractorSiteImagePaths =>
      splitRfiValidationPaths(imagesUploadedByContractor);

  List<String> get clientSiteImagePaths =>
      splitRfiValidationPaths(imagesUploadedByClient);

  /// Web preview/PDF status chip (Active / Closed / Rejected / Deleted).
  String get displayStatus {
    final String status = rfiStatus.trim().toUpperCase();
    final String test = testStatus.trim();
    final String validation = validationStatus.trim().toUpperCase();
    if (status == 'DELETED') {
      return 'Deleted';
    }
    if (test.toLowerCase() == 'rejected' || validation == 'REJECTED') {
      return 'Rejected';
    }
    if (status == 'INSPECTION_DONE') {
      return 'Closed';
    }
    return 'Active';
  }

  factory RfiValidationReportDetails.fromJson(Map<String, dynamic> json) {
    return RfiValidationReportDetails(
      project: _text(json['project']),
      consultant: _text(json['consultant']),
      contract: _text(json['contract']),
      rfiCategory: _text(json['rfiCategory']),
      contractor: _text(json['contractor']),
      contractId: _text(json['contractId']),
      rfiId: _text(json['rfiId']),
      rfiStatus: _text(json['rfiStatus']),
      conInspectedOn: _text(json['conInspectedOn']),
      enggInspectedOn: _text(json['enggInspectedOn']),
      location: _text(json['location']),
      proposedInspectionDate: _text(
        json['proposedInspectionDate'] ?? json['proposedDateOfInspection'],
      ),
      proposedInspectionTime: _text(json['proposedInspectionTime']),
      rfiDescription: _text(json['rfiDescription']),
      enclosures: _text(json['enclosures']),
      item: _text(json['item']),
      material: _text(json['material']),
      rfiRequired: _text(json['rfiRequired']),
      fddTestPitNos: _text(json['fddTestPitNos']),
      fieldCompactionPercentage: _text(json['fieldCompactionPercentage']),
      manpowerDeployment: _text(json['manpowerDeployment']),
      mpDeploymentDetails: _text(json['mpDeploymentDetails']),
      contractorRepresentative: _text(json['contractorRepresentative']),
      clientRepresentative: _text(json['clientRepresentative']),
      descriptionByContractor: _text(json['descriptionByContractor']),
      validationStatus: _text(json['validationStatus']),
      remarks: _text(json['remarks']),
      validationComments: _text(json['validationComments']),
      selfieClient: _text(json['selfieClient']),
      selfieContractor: _text(json['selfieContractor']),
      imagesUploadedByClient: _text(json['imagesUploadedByClient']),
      imagesUploadedByContractor: _text(json['imagesUploadedByContractor']),
      testType: _text(json['testType']),
      testStatus: _text(json['testStatus']),
      testSiteDocumentsContractor: _text(json['testSiteDocumentsContractor']),
      testResultContractor: _text(json['testResultContractor']),
      testResultEngineer: _text(json['testResultEngineer']),
      conSupportFilePaths: _text(json['conSupportFilePaths']),
      enggSupportFilePaths: _text(json['enggSupportFilePaths']),
      attachments: _attachments(
        json['attachments'],
        fallbackData: json['attachmentData'],
      ),
    );
  }
}

class RfiValidationAttachment {
  const RfiValidationAttachment({
    required this.fileName,
    required this.description,
  });

  final String fileName;
  final String description;
}

class RfiValidationChecklistGroup {
  const RfiValidationChecklistGroup({
    required this.rfiDescription,
    required this.enclosureName,
    required this.gradeOfConcrete,
    required this.checklist,
  });

  final String rfiDescription;
  final String enclosureName;
  final String gradeOfConcrete;
  final List<RfiValidationChecklistRow> checklist;
}

class RfiValidationChecklistRow {
  const RfiValidationChecklistRow({
    required this.checklistDescription,
    required this.conStatus,
    required this.aeStatus,
    required this.contractorRemark,
    required this.aeRemark,
  });

  final String checklistDescription;
  final String conStatus;
  final String aeStatus;
  final String contractorRemark;
  final String aeRemark;

  factory RfiValidationChecklistRow.fromJson(Map<String, dynamic> json) {
    return RfiValidationChecklistRow(
      checklistDescription: _text(
        json['checklistDescription'] ?? json['description'],
      ),
      conStatus: _text(json['conStatus'] ?? json['contractorStatus']),
      aeStatus: _text(json['aeStatus']),
      contractorRemark: _text(
        json['contractorRemark'] ??
            json['contractorRemarks'] ??
            json['conRemark'],
      ),
      aeRemark: _text(json['aeRemark'] ?? json['aeRemarks']),
    );
  }
}

class RfiValidationEnclosureFile {
  const RfiValidationEnclosureFile({
    required this.rfiDescription,
    required this.enclosureName,
    required this.file,
  });

  final String rfiDescription;
  final String enclosureName;
  final String file;

  factory RfiValidationEnclosureFile.fromJson(Map<String, dynamic> json) {
    return RfiValidationEnclosureFile(
      rfiDescription: _text(json['rfiDescription']),
      enclosureName: _text(json['enclosureName']),
      file: _text(json['file'] ?? json['filePath'] ?? json['path']),
    );
  }
}

class RfiValidationMeasurement {
  const RfiValidationMeasurement({
    required this.component,
    required this.element,
    required this.activityName,
    required this.measurementType,
    required this.units,
    required this.length,
    required this.breadth,
    required this.height,
    required this.weight,
    required this.count,
    required this.totalQty,
  });

  final String component;
  final String element;
  final String activityName;
  final String measurementType;
  final String units;
  final String length;
  final String breadth;
  final String height;
  final String weight;
  final String count;
  final String totalQty;

  factory RfiValidationMeasurement.fromJson(Map<String, dynamic> json) {
    return RfiValidationMeasurement(
      component: _text(json['component']),
      element: _text(json['element']),
      activityName: _text(json['activityName'] ?? json['activity']),
      measurementType: _text(json['measurementType'] ?? json['type']),
      units: _text(json['units'] ?? json['unit']),
      length: _qty(json['l'] ?? json['length']),
      breadth: _qty(json['b'] ?? json['breadth']),
      height: _qty(json['h'] ?? json['height']),
      weight: _qty(json['weight']),
      count: _qty(json['no'] ?? json['count']),
      totalQty: _qty(json['totalQty'] ?? json['totalQuantity']),
    );
  }
}

class RfiValidationWorkDetail {
  const RfiValidationWorkDetail({
    required this.activityName,
    required this.unit,
    required this.scope,
    required this.completedTillDate,
    required this.inspectionQuantity,
  });

  final String activityName;
  final String unit;
  final String scope;
  final String completedTillDate;
  final String inspectionQuantity;

  factory RfiValidationWorkDetail.fromJson(Map<String, dynamic> json) {
    return RfiValidationWorkDetail(
      activityName: _text(json['activityName'] ?? json['activity']),
      unit: _text(json['unit'] ?? json['units']),
      scope: _qty(json['scope']),
      completedTillDate: _qty(
        json['completedTillDate'] ?? json['completedTill'],
      ),
      inspectionQuantity: _qty(
        json['inspectionQuantity'] ?? json['inspectionQty'],
      ),
    );
  }
}

class RfiValidationMaterialDetail {
  const RfiValidationMaterialDetail({
    required this.material,
    required this.inspectionQuantity,
  });

  final String material;
  final String inspectionQuantity;

  factory RfiValidationMaterialDetail.fromJson(Map<String, dynamic> json) {
    return RfiValidationMaterialDetail(
      material: _text(json['material']),
      inspectionQuantity: _qty(
        json['inspectionQuantity'] ?? json['inspectionQty'],
      ),
    );
  }
}

class RfiValidationHistoryRow {
  const RfiValidationHistoryRow({
    required this.validationType,
    required this.validatorName,
    required this.status,
    required this.validatedOn,
    required this.remarks,
    required this.comment,
  });

  final String validationType;
  final String validatorName;
  final String status;
  final String validatedOn;
  final String remarks;
  final String comment;

  factory RfiValidationHistoryRow.fromJson(Map<String, dynamic> json) {
    return RfiValidationHistoryRow(
      validationType: _text(json['validationType']),
      validatorName: _text(json['validatorName']),
      status: _text(json['status']),
      validatedOn: _text(json['validatedOn']),
      remarks: _text(json['remarks']),
      comment: _text(json['comment']),
    );
  }
}

/// Empty / null → `---` (web preview and PDF).
String rfiValidationBlank(String? value) {
  final String text = (value ?? '').trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return RfiLogLinks.pdfBlank;
  }
  return text;
}

List<String> splitRfiValidationPaths(String? raw) {
  final String text = (raw ?? '').trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return const <String>[];
  }
  if (text.startsWith('[')) {
    try {
      final Object? decoded = _tryJsonList(text);
      if (decoded is List) {
        return decoded
            .map((Object? item) {
              if (item is Map) {
                final Map<String, dynamic> map = Map<String, dynamic>.from(
                  item,
                );
                return _text(
                  map['filePath'] ?? map['file'] ?? map['fileName'] ?? map['path'],
                );
              }
              return _text(item);
            })
            .where((String path) => path.isNotEmpty)
            .toList(growable: false);
      }
    } on Object {
      // Fall through to delimiter split.
    }
  }
  final String delimiter = text.contains('||') ? '||' : ',';
  return text
      .split(delimiter)
      .map((String part) => part.trim())
      .where((String part) => part.isNotEmpty && part.toLowerCase() != 'null')
      .toList(growable: false);
}

Map<String, dynamic> _unwrapMap(Map<String, dynamic> json) {
  if (json.containsKey('reportDetails') || json.containsKey('checklistItems')) {
    return json;
  }
  final Object? nested = json['data'] ?? json['result'];
  if (nested is Map) {
    return Map<String, dynamic>.from(nested);
  }
  return json;
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return <String, dynamic>{};
}

List<dynamic> _asList(Object? value) {
  if (value is List) {
    return value;
  }
  if (value is Map) {
    return <dynamic>[value];
  }
  return const <dynamic>[];
}

List<RfiValidationChecklistGroup> _checklistGroups(Object? value) {
  final List<RfiValidationChecklistGroup> groups =
      <RfiValidationChecklistGroup>[];
  for (final Object? item in _asList(value)) {
    if (item is! Map) {
      continue;
    }
    final Map<String, dynamic> map = Map<String, dynamic>.from(item);
    final Object? nested = map['checklist'];
    if (nested is List) {
      groups.add(
        RfiValidationChecklistGroup(
          rfiDescription: _text(map['rfiDescription']),
          enclosureName: _text(map['enclosureName']),
          gradeOfConcrete: _text(map['gradeOfConcrete']),
          checklist: nested
              .whereType<Map>()
              .map(
                (Map row) => RfiValidationChecklistRow.fromJson(
                  Map<String, dynamic>.from(row),
                ),
              )
              .toList(growable: false),
        ),
      );
      continue;
    }
    // Flat checklist item (log-style) → one group bucket by enclosure.
    final RfiValidationChecklistRow row = RfiValidationChecklistRow.fromJson(
      map,
    );
    final String enclosure = _text(map['enclosureName']);
    final int index = groups.indexWhere(
      (RfiValidationChecklistGroup g) => g.enclosureName == enclosure,
    );
    if (index >= 0) {
      groups[index] = RfiValidationChecklistGroup(
        rfiDescription: groups[index].rfiDescription,
        enclosureName: enclosure,
        gradeOfConcrete: groups[index].gradeOfConcrete,
        checklist: <RfiValidationChecklistRow>[
          ...groups[index].checklist,
          row,
        ],
      );
    } else {
      groups.add(
        RfiValidationChecklistGroup(
          rfiDescription: _text(map['rfiDescription']),
          enclosureName: enclosure,
          gradeOfConcrete: _text(map['gradeOfConcrete']),
          checklist: <RfiValidationChecklistRow>[row],
        ),
      );
    }
  }
  return groups;
}

List<RfiValidationEnclosureFile> _enclosures(Object? value) {
  return _asList(value)
      .whereType<Map>()
      .map(
        (Map item) => RfiValidationEnclosureFile.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
      .where((RfiValidationEnclosureFile e) => e.file.isNotEmpty)
      .toList(growable: false);
}

List<RfiValidationMeasurement> _measurements(Object? value) {
  Object? raw = value;
  if (raw is List &&
      raw.length == 1 &&
      raw.first is List) {
    raw = raw.first;
  }
  return _asList(raw)
      .whereType<Map>()
      .map(
        (Map item) =>
            RfiValidationMeasurement.fromJson(Map<String, dynamic>.from(item)),
      )
      .toList(growable: false);
}

List<RfiValidationWorkDetail> _workDetails(Object? value) {
  return _asList(value)
      .whereType<Map>()
      .map(
        (Map item) =>
            RfiValidationWorkDetail.fromJson(Map<String, dynamic>.from(item)),
      )
      .toList(growable: false);
}

List<RfiValidationMaterialDetail> _materials(Object? value) {
  return _asList(value)
      .whereType<Map>()
      .map(
        (Map item) => RfiValidationMaterialDetail.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
      .toList(growable: false);
}

List<RfiValidationHistoryRow> _validationList(Object? value) {
  return _asList(value)
      .whereType<Map>()
      .map(
        (Map item) =>
            RfiValidationHistoryRow.fromJson(Map<String, dynamic>.from(item)),
      )
      .toList(growable: false);
}

List<RfiValidationAttachment> _attachments(
  Object? value, {
  Object? fallbackData,
}) {
  final List<RfiValidationAttachment> out = <RfiValidationAttachment>[];
  if (value is List) {
    for (final Object? item in value) {
      if (item is Map) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(item);
        final String fileName = _text(
          map['fileName'] ?? map['file'] ?? map['filePath'] ?? map['name'],
        );
        if (fileName.isEmpty) {
          continue;
        }
        out.add(
          RfiValidationAttachment(
            fileName: fileName,
            description: _text(map['description'] ?? map['desc']),
          ),
        );
      } else {
        final String fileName = _text(item);
        if (fileName.isNotEmpty) {
          out.add(
            RfiValidationAttachment(fileName: fileName, description: ''),
          );
        }
      }
    }
  }
  if (out.isNotEmpty) {
    return out;
  }
  final String raw = _text(fallbackData);
  if (raw.isEmpty) {
    return const <RfiValidationAttachment>[];
  }
  // `file.pdf::desc##file2.pdf::desc2##`
  for (final String chunk in raw.split('##')) {
    final String part = chunk.trim();
    if (part.isEmpty) {
      continue;
    }
    final int sep = part.indexOf('::');
    if (sep < 0) {
      final String name = RfiStoredFile.fileName(part);
      if (name.isNotEmpty) {
        out.add(RfiValidationAttachment(fileName: name, description: ''));
      }
      continue;
    }
    final String fileName = RfiStoredFile.fileName(part.substring(0, sep));
    final String description = part.substring(sep + 2).trim();
    if (fileName.isNotEmpty) {
      out.add(
        RfiValidationAttachment(
          fileName: fileName,
          description: description,
        ),
      );
    }
  }
  return out;
}

String _text(Object? value) {
  if (value == null) {
    return '';
  }
  final String text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return '';
  }
  return text;
}

String _qty(Object? value) {
  if (value == null) {
    return '';
  }
  if (value is num) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }
  final String text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return '';
  }
  final num? parsed = num.tryParse(text);
  if (parsed == null) {
    return text;
  }
  if (parsed == parsed.roundToDouble()) {
    return parsed.toInt().toString();
  }
  return text;
}

Object? _tryJsonList(String text) {
  return jsonDecode(text);
}
