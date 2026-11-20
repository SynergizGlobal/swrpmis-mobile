/// Reports → Progress Report → TPC (TPC Status Report).
///
/// Matches menu items by name/url containing `tpc` (case-insensitive),
/// including `tpc-status` URLs. Safe when TPC is absent from getReportForms.
bool isTpcStatusReport({
  required String formId,
  required String formName,
  required String webFormUrl,
}) {
  final String id = formId.trim().toLowerCase();
  if (id.contains('tpc')) {
    return true;
  }

  final String url = webFormUrl.trim().toLowerCase();
  if (url.contains('tpc')) {
    return true;
  }

  final String name = formName.trim().toLowerCase();
  return name.contains('tpc');
}
