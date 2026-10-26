class NcrAttachment {
  const NcrAttachment({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.attachmentStage,
    required this.fileSizeKb,
  });

  final int id;
  final String fileName;
  final String filePath;
  final String attachmentStage;
  final int? fileSizeKb;
}

class NcrObligationReference {
  const NcrObligationReference({
    required this.id,
    required this.obligationCode,
    required this.materialName,
    required this.batchLotNo,
    required this.testName,
  });

  static const NcrObligationReference empty = NcrObligationReference(
    id: 0,
    obligationCode: '',
    materialName: '',
    batchLotNo: '',
    testName: '',
  );

  final int id;
  final String obligationCode;
  final String materialName;
  final String batchLotNo;
  final String testName;
}

class NcrObservationDetail {
  const NcrObservationDetail({
    required this.id,
    required this.ncrCode,
    required this.ncrType,
    required this.severity,
    required this.description,
    required this.applicableRequirement,
    required this.projectId,
    required this.sectionId,
    required this.contractId,
    required this.location,
    required this.sourceType,
    required this.testObligationId,
    required this.materialReceiptId,
    required this.raisedBy,
    required this.raisedDate,
    required this.responsibleContractorId,
    required this.correctiveActionRequired,
    required this.targetClosureDate,
    required this.status,
    required this.correctiveActionTaken,
    required this.submittedBy,
    required this.submittedOn,
    required this.verifiedBy,
    required this.verifiedOn,
    required this.verificationRemarks,
    required this.retestObligationId,
    required this.overdue,
    required this.obligation,
    required this.issueAttachments,
    required this.correctiveAttachments,
  });

  final int id;
  final String ncrCode;
  final String ncrType;
  final String severity;
  final String description;
  final String applicableRequirement;
  final String projectId;
  final String sectionId;
  final String contractId;
  final String location;
  final String sourceType;
  final int? testObligationId;
  final String materialReceiptId;
  final String raisedBy;
  final String raisedDate;
  final String responsibleContractorId;
  final String correctiveActionRequired;
  final String targetClosureDate;
  final String status;
  final String correctiveActionTaken;
  final String submittedBy;
  final String submittedOn;
  final String verifiedBy;
  final String verifiedOn;
  final String verificationRemarks;
  final int? retestObligationId;
  final bool overdue;
  final NcrObligationReference obligation;
  final List<NcrAttachment> issueAttachments;
  final List<NcrAttachment> correctiveAttachments;

  String get sourceLabel {
    final String raw = sourceType.trim();
    if (raw.isEmpty) {
      return '';
    }
    return raw.replaceAll('_', ' ');
  }

  String get statusKey => status.trim().toUpperCase().replaceAll(' ', '_');

  bool get isClosed => statusKey == 'CLOSED';

  bool get canVerify => statusKey == 'ACTION_SUBMITTED';

  bool get isWaitingOnContractor => !isClosed && !canVerify;

  NcrObservationDetail copyWith({
    String? status,
    String? verificationRemarks,
    String? verifiedBy,
    String? verifiedOn,
    List<NcrAttachment>? issueAttachments,
    List<NcrAttachment>? correctiveAttachments,
    NcrObligationReference? obligation,
  }) {
    return NcrObservationDetail(
      id: id,
      ncrCode: ncrCode,
      ncrType: ncrType,
      severity: severity,
      description: description,
      applicableRequirement: applicableRequirement,
      projectId: projectId,
      sectionId: sectionId,
      contractId: contractId,
      location: location,
      sourceType: sourceType,
      testObligationId: testObligationId,
      materialReceiptId: materialReceiptId,
      raisedBy: raisedBy,
      raisedDate: raisedDate,
      responsibleContractorId: responsibleContractorId,
      correctiveActionRequired: correctiveActionRequired,
      targetClosureDate: targetClosureDate,
      status: status ?? this.status,
      correctiveActionTaken: correctiveActionTaken,
      submittedBy: submittedBy,
      submittedOn: submittedOn,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedOn: verifiedOn ?? this.verifiedOn,
      verificationRemarks: verificationRemarks ?? this.verificationRemarks,
      retestObligationId: retestObligationId,
      overdue: overdue,
      obligation: obligation ?? this.obligation,
      issueAttachments: issueAttachments ?? this.issueAttachments,
      correctiveAttachments:
          correctiveAttachments ?? this.correctiveAttachments,
    );
  }
}

/// Absolute URL for an NCR/quality file path under the SWR base URL.
String ncrAttachmentAbsoluteUrl({
  required String baseUrl,
  required String filePath,
}) {
  final String path = filePath.trim();
  if (path.isEmpty) {
    return '';
  }
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }
  final String base = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
  final String normalized = path.startsWith('/') ? path : '/$path';
  return '$base$normalized';
}
