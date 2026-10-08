import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_row.dart';
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
  if (role.canStartInspection(status) &&
      inspectionStartEnabled(role: role, row: row, now: clock)) {
    actions
      ..add(RfiInspectionAction.startOnline)
      ..add(RfiInspectionAction.startOffline);
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
  return actions;
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
