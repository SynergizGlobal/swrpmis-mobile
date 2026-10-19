class RfiInspectionDetails {
  const RfiInspectionDetails({
    required this.rfi,
    required this.enclosures,
    required this.measurements,
    required this.attachments,
    required this.materialDetails,
    required this.workDetails,
  });

  final RfiInspectionDetailRfi rfi;
  final List<RfiInspectionEnclosure> enclosures;
  final List<RfiInspectionMeasurement> measurements;
  final List<Map<String, dynamic>> attachments;
  final List<Map<String, dynamic>> materialDetails;
  final List<Map<String, dynamic>> workDetails;

  factory RfiInspectionDetails.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> rfiJson = _map(json['rfi']) ?? json;
    return RfiInspectionDetails(
      rfi: RfiInspectionDetailRfi.fromJson(rfiJson),
      enclosures: _listMaps(json['enclosures'])
          .map(RfiInspectionEnclosure.fromJson)
          .toList(growable: false),
      measurements: _parseMeasurements(json['measurements']),
      attachments: _listMaps(json['attachments']),
      materialDetails: _listMaps(json['materialDetails']),
      workDetails: _listMaps(json['workDetails']),
    );
  }
}

class RfiInspectionDetailRfi {
  const RfiInspectionDetailRfi({
    required this.id,
    required this.rfiId,
    required this.project,
    required this.contract,
    required this.structureType,
    required this.structure,
    required this.description,
    required this.rfiDescription,
    required this.rfiCategory,
    required this.dateOfInspection,
    required this.timeOfInspection,
    required this.nameOfRepresentative,
    required this.chainage,
    required this.location,
    required this.inspectionMode,
    required this.testInSiteOrLab,
    required this.conSiteImgs,
    required this.enggSiteImgs,
    required this.conSupDocs,
    required this.enggSupDocs,
    required this.conInspectionId,
    required this.component,
  });

  final int? id;
  final String rfiId;
  final String project;
  final String contract;
  final String structureType;
  final String structure;
  final String description;
  final String rfiDescription;
  final String rfiCategory;
  final String dateOfInspection;
  final String timeOfInspection;
  final String nameOfRepresentative;
  final String chainage;
  final String location;
  final String inspectionMode;
  final String testInSiteOrLab;
  final List<String> conSiteImgs;
  final List<String> enggSiteImgs;
  final List<RfiSupportingDocument> conSupDocs;
  final List<RfiSupportingDocument> enggSupDocs;
  final int? conInspectionId;
  final String component;

  factory RfiInspectionDetailRfi.fromJson(Map<String, dynamic> json) {
    final String underscored = _text(json['rfi_Id']);
    return RfiInspectionDetailRfi(
      id: _int(json['id']),
      rfiId: underscored.isEmpty ? _text(json['rfiId']) : underscored,
      project: _firstText(json, const <String>['project', 'projectName']),
      contract: _firstText(json, const <String>['contract', 'contractName']),
      structureType: _text(json['structureType']),
      structure: _text(json['structure']),
      description: _text(json['description']),
      rfiDescription: _text(json['rfiDescription']),
      rfiCategory: _text(json['rfiCategory']),
      dateOfInspection: _text(json['dateOfInspection']),
      timeOfInspection: _text(json['timeOfInspection']),
      nameOfRepresentative: _text(json['nameOfRepresentative']),
      chainage: _text(json['chainage']),
      location: _firstText(json, const <String>['location', 'conLocation']),
      inspectionMode: _text(json['inspectionMode']),
      testInSiteOrLab: _firstText(json, const <String>[
        'testInSiteOrLab',
        'testInsiteLab',
        'testInSiteLab',
      ]),
      conSiteImgs: _stringList(json['conSiteImgs']),
      enggSiteImgs: _stringList(json['enggSiteImgs']),
      conSupDocs: _supportingDocs(json['conSupDocs']),
      enggSupDocs: _supportingDocs(json['enggSupDocs']),
      conInspectionId: _int(json['conInspectionId']),
      component: _firstText(json, const <String>['component', 'element']),
    );
  }
}

class RfiInspectionEnclosure {
  const RfiInspectionEnclosure({
    required this.action,
    required this.enclosureName,
    required this.rfiDescription,
    required this.rfiId,
    required this.enclosureId,
    required this.rfiDescriptionId,
    required this.enclosureUploadedFileId,
    required this.enclosureUploadedFile,
  });

  final String action;
  final String enclosureName;
  final String rfiDescription;
  final int? rfiId;
  final int? enclosureId;
  final int? rfiDescriptionId;
  final int? enclosureUploadedFileId;
  final String enclosureUploadedFile;

