import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class AppLogger {
  static final AppLogger _instance = AppLogger._internal();

  factory AppLogger() {
    return _instance;
  }

  AppLogger._internal();

  static const String _prefix = '';

  /// Log debug message (only in development)
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _log(LogLevel.debug, message, error, stackTrace);
    }
  }

  /// Log info message
  static void info(String message) {
    if (kDebugMode) {
      _log(LogLevel.info, message, null, null);
    }
  }

  /// Log warning message
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }

  /// Log error message
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  /// Internal logging method
  static void _log(
    LogLevel level,
    String message,
    dynamic error,
    StackTrace? stackTrace,
  ) {
    final timestamp = DateTime.now().toIso8601String();
    final levelName = level.toString().split('.').last.toUpperCase();
    final log = '$_prefix [$levelName] [$timestamp] $message';

    if (error != null) {
      debugPrint('$log\nError: $error');
    } else {
      debugPrint(log);
    }

    if (stackTrace != null && kDebugMode) {
      debugPrint('StackTrace:\n$stackTrace');
    }
  }

  /// Log API request
  static void logApiRequest(String method, String endpoint, dynamic body) {
    if (kDebugMode) {
      debug('API REQUEST: $method $endpoint\nBody: $body');
    }
  }

  /// Log API response
  static void logApiResponse(String method, String endpoint, dynamic response) {
    if (kDebugMode) {
      debug('API RESPONSE: $method $endpoint\nResponse: $response');
    }
  }

  /// Log API error
  static void logApiError(
    String method,
    String endpoint,
    dynamic error,
    StackTrace? stackTrace,
  ) {
    this.error('API ERROR: $method $endpoint', error, stackTrace);
  }
}
