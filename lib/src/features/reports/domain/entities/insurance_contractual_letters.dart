/// Reports → Contracts → Insurance Contractual Letters
/// (formId 1370 / insurance-contractual-letters).
///
/// TODO: Search API is pending. Do not call a guessed URL
/// (e.g. `/ajax/generate-insurance-contractual-letters`) until the real
/// endpoint is confirmed. Web title: List of Contracts Closer to Insurance
/// Expiry Date. Screenshot shows a table-only UI (no Start/End date filters).
bool isInsuranceContractualLettersReport({
  required String formId,
  required String formName,
  required String webFormUrl,
}) {
  final String id = formId.trim();
  if (id == '1370') {
    return true;
  }

  final String url = webFormUrl.trim().toLowerCase();
  // Exclude BG letters and Date of Completion Letters.
  if (url.contains('bg-contractual-letters') ||
      url.contains('generate-bg-contractual') ||
      url.contains('doc-contractual-letters')) {
    return false;
  }
  if (url.contains('insurance-contractual-letters') ||
      url.contains('generate-insurance-contractual')) {
    return true;
  }

  final String name = formName.trim().toLowerCase();
  // Exclude BG Contractual Letters and Date of Completion Letters.
  if (name.contains('bg contractual') ||
      name.contains('date of completion letter') ||
      name == 'date of completion letters') {
    return false;
  }
  return name == 'insurance contractual letters' ||
      name == 'list of contracts closer to insurance expiry date';
}