  bool get hasUploadAction =>
      action.toLowerCase().contains('upload');

  bool get hasOpenAction => action.toLowerCase().contains('open');

  bool get hasUploadedFile =>
      enclosureUploadedFileId != null || enclosureUploadedFile.isNotEmpty;

  factory RfiInspectionEnclosure.fromJson(Map<String, dynamic> json) {
    return RfiInspectionEnclosure(
      action: _text(json['action']),
      enclosureName: _firstText(json, const <String>[
        'encloserName',
        'enclosureName',
      ]),
      rfiDescription: _text(json['rfiDescription']),
      rfiId: _int(json['rfiId']),
      enclosureId: _int(json['enclosureId']),
      rfiDescriptionId: _int(json['rfiDescriptionId']),
      enclosureUploadedFileId: _int(json['enclosureUploadedFileId']),
      enclosureUploadedFile: _text(json['enclosureUploadedFile']),
    );
  }
}

class RfiInspectionMeasurement {
  const RfiInspectionMeasurement({
    required this.activityName,
    required this.measurementType,
    required this.units,
    required this.length,
    required this.breadth,
    required this.height,
    required this.weight,
    required this.noOfItems,
    required this.totalQty,
  });

  final String activityName;
  final String measurementType;
  final String units;
  final String length;
  final String breadth;
  final String height;
  final String weight;
  final String noOfItems;
  final double totalQty;

  factory RfiInspectionMeasurement.fromJson(Map<String, dynamic> json) {
    return RfiInspectionMeasurement(
      activityName: _firstText(json, const <String>[
        'activityName',
        'activity',
        'rfiDescription',
      ]),
      measurementType: _firstText(json, const <String>[
        'measurementType',
        'typeOfMeasurement',
        'type',
      ]),
      units: _text(json['units']),
      length: _numText(json['length'] ?? json['l']),
      breadth: _numText(json['breadth'] ?? json['b']),
      height: _numText(json['height'] ?? json['h']),
      weight: _numText(json['weight']),
      noOfItems: _numText(json['noOfItems'] ?? json['no']),
      totalQty: _double(json['totalQty']) ?? 0,
    );
  }
}

class RfiSupportingDocument {
  const RfiSupportingDocument({
    required this.path,
    required this.description,
    this.id,
  });

  final int? id;
  final String path;
  final String description;

  factory RfiSupportingDocument.fromJson(Map<String, dynamic> json) {
    return RfiSupportingDocument(
      id: _int(json['id'] ?? json['fileId']),
      path: _firstText(json, const <String>[
        'path',
        'filePath',
        'supportingDocuments',
        'file',
        'url',
      ]),
      description: _firstText(json, const <String>[
        'description',
        'documentsDescription',
        'documentDescription',
      ]),
    );
  }
}

List<RfiInspectionMeasurement> _parseMeasurements(Object? value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map(
          (Map<dynamic, dynamic> item) =>
              RfiInspectionMeasurement.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
  }
  if (value is Map) {
    return <RfiInspectionMeasurement>[
      RfiInspectionMeasurement.fromJson(Map<String, dynamic>.from(value)),
    ];
  }
  return const <RfiInspectionMeasurement>[];
}

List<RfiSupportingDocument> _supportingDocs(Object? value) {
  if (value is! List) {
    return const <RfiSupportingDocument>[];
  }
  return value
      .map((Object? item) {
        if (item is Map) {
          return RfiSupportingDocument.fromJson(
            Map<String, dynamic>.from(item),
          );
        }
        if (item is String && item.trim().isNotEmpty) {
          return RfiSupportingDocument(path: item.trim(), description: '');
        }
        return null;
      })
      .whereType<RfiSupportingDocument>()
      .toList(growable: false);
}

List<Map<String, dynamic>> _listMaps(Object? value) {
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }
  return value
      .whereType<Map>()
      .map((Map<dynamic, dynamic> item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

Map<String, dynamic>? _map(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

List<String> _stringList(Object? value) {
  if (value is! List) {
    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(',')
          .map((String part) => part.trim())
          .where((String part) => part.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }
  return value
      .map((Object? item) => _text(item))
      .where((String item) => item.isNotEmpty)
      .toList(growable: false);
}

int? _int(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim());
  }
  return null;
}

double? _double(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.trim());
  }
  return null;
}

String _numText(Object? value) {
  if (value == null) {
    return '';
  }
  if (value is num) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }
  return _text(value);
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
