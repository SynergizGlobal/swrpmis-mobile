class RfiInspectionAccess {
  const RfiInspectionAccess({
    required this.permissionType,
    required this.message,
    required this.accessType,
    required this.hasAccess,
  });

  final String permissionType;
  final String message;
  final String accessType;
  final bool hasAccess;

  factory RfiInspectionAccess.fromJson(Map<String, dynamic> json) {
    return RfiInspectionAccess(
      permissionType: _text(json['permissionType']),
      message: _text(json['message']),
      accessType: _text(json['accessType']),
      hasAccess: _bool(json['hasAccess']),
    );
  }
}

class RfiUserSignature {
  const RfiUserSignature({required this.exists});

  final bool exists;

  factory RfiUserSignature.fromJson(Map<String, dynamic> json) {
    return RfiUserSignature(exists: _bool(json['exists']));
  }
}

bool _bool(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final String text = value.trim().toLowerCase();
    return text == 'true' || text == '1' || text == 'yes';
  }
  return false;
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
