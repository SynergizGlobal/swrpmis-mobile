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

List<RfiChecklistItem> parseRfiChecklistItems(Object? raw) {
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
