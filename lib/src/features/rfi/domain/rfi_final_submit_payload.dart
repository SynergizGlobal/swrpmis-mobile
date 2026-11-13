/// One measurement row as `/rfi/finalSubmit` expects it (web keys: l, b, h, no).
class RfiSubmitMeasurement {
  const RfiSubmitMeasurement({
    required this.activityIdFk,
    required this.activityName,
    required this.measurementType,
    required this.units,
    required this.length,
    required this.breadth,
    required this.height,
    required this.weight,
    required this.no,
    required this.totalQty,
  });

  final int? activityIdFk;
  final String activityName;
  final String measurementType;
  final String units;
  final String length;
  final String breadth;
  final String height;
  final String weight;
  final String no;
  final num? totalQty;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'activityIdFk': activityIdFk,
      'activityName': _textOrNull(activityName),
      'measurementType': _textOrNull(measurementType),
      'l': _double(length),
      'b': _double(breadth),
      'h': _double(height),
      'weight': _double(weight),
      'units': _textOrNull(units),
      'no': _int(no),
      'totalQty': _whole(totalQty),
    };
  }
}

/// The `data` JSON for `POST /rfi/finalSubmit`, shaped exactly like the web
/// (InspectionForm.jsx `inspectionPayload`).
Map<String, dynamic> buildRfiFinalSubmitPayload({
  required int? inspectionId,
  required int rfiId,
  required String uploadedBy,
  required String location,
  required String chainage,
  required String nameOfRepresentative,
  required List<RfiSubmitMeasurement> measurements,
  required String? testInsiteLab,
  required String? inspectionStatus,
  required String? engineerRemarks,
  required String descriptionEnclosure,
  required List<String> supportingDescriptions,
  required String inspectionMode,
}) {
  return <String, dynamic>{
    'inspectionId': inspectionId,
    'rfiId': rfiId,
    'uploadedBy': uploadedBy,
    'location': _textOrNull(location),
    'chainage': _textOrNull(chainage),
    'nameOfRepresentative': _textOrNull(nameOfRepresentative),
    'measurements': measurements
        .map((RfiSubmitMeasurement m) => m.toJson())
        .toList(growable: false),
    'testInsiteLab': _textOrNull(testInsiteLab ?? ''),
    'inspectionStatus': _textOrNull(inspectionStatus ?? ''),
    'engineerRemarks': _textOrNull(engineerRemarks ?? ''),
    'descriptionEnclosure': descriptionEnclosure,
    'supportingDescriptions': supportingDescriptions,
    'inspectionMode': inspectionMode,
  };
}

/// Transaction id for `/rfi/stampPdfFromXml`, built like the web:
/// epoch milliseconds followed by a 3-digit random suffix.
String rfiStampTxnId({DateTime? now, int? random}) {
  final int millis = (now ?? DateTime.now()).millisecondsSinceEpoch;
  final int suffix = (random ?? DateTime.now().microsecond) % 1000;
  return '$millis${suffix.toString().padLeft(3, '0')}';
}

String? _textOrNull(String value) {
  final String text = value.trim();
  return text.isEmpty ? null : text;
}

double? _double(String raw) {
  final String text = raw.trim();
  return text.isEmpty ? null : double.tryParse(text);
}

int? _int(String raw) {
  final String text = raw.trim();
  if (text.isEmpty) {
    return null;
  }
  return int.tryParse(text) ?? double.tryParse(text)?.round();
}

num? _whole(num? value) {
  if (value == null) {
    return null;
  }
  return value == value.roundToDouble() ? value.toInt() : value;
}
