class StructureFormFormOption {
  const StructureFormFormOption({
    required this.id,
    required this.label,
    this.projectId = '',
    this.extra = '',
  });

  final String id;
  final String label;
  final String projectId;
  final String extra;
}

class StructureFormPersonOption {
  const StructureFormPersonOption({
    required this.id,
    required this.userName,
    required this.designation,
  });

  final String id;
  final String userName;
  final String designation;

  String get label {
    final String desig = designation.trim();
    final String name = userName.trim();
    if (desig.isNotEmpty && name.isNotEmpty) {
      return '$desig - $name';
    }
    return name.isNotEmpty ? name : desig;
  }
}

class StructureFormResponsiblePerson {
  const StructureFormResponsiblePerson({
    required this.id,
    required this.userName,
    required this.designation,
    this.rowId = '',
  });

  final String id;
  final String userName;
  final String designation;
  final String rowId;

  String get label {
    final String desig = designation.trim();
    final String name = userName.trim();
    if (desig.isNotEmpty && name.isNotEmpty) {
      return '$desig - $name';
    }
    return name.isNotEmpty ? name : desig;
  }
}

class StructureFormExecutiveRow {
  const StructureFormExecutiveRow({
    required this.contractIdFk,
    required this.contractLabel,
    required this.people,
  });

  final String contractIdFk;
  final String contractLabel;
  final List<StructureFormResponsiblePerson> people;

  StructureFormExecutiveRow copyWith({
    String? contractIdFk,
    String? contractLabel,
    List<StructureFormResponsiblePerson>? people,
  }) {
    return StructureFormExecutiveRow(
      contractIdFk: contractIdFk ?? this.contractIdFk,
      contractLabel: contractLabel ?? this.contractLabel,
      people: people ?? this.people,
    );
  }
}

class StructureFormDetailRow {
  const StructureFormDetailRow({
    this.id = '',
    required this.structureDetail,
    required this.structureValue,
  });

  final String id;
  final String structureDetail;
  final String structureValue;

  StructureFormDetailRow copyWith({
    String? id,
    String? structureDetail,
    String? structureValue,
  }) {
    return StructureFormDetailRow(
      id: id ?? this.id,
      structureDetail: structureDetail ?? this.structureDetail,
      structureValue: structureValue ?? this.structureValue,
    );
  }
}

class StructureFormDocumentRow {
  const StructureFormDocumentRow({
    this.structureFileId = '',
    required this.fileType,
    required this.name,
    this.existingAttachment = '',
    this.localPath = '',
    this.localFileName = '',
  });

  final String structureFileId;
  final String fileType;
  final String name;
  final String existingAttachment;
  final String localPath;
  final String localFileName;

  bool get hasLocalFile => localPath.trim().isNotEmpty;

  String get displayFileName {
    if (localFileName.trim().isNotEmpty) {
      return localFileName.trim();
    }
    return existingAttachment.trim();
  }

  StructureFormDocumentRow copyWith({
    String? structureFileId,
    String? fileType,
    String? name,
    String? existingAttachment,
    String? localPath,
    String? localFileName,
  }) {
    return StructureFormDocumentRow(
      structureFileId: structureFileId ?? this.structureFileId,
      fileType: fileType ?? this.fileType,
      name: name ?? this.name,
      existingAttachment: existingAttachment ?? this.existingAttachment,
      localPath: localPath ?? this.localPath,
      localFileName: localFileName ?? this.localFileName,
    );
  }
}

class StructureFormMaster {
  const StructureFormMaster({
    this.projects = const <StructureFormFormOption>[],
    this.contracts = const <StructureFormFormOption>[],
    this.structureTypes = const <StructureFormFormOption>[],
    this.workStatuses = const <StructureFormFormOption>[],
    this.fileTypes = const <StructureFormFormOption>[],
    this.responsiblePeople = const <StructureFormPersonOption>[],
    this.detail,
    this.action = '',
  });

  static const StructureFormMaster empty = StructureFormMaster();

  final List<StructureFormFormOption> projects;
  final List<StructureFormFormOption> contracts;
  final List<StructureFormFormOption> structureTypes;
  final List<StructureFormFormOption> workStatuses;
  final List<StructureFormFormOption> fileTypes;
  final List<StructureFormPersonOption> responsiblePeople;
  final StructureFormDetail? detail;
  final String action;
}

class StructureFormDetail {
  const StructureFormDetail({
    this.structureId = '',
    this.projectIdFk = '',
    this.structureTypeFk = '',
    this.structure = '',
    this.structureName = '',
    this.workStatusFk = '',
    this.executives = const <StructureFormExecutiveRow>[],
    this.details = const <StructureFormDetailRow>[],
    this.documents = const <StructureFormDocumentRow>[],
  });

  static const StructureFormDetail empty = StructureFormDetail();

  final String structureId;
  final String projectIdFk;
  final String structureTypeFk;
  final String structure;
  final String structureName;
  final String workStatusFk;
  final List<StructureFormExecutiveRow> executives;
  final List<StructureFormDetailRow> details;
  final List<StructureFormDocumentRow> documents;

  bool get isEmpty => structureId.trim().isEmpty && structureName.trim().isEmpty;
}
