import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_log_links.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_stored_file.dart';

class RfiLogReport {
  const RfiLogReport({
    required this.details,
    required this.workDetails,
    required this.measurement,
    required this.checklistItems,
    required this.enclosurePaths,
    required this.attachmentPaths,
  });

  final RfiLogReportDetails details;
  final List<RfiLogWorkDetail> workDetails;
  final RfiLogMeasurement? measurement;
  final List<RfiLogChecklistItem> checklistItems;
  final List<String> enclosurePaths;
  final List<String> attachmentPaths;

  bool get hasEnclosures =>
      enclosurePaths.isNotEmpty || attachmentPaths.isNotEmpty;

  List<RfiLogChecklistGroup> get checklistGroups {
    final Map<String, List<RfiLogChecklistItem>> grouped =
        <String, List<RfiLogChecklistItem>>{};
    for (final RfiLogChecklistItem item in checklistItems) {
      grouped
          .putIfAbsent(item.enclosureName, () => <RfiLogChecklistItem>[])
          .add(item);
    }
    return grouped.entries
        .map(
          (MapEntry<String, List<RfiLogChecklistItem>> entry) =>
              RfiLogChecklistGroup(
                enclosureName: entry.key,
                items: entry.value,
              ),
        )
        .toList(growable: false);
  }

  factory RfiLogReport.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> root = _unwrapMap(json);
    final Map<String, dynamic> details = _asMap(
      root['reportDetails'] ?? root['reportDetail'],
    );
    return RfiLogReport(
      details: RfiLogReportDetails.fromJson(details.isEmpty ? root : details),
      workDetails: _asList(root['workDetails'] ?? details['workDetails'])
          .whereType<Map>()
          .map(
            (Map item) =>
                RfiLogWorkDetail.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      measurement: _measurement(
        root['measurementDetails'] ?? details['measurementDetails'],
      ),
      checklistItems:
          _asList(root['checklistItems'] ?? details['checklistItems'])
              .whereType<Map>()
              .map(
                (Map item) => RfiLogChecklistItem.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(growable: false),
      enclosurePaths: _paths(root['enclosures'] ?? details['enclosures']),
      attachmentPaths: _paths(details['attachments'] ?? root['attachments']),
    );
  }
}

class RfiLogChecklistGroup {
  const RfiLogChecklistGroup({
    required this.enclosureName,
    required this.items,
  });

  final String enclosureName;
  final List<RfiLogChecklistItem> items;

  String titleFor(String rfiDescription) {
    final String name = enclosureName.trim();
    final String description = rfiDescription.trim();
    if (name.isEmpty) {
      return description;
    }
    if (description.isEmpty) {
      return name;
    }
    return '$name / $description';
  }
}

class RfiLogReportDetails {
  const RfiLogReportDetails({
    required this.rfiStatus,
    required this.consultant,
    required this.rfiId,
    required this.dateOfCreation,
    required this.project,
    required this.contract,
    required this.contractId,
    required this.structureType,
    required this.structure,
    required this.component,
    required this.element,
    required this.activity,
    required this.rfiDescription,
    required this.rfiCategory,
    required this.typeOfRfi,
    required this.enclosures,
    required this.contractor,
    required this.contractorRepresentative,
    required this.clientRepresentative,
    required this.chainage,
    required this.chainageFrom,
    required this.chainageTo,
    required this.proposedDateOfInspection,
    required this.proposedInspectionTime,
    required this.conInspDate,
    required this.conInspTime,
    required this.enggInspDate,
    required this.descriptionByContractor,
    required this.conLocation,
    required this.clientLocation,
    required this.typeOfTest,
    required this.testStatus,
    required this.dyHodUserName,
    required this.validationStatus,
    required this.remarks,
    required this.validationComments,
    required this.selfieContractor,
    required this.selfieClient,
    required this.testSiteDocumentsContractor,
  });

