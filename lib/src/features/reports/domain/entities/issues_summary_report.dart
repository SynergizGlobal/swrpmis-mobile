/// Reports → Issues → Issues Summary Report (formId 292).
///
/// Confirm → GET `/api/issues-report/issues-summary-report/ALL` → file download.
/// Distinct from Pending Issues Report and Issue Details Report.
bool isIssuesSummaryReport({
  required String formId,
  required String formName,
  required String webFormUrl,
}) {
  final String id = formId.trim();
  if (id == '292') {
    return true;
  }

  final String url = webFormUrl.trim().toLowerCase();
  if (url.contains('issues-summary-report')) {
    return true;
  }

  final String name = formName.trim().toLowerCase();
  return name.contains('issues summary');
}
