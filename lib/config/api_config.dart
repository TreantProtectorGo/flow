import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  // Backend API URL (required for release builds via --dart-define=API_BASE_URL=...)
  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl.endsWith('/')
          ? _configuredBaseUrl.substring(0, _configuredBaseUrl.length - 1)
          : _configuredBaseUrl;
    }

    if (kReleaseMode) {
      throw StateError(
        'API_BASE_URL is required for release builds. '
        'Build with --dart-define=API_BASE_URL=https://your-api-domain',
      );
    }

    return 'http://localhost:3000';
  }

  // API Endpoints
  static String get chatEndpoint => '$baseUrl/api/chat/message';
  static String get healthEndpoint => '$baseUrl/health';
}
