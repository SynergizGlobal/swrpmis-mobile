class ApiHosts {
  const ApiHosts._();

  static const String prodBaseUrl =
      'https://pmis-swrindianrailways.org/swrpmis/';

  /// QA SWR PMIS (`/swrpmis_qa/` on the public HTTPS host).
  static const String qaBaseUrl =
      'https://pmis-swrindianrailways.org/swrpmis_qa/';

  /// Hosted privacy policy (same document as [docs/swr-pmis-privacy-policy.html]).
  static const String privacyPolicyUrl =
      'https://syntrackpro.com/images/swr-pmis-privacy-policy.html';

  static Uri originUriFor(String baseUrl) {
    final Uri parsed = Uri.parse(baseUrl);
    return Uri(
      scheme: parsed.scheme,
      host: parsed.host,
      port: parsed.hasPort ? parsed.port : null,
    );
  }
}
