import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class AppLogger {
  static final AppLogger _instance = AppLogger._internal();

  factory AppLogger() {
    return _instance;
  }

  AppLogger._internal();

  static const String _prefix = '';
  static const Set<String> _sensitiveKeyFragments = {
    'token',
    'password',
    'pin',
    'otp',
    'secret',
    'installation_id',
    'fingerprint',
    'imei',
  };

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
      debug(
        'API REQUEST: $method $endpoint\nBody: ${_sanitizeForLogging(body)}',
      );
    }
  }

  /// Log API response
  static void logApiResponse(String method, String endpoint, dynamic response) {
    if (kDebugMode) {
      debug(
        'API RESPONSE: $method $endpoint\nResponse: ${_sanitizeForLogging(response)}',
      );
    }
  }

  /// Log API error
  static void logApiError(
    String method,
    String endpoint,
    dynamic error,
    StackTrace? stackTrace,
  ) {
    // Use the class static method instead of `this` to avoid instance reference
    AppLogger.error('API ERROR: $method $endpoint', error, stackTrace);
  }

  static dynamic _sanitizeForLogging(dynamic value, {String? keyHint}) {
    if (value is Map) {
      return {
        for (final entry in value.entries)
          entry.key: _sanitizeForLogging(
            entry.value,
            keyHint: entry.key.toString(),
          ),
      };
    }

    if (value is List) {
      return value
          .map((item) => _sanitizeForLogging(item, keyHint: keyHint))
          .toList();
    }

    if (_isSensitiveKey(keyHint)) {
      return _redactValue(value);
    }

    return value;
  }

  static bool _isSensitiveKey(String? key) {
    if (key == null || key.isEmpty) return false;

    final normalizedKey = key.toLowerCase();
    return _sensitiveKeyFragments.any(normalizedKey.contains);
  }

  static String _redactValue(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) return '[REDACTED]';
    if (text.length <= 6) return List.filled(text.length, '*').join();

    final prefix = text.substring(0, 2);
    final suffix = text.substring(text.length - 2);
    return '$prefix${List.filled(text.length - 4, '*').join()}$suffix';
  }
}
