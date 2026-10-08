import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_list_item.dart';

class RfiInspectionRow {
  const RfiInspectionRow({
    required this.id,
    required this.rfiId,
    required this.rfiCategory,
    required this.projectName,
    required this.contractName,
    required this.structure,
    required this.structureType,
    required this.element,
    required this.description,
    required this.contractor,
    required this.assignedPersonClient,
    required this.dateOfSubmission,
    required this.dateOfInspection,
    required this.timeOfInspection,
    required this.contractorSubmittedOn,
    required this.measurementType,
    required this.totalQty,
    required this.status,
    required this.inspectionStatus,
    required this.action,
  });

  final int? id;
  final String rfiId;
  final String rfiCategory;
  final String projectName;
  final String contractName;
  final String structure;
  final String structureType;
  final String element;
  final String description;
  final String contractor;
  final String assignedPersonClient;
  final String dateOfSubmission;
  final String dateOfInspection;
  final String timeOfInspection;
  final String contractorSubmittedOn;
  final String measurementType;
  final double? totalQty;
  final String status;
  final String inspectionStatus;
  final String action;

  bool get hasQty => totalQty != null;

  String get qtyText => formatInspectionQty(totalQty);

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
    final String text = status.trim();
    if (text.isEmpty) {
      return '';
    }
    return text.replaceAll('_', ' ');
  }

  RfiListItem toListItem() {
    return RfiListItem(
      id: id,
      rfiId: rfiId,
      rfiCategory: rfiCategory,
      projectName: projectName,
      item: '',
      material: '',
      location: '',
      batchLotNo: '',
      structure: structure,
      structureType: structureType,
      element: element,
      nameOfRepresentative: contractor,
      assignedPersonClient: assignedPersonClient,
      contractName: contractName,
      dateOfSubmission: dateOfSubmission,
      dateOfInspection: dateOfInspection,
      timeOfInspection: timeOfInspection,
      contractorSubmittedOn: contractorSubmittedOn,
      rfiStatus: status,
      rfiDescription: description,
      measurementType: measurementType,
      inspectionQty: qtyText,
    );
  }

  factory RfiInspectionRow.fromJson(Map<String, dynamic> json) {
    final String underscored = _text(json['rfi_Id']);
    return RfiInspectionRow(
      id: _readId(json['id']),
      rfiId: underscored.isEmpty ? _text(json['rfiId']) : underscored,
      rfiCategory: _text(json['rfiCategory']),
      projectName: _text(json['projectName']),
      contractName: _text(json['contractName']),
      structure: _text(json['structure']),
      structureType: _text(json['structureType']),
      element: _text(json['element']),
      description: _text(json['rfiDescription']),
      contractor: _text(json['nameOfRepresentative']),
      assignedPersonClient: _text(json['assignedPersonClient']),
      dateOfSubmission: _text(json['dateOfSubmission']),
      dateOfInspection: _text(json['dateOfInspection']),
      timeOfInspection: _text(json['timeOfInspection']),
      contractorSubmittedOn: _text(json['contractorSubmittedOn']),
      measurementType: _text(json['measurementType']),
      totalQty: _readQty(json['totalQty']),
      status: _text(json['status']),
      inspectionStatus: _text(json['inspectionStatus']),
      action: _text(json['action']),
    );
  }
}

String formatInspectionQty(Object? value) {
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
  return formatInspectionQty(parsed);
}

class RfiBulkSubmitResult {
  const RfiBulkSubmitResult({
    required this.task,
    required this.totalFound,
    required this.successCount,
    required this.skippedNoMeasurement,
    required this.failed,
    required this.submittedRfiNumbers,
    required this.failedRfiNumbers,
  });

  final String task;
  final int totalFound;
  final int successCount;
  final int skippedNoMeasurement;
  final int failed;
  final List<String> submittedRfiNumbers;
  final List<String> failedRfiNumbers;

  bool get allSucceeded => failed == 0;

  String get message {
    final StringBuffer buffer = StringBuffer()
      ..writeln('Total found: $totalFound')
      ..writeln('Success: $successCount')
      ..writeln('Skipped (no measurement): $skippedNoMeasurement')
      ..write('Failed: $failed');
    if (submittedRfiNumbers.isNotEmpty) {
      buffer
        ..writeln()
        ..write('Submitted: ${submittedRfiNumbers.join(', ')}');
    }
    if (failedRfiNumbers.isNotEmpty) {
      buffer
        ..writeln()
        ..write('Failed RFIs: ${failedRfiNumbers.join(', ')}');
    }
    return buffer.toString();
  }

  factory RfiBulkSubmitResult.fromJson(Map<String, dynamic> json) {
    return RfiBulkSubmitResult(
      task: _text(json['task']),
      totalFound: _readCount(json['totalFound']),
      successCount: _readCount(json['success']),
      skippedNoMeasurement: _readCount(json['skippedNoMeasurement']),
      failed: _readCount(json['failed']),
      submittedRfiNumbers: _stringList(json['submittedRfiNumbers']),
      failedRfiNumbers: _stringList(json['failedRfiNumbers']),
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

double? _readQty(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    final String text = value.trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }
    return double.tryParse(text);
  }
  return null;
}

int _readCount(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim()) ?? 0;
  }
  return 0;
}

List<String> _stringList(Object? value) {
  if (value is! List) {
    return const <String>[];
  }
  return value
      .map((Object? item) => _text(item))
      .where((String item) => item.isNotEmpty)
      .toList(growable: false);
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
