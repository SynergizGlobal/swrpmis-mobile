export 'package:swr_pmis_mobile/src/features/quality_test_register/domain/quality_test_register_permissions.dart'
    show qualityTestRegisterIsContractorRole;

enum QualityTestRegisterAction {
  viewUpdate,
  review,
  viewDetails,
  viewTraceability,
}

List<QualityTestRegisterAction> qualityTestRegisterActionsFor({
  required String contractorStatus,
  required bool isContractor,
}) {
  final String status = contractorStatus.trim().toUpperCase().replaceAll(
    ' ',
    '_',
  );
  final List<QualityTestRegisterAction> items = <QualityTestRegisterAction>[];
  if (isContractor && status != 'SUBMITTED') {
    items.add(QualityTestRegisterAction.viewUpdate);
  }
  if (!isContractor && status == 'SUBMITTED') {
    items.add(QualityTestRegisterAction.review);
  }
  items.add(QualityTestRegisterAction.viewDetails);
  items.add(QualityTestRegisterAction.viewTraceability);
  return items;
}

String qualityTestRegisterActionLabel(QualityTestRegisterAction action) {
  switch (action) {
    case QualityTestRegisterAction.viewUpdate:
      return 'View / Update';
    case QualityTestRegisterAction.review:
      return 'Review';
    case QualityTestRegisterAction.viewDetails:
      return 'View Details';
    case QualityTestRegisterAction.viewTraceability:
      return 'View Traceability';
  }
}
