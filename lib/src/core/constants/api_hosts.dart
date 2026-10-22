class ApiHosts {
  const ApiHosts._();

  static const String prodBaseUrl =
      'https://pmis-swrindianrailways.org/swrpmis/';

  /// QA matches production until a separate QA host is provided.
  static const String qaBaseUrl = prodBaseUrl;

  /// Hosted privacy policy (deploy [docs/swr-pmis-privacy-policy.html] here).
  static const String privacyPolicyRelativePath =
      'legal/swr-pmis-privacy-policy.html';

  static String absoluteUrlFor(String baseUrl, String relativePath) {
    final String trimmed = baseUrl.trim();
    final String root = trimmed.endsWith('/') ? trimmed : '$trimmed/';
    final String path = relativePath.startsWith('/')
        ? relativePath.substring(1)
        : relativePath;
    return '$root$path';
  }

  static String privacyPolicyUrlFor(String baseUrl) =>
      absoluteUrlFor(baseUrl, privacyPolicyRelativePath);

  static Uri originUriFor(String baseUrl) {
    final Uri parsed = Uri.parse(baseUrl);
    return Uri(
      scheme: parsed.scheme,
      host: parsed.host,
      port: parsed.hasPort ? parsed.port : null,
    );
  }
}
