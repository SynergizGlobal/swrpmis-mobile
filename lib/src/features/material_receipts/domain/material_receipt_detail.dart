class MaterialReceiptItem {
  const MaterialReceiptItem({
    required this.itemId,
    required this.materialCode,
    required this.materialName,
    required this.gradeSpec,
    required this.sizeType,
    required this.unit,
    required this.quantity,
    required this.itemBatchLotNo,
    required this.remarks,
    required this.verifiedQuantity,
    required this.engineerItemRemarks,
    required this.itemDecision,
  });

  final int? itemId;
  final String materialCode;
  final String materialName;
  final String gradeSpec;
  final String sizeType;
  final String unit;
  final String quantity;
  final String itemBatchLotNo;
  final String remarks;
  final String verifiedQuantity;
  final String engineerItemRemarks;
  final String itemDecision;
}

class MaterialReceiptDocument {
  const MaterialReceiptDocument({
    required this.docId,
    required this.itemId,
    required this.docType,
    required this.fileName,
    required this.downloadUrl,
    required this.uploadedBy,
    required this.uploadedOn,
  });

  final int docId;
  final int? itemId;
  final String docType;
  final String fileName;
  final String downloadUrl;
  final String uploadedBy;
  final String uploadedOn;
}

class MaterialReceiptDetail {
  const MaterialReceiptDetail({
    required this.receiptId,
    required this.projectId,
    required this.projectName,
    required this.sectionId,
    required this.sectionName,
    required this.contractId,
    required this.contractShortName,
    required this.sourceSupplier,
    required this.batchLotNo,
    required this.invoiceNo,
    required this.deliveryDate,
    required this.placeChainage,
    required this.remarks,
    required this.vehicleChallanNo,
    required this.status,
    required this.createdBy,
    required this.createdOn,
    required this.submittedBy,
    required this.submittedOn,
    required this.engineerId,
    required this.engineerName,
    required this.engineerDecision,
    required this.engineerRemarks,
    required this.decisionOn,
    required this.contractorName,
    required this.createdByName,
    required this.revisionNo,
    required this.items,
    required this.documents,
  });

  final String receiptId;
  final String projectId;
  final String projectName;
  final String sectionId;
  final String sectionName;
  final String contractId;
  final String contractShortName;
  final String sourceSupplier;
  final String batchLotNo;
  final String invoiceNo;
  final String deliveryDate;
  final String placeChainage;
  final String remarks;
  final String vehicleChallanNo;
  final String status;
  final String createdBy;
  final String createdOn;
  final String submittedBy;
  final String submittedOn;
  final String engineerId;
  final String engineerName;
  final String engineerDecision;
  final String engineerRemarks;
  final String decisionOn;
  final String contractorName;
  final String createdByName;
  final String revisionNo;
  final List<MaterialReceiptItem> items;
  final List<MaterialReceiptDocument> documents;
}
