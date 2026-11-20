/// Reports → Contracts → Date of Completion Letters
/// (formId 1371 / doc-contractual-letters).
///
/// TODO: Search API is pending. Do not call a guessed URL
/// (e.g. `/ajax/generate-doc-contractual-letters`) until the real
/// endpoint is confirmed. Web title: List of Contracts Closer to DOC
/// Expiry Date. Screenshot shows a table-only UI (no Start/End date filters).
bool isDocContractualLettersReport({
  required String formId,
  required String formName,
  required String webFormUrl,
}) {
  final String id = formId.trim();
  if (id == '1371') {
    return true;
  }

  final String url = webFormUrl.trim().toLowerCase();
  // Exclude Date of Completion Report (contract-report/9) and sibling letters.
  if (url.contains('contract-report') ||
      url.contains('bg-contractual-letters') ||
      url.contains('generate-bg-contractual') ||
      url.contains('insurance-contractual-letters') ||
      url.contains('generate-insurance-contractual')) {
    return false;
  }
  if (url.contains('doc-contractual-letters') ||
      url.contains('generate-doc-contractual')) {
    return true;
  }

  final String name = formName.trim().toLowerCase();
  // Exclude Date of Completion Report / Contract Completion Report.
  if (name.contains('report') && !name.contains('letter')) {
    return false;
  }
  if (name.contains('bg contractual') ||
      name.contains('insurance contractual')) {
    return false;
  }
  return name == 'date of completion letters' ||
      name == 'list of contracts closer to doc expiry date';
}
