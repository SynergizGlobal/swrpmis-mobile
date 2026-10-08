class RfiListItem {
  const RfiListItem({
    required this.id,
    required this.rfiId,
    required this.rfiCategory,
    required this.projectName,
    required this.item,
    required this.material,
    required this.location,
    required this.batchLotNo,
    required this.structure,
    required this.structureType,
    required this.element,
    required this.nameOfRepresentative,
    required this.assignedPersonClient,
    required this.contractName,
    required this.dateOfSubmission,
    required this.dateOfInspection,
    required this.timeOfInspection,
    required this.contractorSubmittedOn,
    required this.rfiStatus,
  });

  final int? id;
  final String rfiId;
  final String rfiCategory;
  final String projectName;
  final String item;
  final String material;
  final String location;
  final String batchLotNo;
  final String structure;
  final String structureType;
  final String element;
  final String nameOfRepresentative;
  final String assignedPersonClient;
  final String contractName;
  final String dateOfSubmission;
  final String dateOfInspection;
  final String timeOfInspection;
  final String contractorSubmittedOn;
  final String rfiStatus;

  String get scheduledText {
    final String date = dateOfInspection.trim();
    final String time = timeOfInspection.trim();
    if (date.isEmpty) {
      return time;
    }
    if (time.isEmpty) {
      return date;
    }
    return '$date $time';
  }

  String get statusLabel {
    final String text = rfiStatus.trim();
    if (text.isEmpty) {
      return '';
    }
    return text.replaceAll('_', ' ');
  }

  factory RfiListItem.fromJson(Map<String, dynamic> json) {
    return RfiListItem(
      id: _readId(json['id']),
      rfiId: _text(json['rfiId']),
      rfiCategory: _text(json['rfiCategory']),
      projectName: _text(json['projectName']),
      item: _text(json['item']),
      material: _text(json['material']),
      location: _text(json['location']),
      batchLotNo: _text(json['batchLotNo']),
      structure: _text(json['structure']),
      structureType: _text(json['structureType']),
      element: _text(json['element']),
      nameOfRepresentative: _text(json['nameOfRepresentative']),
      assignedPersonClient: _text(json['assignedPersonClient']),
      contractName: _text(json['contractName']),
      dateOfSubmission: _text(json['dateOfSubmission']),
      dateOfInspection: _text(json['dateOfInspection']),
      timeOfInspection: _text(json['timeOfInspection']),
      contractorSubmittedOn: _text(json['contractorSubmittedOn']),
      rfiStatus: _text(json['rfiStatus']),
    );
  }
}

int? _readId(Object? value) {
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
