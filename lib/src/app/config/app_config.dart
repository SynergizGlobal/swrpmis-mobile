class AppConfig {
  const AppConfig({required this.appName, required this.baseUrl});

  final String appName;
  final String baseUrl;

  AppConfig copyWith({String? baseUrl}) {
    return AppConfig(
      appName: appName,
      baseUrl: baseUrl ?? this.baseUrl,
    );
  }
}
