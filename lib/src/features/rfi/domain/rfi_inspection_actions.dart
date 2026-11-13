import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_row.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_uploaded_by.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_user_role.dart';

enum RfiInspectionAction {
  startOnline('Start Inspection Online', 'Start inspection'),
  startOffline('Start Inspection Offline', 'Start inspection offline'),
  viewDetails('View Details', 'View'),
  uploadAttachments('Upload Attachments', 'Upload attachments'),
  uploadTestResults('Upload Test Results', 'Upload test results'),
  submit('Submit', 'Submit'),
  sendForValidation('Send for Validation', 'Validation'),
  closeRfi('Close RFI', 'Close RFI'),
  deleteRfi('Delete RFI', 'Delete RFI'),
  changeExecutive('Change Executive', 'Change executive');

  const RfiInspectionAction(this.menuLabel, this.dialogTitle);

  final String menuLabel;
  final String dialogTitle;
}

List<RfiInspectionAction> rfiInspectionActions({
  required RfiUserRole role,
  required RfiInspectionRow row,
  DateTime? now,
}) {
  final String status = row.status;
  final DateTime clock = now ?? DateTime.now();
  final List<RfiInspectionAction> actions = <RfiInspectionAction>[];
  final bool engineerSide = rfiRoleIsEngineerSide(role);
  if (role.canStartInspection(status) &&
      (!engineerSide ||
          rfiEngineerInspectionStatuses.contains(status.toUpperCase())) &&
      inspectionStartEnabled(role: role, row: row, now: clock)) {
    actions
      ..add(RfiInspectionAction.startOnline)
      ..add(RfiInspectionAction.startOffline);
  } else if (rfiEngineerCanStartOnline(role: role, row: row, now: clock)) {
    // Engineer side: the list rows carry no measurement/qty, which used to
    // hide Start entirely. Offer the online inspection like the web.
    actions.add(RfiInspectionAction.startOnline);
  }
  if (role.canViewRfi(status)) {
    actions.add(RfiInspectionAction.viewDetails);
  }
  if (role.canUploadAttachments(status)) {
    actions.add(RfiInspectionAction.uploadAttachments);
  }
  if (role.canUploadTestResults(status)) {
    actions.add(RfiInspectionAction.uploadTestResults);
  }
  if (role.canSubmitInspection(status)) {
    actions.add(RfiInspectionAction.submit);
  }
  if (role.canSendForValidation(status)) {
    actions.add(RfiInspectionAction.sendForValidation);
  }
  if (role.canRejectOrClose(status)) {
    actions.add(RfiInspectionAction.closeRfi);
  }
  if (role.canDeleteRfi(status)) {
    actions.add(RfiInspectionAction.deleteRfi);
  }
  if (role.canChangeExecutive(status)) {
    actions.add(RfiInspectionAction.changeExecutive);
  }
  if (engineerSide) {
    // Engineer side gets only what the web offers: start online and view.
    return actions
        .where(rfiEngineerMenuActions.contains)
        .toList(growable: false);
  }
  return actions;
}

/// The only actions an engineer-side user sees in the inspection list.
const Set<RfiInspectionAction> rfiEngineerMenuActions = <RfiInspectionAction>{
  RfiInspectionAction.startOnline,
  RfiInspectionAction.viewDetails,
};

/// The engineer may start an inspection only after the contractor has
/// finished theirs.
const Set<String> rfiEngineerInspectionStatuses = <String>{'INSPECTED_BY_CON'};

/// Any client/engineer-side role may start an online inspection once the
/// contractor has inspected and the inspection date has arrived.
bool rfiEngineerCanStartOnline({
  required RfiUserRole role,
  required RfiInspectionRow row,
  required DateTime now,
}) {
  if (!rfiRoleIsEngineerSide(role)) {
    return false;
  }
  if (!rfiEngineerInspectionStatuses.contains(row.status.toUpperCase())) {
    return false;
  }
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime? inspectionDate = _parseDate(row.dateOfInspection);
  return inspectionDate == null || !inspectionDate.isAfter(today);
}

bool inspectionStartEnabled({
  required RfiUserRole role,
  required RfiInspectionRow row,
  required DateTime now,
}) {
  if (row.dateOfInspection.trim().isEmpty ||
      row.timeOfInspection.trim().isEmpty) {
    return false;
  }
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime? inspectionDate = _parseDate(row.dateOfInspection);
  final DateTime? submissionDate = _parseDate(row.dateOfSubmission);
  if (inspectionDate == null || inspectionDate.isAfter(today)) {
    return false;
  }
  if (submissionDate != null && submissionDate.isAfter(today)) {
    return false;
  }
  if (!role.canStartInspection(row.status)) {
    return false;
  }
  if (role == RfiUserRole.engineer ||
      role == RfiUserRole.dyHod ||
      role == RfiUserRole.dyHodEngineer) {
    final bool hasMeasurement =
        row.measurementType.trim().isNotEmpty && row.hasQty;
    if (!hasMeasurement) {
      return false;
    }
  }
  return true;
}

DateTime? _parseDate(String? dateStr) {
  if (dateStr == null || dateStr.trim().isEmpty) {
    return null;
  }
  final String value = dateStr.trim();
  if (value.contains('-') && value.indexOf('-') == 4) {
    return DateTime.tryParse(value);
  }
  final List<String> parts = value.split('-');
  if (parts.length != 3) {
    return null;
  }
  final int? day = int.tryParse(parts[0]);
  final int? month = int.tryParse(parts[1]);
  int? year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) {
    return null;
  }
  if (year < 100) {
    year += 2000;
  }
  return DateTime(year, month, day);
}
