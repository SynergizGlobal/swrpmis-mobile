/// Reports → Progress Report → Station Improvement Progress Report.
///
/// Matches formName containing `station improvement` and/or webFormUrl
/// containing `station-improvement` (case-insensitive). Does not match
/// Activities Export or other Progress Report siblings.
bool isStationImprovementsReport({
  required String formId,
  required String formName,
  required String webFormUrl,
}) {
  final String url = webFormUrl.trim().toLowerCase();
  if (url.contains('station-improvement')) {
    return true;
  }

  final String name = formName.trim().toLowerCase();
  return name.contains('station improvement');
}
