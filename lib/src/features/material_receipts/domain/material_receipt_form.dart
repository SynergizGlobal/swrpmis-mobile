import 'package:swr_pmis_mobile/src/features/material_receipts/domain/material_receipt_detail.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/domain/material_receipt_list.dart';

enum MaterialReceiptFormMode { create, edit, view }

enum MaterialReceiptSaveAction { draft, submit }

class MaterialReceiptUnit {
  const MaterialReceiptUnit._();

  static const List<String> values = <String>[
    'Cum',
    'MT',
    'Bag',
    'Nos',
    'Kg',
  ];
}

class MaterialReceiptFormItemDraft {
  MaterialReceiptFormItemDraft({
    this.itemId,
    this.materialCode = '',
    this.materialName = '',
    this.gradeSpec = '',
    this.sizeType = '',
    this.unit = '',
    this.quantity = '',
    this.remarks = '',
    this.itemDecision = '',
    this.engineerItemRemarks = '',
  });

  factory MaterialReceiptFormItemDraft.fromDetail(MaterialReceiptItem item) {
    return MaterialReceiptFormItemDraft(
      itemId: item.itemId,
      materialCode: item.materialCode,
      materialName: item.materialName,
      gradeSpec: item.gradeSpec,
      sizeType: item.sizeType,
      unit: item.unit,
      quantity: item.quantity,
      remarks: item.remarks,
      itemDecision: item.itemDecision,
      engineerItemRemarks: item.engineerItemRemarks,
    );
  }

  int? itemId;
  String materialCode;
  String materialName;
  String gradeSpec;
  String sizeType;
  String unit;
  String quantity;
  String remarks;
  String itemDecision;
  String engineerItemRemarks;

  double get quantityValue => double.tryParse(quantity.trim()) ?? 0;
}

class MaterialReceiptChecklistDoc {
  MaterialReceiptChecklistDoc({
    required this.documentName,
    required this.mandatory,
    this.documentId,
    this.docId,
    this.existingFileName = '',
    this.localPath,
    this.localFileName = '',
  });

  final int? documentId;
  final String documentName;
  final bool mandatory;
  int? docId;
  String existingFileName;
  String? localPath;
  String localFileName;

  bool get hasFile =>
      (localPath != null && localPath!.trim().isNotEmpty) ||
      existingFileName.trim().isNotEmpty;

  bool get hasNewFile => localPath != null && localPath!.trim().isNotEmpty;
}

class MaterialReceiptFormCatalog {
  const MaterialReceiptFormCatalog({
    this.projects = const <MaterialReceiptOption>[],
    this.sections = const <MaterialReceiptOption>[],
    this.contracts = const <MaterialReceiptOption>[],
    this.materials = const <MaterialReceiptOption>[],
  });

  final List<MaterialReceiptOption> projects;
  final List<MaterialReceiptOption> sections;
  final List<MaterialReceiptOption> contracts;
  final List<MaterialReceiptOption> materials;

  MaterialReceiptFormCatalog copyWith({
    List<MaterialReceiptOption>? projects,
    List<MaterialReceiptOption>? sections,
    List<MaterialReceiptOption>? contracts,
    List<MaterialReceiptOption>? materials,
  }) {
    return MaterialReceiptFormCatalog(
      projects: projects ?? this.projects,
      sections: sections ?? this.sections,
      contracts: contracts ?? this.contracts,
      materials: materials ?? this.materials,
    );
  }
}

MaterialReceiptFormMode materialReceiptFormModeForStatus(String? status) {
  final String value = (status ?? '').trim().toUpperCase();
  if (value == 'ACCEPTED') {
    return MaterialReceiptFormMode.view;
  }
  if (value.isEmpty) {
    return MaterialReceiptFormMode.create;
  }
  return MaterialReceiptFormMode.edit;
}

bool materialReceiptCanSaveDraft(String? status) {
  final String value = (status ?? '').trim().toUpperCase();
  return value.isEmpty || value == 'DRAFT' || value == 'RETURNED';
}

bool materialReceiptCanSubmit(String? status) {
  final String value = (status ?? '').trim().toUpperCase();
  return value.isEmpty ||
      value == 'DRAFT' ||
      value == 'RETURNED' ||
      value == 'PENDING_REVIEW';
}

bool materialReceiptLocksProjectFields(String? status) {
  final String value = (status ?? '').trim().toUpperCase();
  return value == 'PENDING_REVIEW' || value == 'ACCEPTED';
}

String materialReceiptSubmitStatus(String? currentStatus) {
  final String value = (currentStatus ?? '').trim().toUpperCase();
  if (value == 'PENDING_REVIEW') {
    return 'PENDING_REVIEW';
  }
  return 'PENDING_REVIEW';
}

String materialReceiptDraftStatus(String? currentStatus) {
  final String value = (currentStatus ?? '').trim().toUpperCase();
  if (value == 'RETURNED') {
    return 'RETURNED';
  }
  return 'DRAFT';
}