  final String rfiStatus;
  final String consultant;
  final String rfiId;
  final String dateOfCreation;
  final String project;
  final String contract;
  final String contractId;
  final String structureType;
  final String structure;
  final String component;
  final String element;
  final String activity;
  final String rfiDescription;
  final String rfiCategory;
  final String typeOfRfi;
  final String enclosures;
  final String contractor;
  final String contractorRepresentative;
  final String clientRepresentative;
  final String chainage;
  final String chainageFrom;
  final String chainageTo;
  final String proposedDateOfInspection;
  final String proposedInspectionTime;
  final String conInspDate;
  final String conInspTime;
  final String enggInspDate;
  final String descriptionByContractor;
  final String conLocation;
  final String clientLocation;
  final String typeOfTest;
  final String testStatus;
  final String dyHodUserName;
  final String validationStatus;
  final String remarks;
  final String validationComments;
  final String selfieContractor;
  final String selfieClient;
  final String testSiteDocumentsContractor;

  String get statusText {
    if (rfiStatus.isEmpty) {
      return '';
    }
    return rfiStatus.replaceAll('_', ' ');
  }

  String get scheduledText {
    final String date = proposedDateOfInspection.trim();
    final String time = proposedInspectionTime.trim();
    if (date.isEmpty) {
      return time;
    }
    if (time.isEmpty) {
      return date;
    }
    return '$date $time';
  }

  String get chainageText {
    if (chainage.isNotEmpty) {
      return chainage;
    }
    if (chainageFrom.isNotEmpty && chainageTo.isNotEmpty) {
      return '$chainageFrom–$chainageTo';
    }
    return '';
  }

  bool get selfieContractorIsUrl => RfiStoredFile.isHttpUrl(selfieContractor);

  bool get selfieClientIsUrl => RfiStoredFile.isHttpUrl(selfieClient);

