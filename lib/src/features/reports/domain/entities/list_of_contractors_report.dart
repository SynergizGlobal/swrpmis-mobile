/// Reports → Contracts → List of Contractors (formId 290 / contractorslist).
///
/// Confirm → POST `/contract-report/contractorslist` with `{}` → file download.
/// Distinct from List of Contracts (formId 1335 / contract-report/7).
bool isListOfContractorsReport({
  required String formId,
  required String formName,
  required String webFormUrl,
}) {
  final String id = formId.trim();
  if (id == '290') {
    return true;
  }

  final String url = webFormUrl.trim().toLowerCase();
  if (url.contains('contractorslist')) {
    return true;
  }

  final String name = formName.trim().toLowerCase();
  return name == 'list of contractors';
}
