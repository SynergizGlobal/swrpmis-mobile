class StructureProjectOption {
  const StructureProjectOption({
    required this.projectId,
    required this.projectName,
  });

  final String projectId;
  final String projectName;

  String get displayLabel {
    final String id = projectId.trim();
    final String name = projectName.trim();
    if (id.isEmpty) {
      return name;
    }
    if (name.isEmpty) {
      return id;
    }
    return '$id - $name';
  }
}

class StructureRowDraft {
  const StructureRowDraft({
    this.structureId = '',
    this.structure = '',
    this.structureName = '',
    this.structureDetails = '',
    this.fromChainage = '',
    this.toChainage = '',
  });

  final String structureId;
  final String structure;
  final String structureName;
  final String structureDetails;
  final String fromChainage;
  final String toChainage;

  StructureRowDraft copyWith({
    String? structureId,
    String? structure,
    String? structureName,
    String? structureDetails,
    String? fromChainage,
    String? toChainage,
  }) {
    return StructureRowDraft(
      structureId: structureId ?? this.structureId,
      structure: structure ?? this.structure,
      structureName: structureName ?? this.structureName,
      structureDetails: structureDetails ?? this.structureDetails,
      fromChainage: fromChainage ?? this.fromChainage,
      toChainage: toChainage ?? this.toChainage,
    );
  }

  Map<String, dynamic> toPayload({required bool includeStructureId}) {
    final Map<String, dynamic> row = <String, dynamic>{
      'structure': structure.trim(),
      'structureName': structureName.trim(),
      'structureDetails': structureDetails.trim(),
      'fromChainage': _chainageValue(fromChainage),
      'toChainage': _chainageValue(toChainage),
    };
    final String id = structureId.trim();
    if (includeStructureId && id.isNotEmpty) {
      row['structureId'] = id;
    }
    return row;
  }

  static Object _chainageValue(String raw) {
    final String text = raw.trim();
    if (text.isEmpty) {
      return '';
    }
    final double? number = double.tryParse(text);
    if (number == null) {
      return text;
    }
    if (number == number.roundToDouble()) {
      return number.toInt();
    }
    return number;
  }
}

class StructureTypeGroupDraft {
  const StructureTypeGroupDraft({
    this.type = '',
    this.rows = const <StructureRowDraft>[StructureRowDraft()],
  });

  final String type;
  final List<StructureRowDraft> rows;

  StructureTypeGroupDraft copyWith({
    String? type,
    List<StructureRowDraft>? rows,
  }) {
    return StructureTypeGroupDraft(
      type: type ?? this.type,
      rows: rows ?? this.rows,
    );
  }

  Map<String, dynamic> toPayload({required bool editing}) {
    return <String, dynamic>{
      'type': type.trim(),
      'rows': <Map<String, dynamic>>[
        for (final StructureRowDraft row in rows)
          row.toPayload(includeStructureId: editing),
      ],
    };
  }
}

class StructureProjectChainage {
  const StructureProjectChainage({this.fromChainage, this.toChainage});

  static const StructureProjectChainage empty = StructureProjectChainage();

  final double? fromChainage;
  final double? toChainage;

  bool get hasBounds => fromChainage != null || toChainage != null;
}

class StructureFullDetail {
  const StructureFullDetail({
    required this.projectId,
    required this.projectName,
    required this.structureTypes,
  });

  static const StructureFullDetail empty = StructureFullDetail(
    projectId: '',
    projectName: '',
    structureTypes: <StructureTypeGroupDraft>[],
  );

  final String projectId;
  final String projectName;
  final List<StructureTypeGroupDraft> structureTypes;
}

class StructureFormMaster {
  const StructureFormMaster({
    this.projects = const <StructureProjectOption>[],
    this.structureTypes = const <String>[],
  });

  static const StructureFormMaster empty = StructureFormMaster();

  final List<StructureProjectOption> projects;
  final List<String> structureTypes;
}
