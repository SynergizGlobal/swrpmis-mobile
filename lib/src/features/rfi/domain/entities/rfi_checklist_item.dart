class RfiChecklistItem {
  const RfiChecklistItem({
    required this.checklistDescId,
    required this.checklistDescription,
    required this.contractorStatus,
    required this.engineerStatus,
    required this.contractorRemarks,
    required this.engineerRemark,
    required this.gradeOfConcrete,
    required this.enclosureName,
  });

  final int? checklistDescId;
  final String checklistDescription;
  final String contractorStatus;
  final String engineerStatus;
  final String contractorRemarks;
  final String engineerRemark;
  final String gradeOfConcrete;
  final String enclosureName;

  RfiChecklistItem copyWith({
    String? contractorStatus,
    String? engineerStatus,
    String? contractorRemarks,
    String? engineerRemark,
    String? gradeOfConcrete,
  }) {
    return RfiChecklistItem(
      checklistDescId: checklistDescId,
      checklistDescription: checklistDescription,
      contractorStatus: contractorStatus ?? this.contractorStatus,
      engineerStatus: engineerStatus ?? this.engineerStatus,
      contractorRemarks: contractorRemarks ?? this.contractorRemarks,
      engineerRemark: engineerRemark ?? this.engineerRemark,
      gradeOfConcrete: gradeOfConcrete ?? this.gradeOfConcrete,
      enclosureName: enclosureName,
    );
  }

  factory RfiChecklistItem.fromJson(Map<String, dynamic> json) {
    return RfiChecklistItem(
      checklistDescId: _int(
        json['checklistDescId'] ?? json['checklistDescriptionId'],
      ),
      checklistDescription: _firstText(json, const <String>[
        'checklistDescription',
        'description',
      ]),
      contractorStatus: _text(json['contractorStatus']),
      engineerStatus: _text(json['engineerStatus']),
      contractorRemarks: _firstText(json, const <String>[
        'contractorRemarks',
        'contractorRemark',
      ]),
      engineerRemark: _firstText(json, const <String>[
        'engineerRemark',
        'aeRemark',
        'engineerRemarks',
      ]),
      gradeOfConcrete: _text(json['gradeOfConcrete']),
      enclosureName: _text(json['enclosureName']),
    );
  }

  Map<String, dynamic> toSaveRowJson() {
    return <String, dynamic>{
      'checklistDescriptionId': checklistDescId,
      'description': checklistDescription,
      'contractorStatus': contractorStatus,
      'engineerStatus': engineerStatus,
      'contractorRemark': contractorRemarks,
      'aeRemark': engineerRemark,
    };
  }
}

/// Reads `GET /api/v1/enclouser/checklist-items`, which answers
/// `{gradeOfConcrete, rfiDescription, enclosureName, checklistItems: [...]}`.
/// A bare list is still accepted. The top-level grade is copied onto items
/// that have none, so callers can read it from any item.
List<RfiChecklistItem> parseRfiChecklistItems(Object? raw) {
  if (raw is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(raw);
    final String grade = _text(map['gradeOfConcrete']);
    final String enclosure = _text(map['enclosureName']);
    return parseRfiChecklistItems(map['checklistItems'] ?? map['items'])
        .map(
          (RfiChecklistItem item) => RfiChecklistItem(
            checklistDescId: item.checklistDescId,
            checklistDescription: item.checklistDescription,
            contractorStatus: item.contractorStatus,
            engineerStatus: item.engineerStatus,
            contractorRemarks: item.contractorRemarks,
            engineerRemark: item.engineerRemark,
            gradeOfConcrete: item.gradeOfConcrete.isEmpty
                ? grade
                : item.gradeOfConcrete,
            enclosureName: item.enclosureName.isEmpty
                ? enclosure
                : item.enclosureName,
          ),
        )
        .toList(growable: false);
  }
  if (raw is! List) {
    return const <RfiChecklistItem>[];
  }
  return raw
      .whereType<Map>()
      .map(
        (Map<dynamic, dynamic> item) =>
            RfiChecklistItem.fromJson(Map<String, dynamic>.from(item)),
      )
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
