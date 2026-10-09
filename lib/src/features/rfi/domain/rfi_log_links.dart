class RfiLogLinks {
  const RfiLogLinks._();

  static const String logoRelativePath =
      'static/media/swrlogo.ed293643301635609477.png';

  static const String clientName = 'South Western Railway';

  static const String pdfBlank = '---';

  static const String dialogBlank = '—';

  static const String dialogMissing = 'N/A';

  static String logoUrl(String baseUrl) {
    final String trimmed = baseUrl.trim();
    final String root = trimmed.endsWith('/') ? trimmed : '$trimmed/';
    return '$root$logoRelativePath';
  }

  static String reportPath(int id) => '/api/rfiLog/getRfiReportDetails/$id';

  static String downloadPath(String rfiId, String txnId) {
    return '/api/rfiLog/pdf/download/${Uri.encodeComponent(rfiId)}/${Uri.encodeComponent(txnId)}';
  }
}
