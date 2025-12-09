class ApiConfig {
  // Backend API URL
  static const String baseUrl = 'http://localhost:3000';

  // API Endpoints
  static const String chatEndpoint = '$baseUrl/api/chat/message';
  static const String healthEndpoint = '$baseUrl/health';
}