  factory RfiLogReportDetails.fromJson(Map<String, dynamic> json) {
    return RfiLogReportDetails(
      rfiStatus: _text(json['rfiStatus']),
      consultant: _text(json['consultant']),
      rfiId: _text(json['rfiId']),
      dateOfCreation: _text(json['dateOfCreation']),
      project: _text(json['project']),
      contract: _text(json['contract']),
      contractId: _text(json['contractId']),
      structureType: _text(json['structureType']),
      structure: _text(json['structure']),
      component: _text(json['component']),
      element: _text(json['element']),
      activity: _text(json['activity']),
      rfiDescription: _text(json['rfiDescription']),
      rfiCategory: _text(json['rfiCategory']),
      typeOfRfi: _text(json['typeOfRfi']),
      enclosures: _text(json['enclosures']),
      contractor: _text(json['contractor']),
      contractorRepresentative: _text(json['contractorRepresentative']),
      clientRepresentative: _text(json['clientRepresentative']),
      chainage: _text(json['chainage']),
      chainageFrom: _firstText(json, const <String>[
        'chainageFrom',
        'fromChainage',
        'from',
      ]),
      chainageTo: _firstText(json, const <String>[
        'chainageTo',
        'toChainage',
        'to',
      ]),
      proposedDateOfInspection: _text(json['proposedDateOfInspection']),
      proposedInspectionTime: _text(json['proposedInspectionTime']),
      conInspDate: _text(json['conInspDate']),
      conInspTime: _text(json['conInspTime']),
      enggInspDate: _text(json['enggInspDate']),
      descriptionByContractor: _text(json['descriptionByContractor']),
      conLocation: _text(json['conLocation']),
      clientLocation: _text(json['clientLocation']),
      typeOfTest: _text(json['typeOfTest']),
      testStatus: _text(json['testStatus']),
      dyHodUserName: _text(json['dyHodUserName']),
      validationStatus: _text(json['validationStatus']),
      remarks: _text(json['remarks']),
      validationComments: _text(json['validationComments']),
      selfieContractor: _text(json['selfieContractor']),
      selfieClient: _text(json['selfieClient']),
      testSiteDocumentsContractor: _text(json['testSiteDocumentsContractor']),
    );
  }
}

class RfiLogWorkDetail {
  const RfiLogWorkDetail({
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

  factory RfiLogWorkDetail.fromJson(Map<String, dynamic> json) {
    return RfiLogWorkDetail(
      activityName: _text(json['activityName'] ?? json['activity']),
      unit: _text(json['unit'] ?? json['units']),
      scope: rfiLogQuantityText(json['scope']),
      completedTillDate: rfiLogQuantityText(
        json['completedTillDate'] ?? json['completedTill'],
      ),
      inspectionQuantity: rfiLogQuantityText(
        json['inspectionQuantity'] ?? json['inspectionQty'],
      ),
    );
  }
}

class RfiLogMeasurement {
  const RfiLogMeasurement({
    required this.measurementType,
    required this.units,
    required this.length,
    required this.breadth,
    required this.height,
    required this.weight,
    required this.count,
    required this.totalQty,
  });

  final String measurementType;
  final String units;
  final String length;
  final String breadth;
  final String height;
  final String weight;
  final String count;
  final String totalQty;

  factory RfiLogMeasurement.fromJson(Map<String, dynamic> json) {
    return RfiLogMeasurement(
      measurementType: _text(json['measurementType'] ?? json['type']),
      units: _text(json['units'] ?? json['unit']),
      length: rfiLogQuantityText(json['l'] ?? json['length']),
      breadth: rfiLogQuantityText(json['b'] ?? json['breadth']),
      height: rfiLogQuantityText(json['h'] ?? json['height']),
      weight: rfiLogQuantityText(json['weight']),
      count: rfiLogQuantityText(json['no'] ?? json['count']),
      totalQty: rfiLogQuantityText(json['totalQty'] ?? json['totalQuantity']),
    );
  }
}

class RfiLogChecklistItem {
  const RfiLogChecklistItem({
    required this.enclosureName,
    required this.checklistDescription,
    required this.conStatus,
    required this.aeStatus,
    required this.contractorRemark,
    required this.aeRemark,
  });

  final String enclosureName;
  final String checklistDescription;
  final String conStatus;
  final String aeStatus;
  final String contractorRemark;
  final String aeRemark;

  factory RfiLogChecklistItem.fromJson(Map<String, dynamic> json) {
    return RfiLogChecklistItem(
      enclosureName: _text(json['enclosureName']),
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

String rfiLogQuantityText(Object? value) {
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

String rfiLogPdfText(String value) {
  final String text = value.trim();
  if (text.isEmpty) {
    return RfiLogLinks.pdfBlank;
  }
  return text;
}

String rfiLogDialogText(
  String value, {
  String empty = RfiLogLinks.dialogBlank,
}) {
  final String text = value.trim();
  if (text.isEmpty) {
    return empty;
  }
  return text;
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

RfiLogMeasurement? _measurement(Object? value) {
  if (value is List) {
    for (final Object? item in value) {
      if (item is Map) {
        return RfiLogMeasurement.fromJson(Map<String, dynamic>.from(item));
      }
    }
    return null;
  }
  if (value is Map) {
    return RfiLogMeasurement.fromJson(Map<String, dynamic>.from(value));
  }
  return null;
}

List<String> _paths(Object? value) {
  final List<String> paths = <String>[];
  void add(Object? raw) {
    final String text = _text(raw);
    if (text.isNotEmpty) {
      paths.add(text);
    }
  }

  if (value is List) {
    for (final Object? item in value) {
      if (item is Map) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(item);
        add(map['filePath'] ?? map['file'] ?? map['path']);
      } else {
        add(item);
      }
    }
    return paths;
  }
  if (value is Map) {
    add(
      Map<String, dynamic>.from(value)['filePath'] ??
          Map<String, dynamic>.from(value)['file'],
    );
    return paths;
  }
  add(value);
  return paths;
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

String _firstText(Map<String, dynamic> json, List<String> keys) {
  for (final String key in keys) {
    final String text = _text(json[key]);
    if (text.isNotEmpty) {
      return text;
    }
  }
  return '';
}
