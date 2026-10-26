/// QTR row action-menu items (matches SWR web Quality Test Register).
enum QualityTestRegisterAction {
  /// Contractor only — when contractor status is not SUBMITTED.
  viewUpdate,

  /// Non-contractor (engineer etc.) — when contractor status is SUBMITTED.
  review,

  /// Always available.
  viewDetails,

  /// Always available.
  viewTraceability,
}

/// Web: `t = userRoleNameFk === "Contractor"`.
bool qualityTestRegisterIsContractorRole(String userRoleNameFk) {
  return userRoleNameFk.trim() == 'Contractor';
}

/// Builds the overflow menu for a row.
///
/// Rules from web (`QualityTestRegister`):
/// - Contractor + status ≠ SUBMITTED → **View / Update**
/// - Non-contractor + status = SUBMITTED → **Review**
/// - Always → **View Details**, **View Traceability**
///
/// Engineer status (PENDING / RETURNED / NCR_RAISED / …) does not change the
/// menu — only contractor status + role do (matches SUBMITTED+NCR RAISED vs
/// PENDING+… screenshots).
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
