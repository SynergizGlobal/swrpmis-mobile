import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_row.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_list_item.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_user_role.dart';

/// Actions offered on Work / Material / Quality **list** rows.
///
/// Mirrors WCR `RfiListActions` (role × status). Category `viewOnly` from
/// `/category-view-only` gates Edit/Delete via [canModify] — inspection
/// workflow actions still follow the role matrix so reps/engineers are not
/// blocked from starting or submitting.
enum RfiListRowAction {
  viewDetails('View Details'),
  editRfi('Edit RFI'),
  uploadAttachments('Upload Attachments'),
  uploadTestResults('Upload Test Results'),
  startOnline('Start Inspection Online'),
  startOffline('Start Inspection Offline'),
  submit('Submit'),
  closeRfi('Close RFI'),
  deleteRfi('Delete RFI'),
  changeExecutive('Change Executive');

  const RfiListRowAction(this.menuLabel);

  final String menuLabel;
}

/// Builds the Actions menu for one list row.
///
/// [canModify] is false when the category is view-only (or access still
/// loading). Edit/Delete require both [canModify] and the role permission.
List<RfiListRowAction> rfiListRowActions({
  required RfiUserRole role,
  required String status,
  required bool canModify,
}) {
  final List<RfiListRowAction> actions = <RfiListRowAction>[];

  if (role.canViewRfi(status)) {
    actions.add(RfiListRowAction.viewDetails);
  }
  if (canModify && role.canEditRfi(status)) {
    actions.add(RfiListRowAction.editRfi);
  }
  if (role.canUploadAttachments(status)) {
    actions.add(RfiListRowAction.uploadAttachments);
  }
  if (role.canUploadTestResults(status)) {
    actions.add(RfiListRowAction.uploadTestResults);
  }
  if (role.canStartInspection(status)) {
    actions
      ..add(RfiListRowAction.startOnline)
      ..add(RfiListRowAction.startOffline);
  }
  if (role.canSubmitInspection(status)) {
    actions.add(RfiListRowAction.submit);
  }
  if (role.canRejectOrClose(status)) {
    actions.add(RfiListRowAction.closeRfi);
  }
  if (canModify && role.canDeleteRfi(status)) {
    actions.add(RfiListRowAction.deleteRfi);
  }
  if (role.canChangeExecutive(status)) {
    actions.add(RfiListRowAction.changeExecutive);
  }
  return actions;
}

/// Maps a category-list row into the shape inspection start/view expect.
RfiInspectionRow rfiListItemToInspectionRow(RfiListItem item) {
  return RfiInspectionRow(
    id: item.id,
    rfiId: item.rfiId,
    rfiCategory: item.rfiCategory,
    projectName: item.projectName,
    contractName: item.contractName,
    contractId: '',
    structure: item.structure,
    structureType: item.structureType,
    element: item.element,
    description: item.rfiDescription,
    contractor: item.nameOfRepresentative,
    assignedPersonClient: item.assignedPersonClient,
    dateOfSubmission: item.dateOfSubmission,
    dateOfInspection: item.dateOfInspection,
    timeOfInspection: item.timeOfInspection,
    contractorSubmittedOn: item.contractorSubmittedOn,
    measurementType: item.measurementType,
    totalQty: double.tryParse(item.inspectionQty.trim()),
    status: item.rfiStatus,
    inspectionStatus: '',
    action: '',
  );
}
