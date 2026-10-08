class AppEnvironment {
  const AppEnvironment._();

  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static bool get hasBackendConfig => apiBaseUrl.trim().isNotEmpty;
}
