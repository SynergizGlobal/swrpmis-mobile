class ApiHosts {
  const ApiHosts._();

  static const String qaBaseUrl = 'http://115.124.125.151:8443/swrpmis_qa/';
  static const String prodBaseUrl = 'http://115.124.125.151:8444/swrpmis/';

  static Uri originUriFor(String baseUrl) {
    final Uri parsed = Uri.parse(baseUrl);
    return Uri(
      scheme: parsed.scheme,
      host: parsed.host,
      port: parsed.hasPort ? parsed.port : null,
    );
  }
}
