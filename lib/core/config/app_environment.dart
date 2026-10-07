class AppEnvironment {
  const AppEnvironment._();

  static const String backendBaseUrl =
      String.fromEnvironment('BACKEND_BASE_URL');
  static bool get hasBackendConfig => backendBaseUrl.trim().isNotEmpty;
}
