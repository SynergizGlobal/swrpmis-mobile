import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_list_item.dart';

class RfiValidationRow {
  const RfiValidationRow({
    required this.rfiCategory,
    required this.stringRfiId,
    required this.longRfiId,
    required this.longRfiValidateId,
    required this.status,
    required this.remarks,
    required this.comment,
  });

  final String? rfiCategory;
  final String? stringRfiId;
  final String? longRfiId;
  final int? longRfiValidateId;
  final String? status;
  final String? remarks;
  final String? comment;

  factory RfiValidationRow.fromJson(Map<String, dynamic> json) {
    return RfiValidationRow(
      rfiCategory: _text(json['rfiCategory']),
      stringRfiId: _text(json['stringRfiId']),
      longRfiId: _text(json['longRfiId']),
      longRfiValidateId: _int(json['longRfiValidateId']),
      status: _text(json['status']),
      remarks: _text(json['remarks']),
      comment: _text(json['comment']),
    );
  }

  RfiListItem toListItem() {
    return RfiListItem(
      id: longRfiValidateId,
      rfiId: stringRfiId ?? '',
      rfiCategory: rfiCategory ?? '',
      projectName: '',
      item: '',
      material: '',
      location: '',
      batchLotNo: '',
      structure: '',
      structureType: '',
      element: '',
      nameOfRepresentative: '',
      assignedPersonClient: '',
      contractName: '',
      dateOfSubmission: '',
      dateOfInspection: '',
      timeOfInspection: '',
      contractorSubmittedOn: '',
      rfiStatus: status ?? '',
      rfiDescription: comment ?? '',
    );
  }
}

String rfiValidationRowKey(RfiValidationRow row, int index) {
  return '${row.longRfiValidateId ?? ''}|${row.stringRfiId ?? ''}|$index';
}

List<RfiValidationRow> parseRfiValidationRows(dynamic data) {
  return _rowItems(data)
      .whereType<Map>()
      .map(
        (Map item) =>
            RfiValidationRow.fromJson(Map<String, dynamic>.from(item)),
      )
      .toList(growable: false);
}

List<dynamic> _rowItems(dynamic data) {
  if (data is List) {
    return data;
  }
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    for (final String key in const <String>[
      'data',
      'result',
      'content',
      'list',
      'records',
    ]) {
      final Object? nested = map[key];
      if (nested is List) {
        return nested;
      }
      if (nested is Map && _isRow(Map<String, dynamic>.from(nested))) {
        return <dynamic>[nested];
      }
    }
    if (_isRow(map)) {
      return <dynamic>[map];
    }
  }
  return const <dynamic>[];
}

bool _isRow(Map<String, dynamic> map) {
  for (final String key in const <String>[
    'longRfiValidateId',
    'stringRfiId',
    'longRfiId',
    'valdationAuth',
    'rfiCategory',
    'remarks',
    'comment',
    'status',
  ]) {
    if (map.containsKey(key)) {
      return true;
    }
  }
  return false;
}

String? _text(Object? value) {
  if (value == null) {
    return null;
  }
  final String text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }
  return text;
}

int? _int(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    final String text = value.trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }
    return int.tryParse(text);
  }
  return null;
}
