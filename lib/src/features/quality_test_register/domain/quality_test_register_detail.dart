class QualityTestObligationDetail {
  const QualityTestObligationDetail({
    required this.id,
    required this.obligationCode,
    required this.projectId,
    required this.sectionId,
    required this.contractId,
    required this.materialCode,
    required this.materialName,
    required this.testName,
    required this.generatedFrom,
    required this.batchLotNo,
    required this.obligationBasisCoverage,
    required this.requiredByDate,
    required this.contractorStatus,
    required this.engineerStatus,
    required this.finalResult,
    required this.contractorRemarks,
    required this.submittedBy,
    required this.submittedOn,
    required this.reviewedBy,
    required this.reviewDate,
    required this.reviewComments,
    required this.testDate,
    required this.remarks,
  });

  final int id;
  final String obligationCode;
  final String projectId;
  final String sectionId;
  final String contractId;
  final String materialCode;
  final String materialName;
  final String testName;
  final String generatedFrom;
  final String batchLotNo;
  final String obligationBasisCoverage;
  final String requiredByDate;
  final String contractorStatus;
  final String engineerStatus;
  final String finalResult;
  final String contractorRemarks;
  final String submittedBy;
  final String submittedOn;
  final String reviewedBy;
  final String reviewDate;
  final String reviewComments;
  final String testDate;
  final String remarks;
}
