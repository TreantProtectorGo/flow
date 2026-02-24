class ApiConfig {
  // Backend API URL (override with --dart-define=API_BASE_URL=...)
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  // API Endpoints
  static const String chatEndpoint = '$baseUrl/api/chat/message';
  static const String healthEndpoint = '$baseUrl/health';
}
