class RfiMenuAccess {
  const RfiMenuAccess({
    required this.showHome,
    required this.showMaterialRfi,
    required this.showWorkRfi,
    required this.showQualitySafetyRfi,
    required this.showInspection,
    required this.showValidation,
    required this.showRfiLog,
    required this.showAssignExecutive,
    required this.showReferenceForms,
  });

  static const RfiMenuAccess allVisible = RfiMenuAccess(
    showHome: true,
    showMaterialRfi: true,
    showWorkRfi: true,
    showQualitySafetyRfi: true,
    showInspection: true,
    showValidation: true,
    showRfiLog: true,
    showAssignExecutive: true,
    showReferenceForms: true,
  );

  final bool showHome;
  final bool showMaterialRfi;
  final bool showWorkRfi;
  final bool showQualitySafetyRfi;
  final bool showInspection;
  final bool showValidation;
  final bool showRfiLog;
  final bool showAssignExecutive;
  final bool showReferenceForms;

  factory RfiMenuAccess.fromJson(Map<String, dynamic> json) {
    return RfiMenuAccess(
      showHome: _bool(json['showHome']),
      showMaterialRfi: _bool(json['showMaterialRfi']),
      showWorkRfi: _bool(json['showWorkRfi']),
      showQualitySafetyRfi: _bool(json['showQualitySafetyRfi']),
      showInspection: _bool(json['showInspection']),
      showValidation: _bool(json['showValidation']),
      showRfiLog: _bool(json['showRfiLog']),
      showAssignExecutive: _bool(json['showAssignExecutive']),
      showReferenceForms: _bool(json['showReferenceForms']),
    );
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
