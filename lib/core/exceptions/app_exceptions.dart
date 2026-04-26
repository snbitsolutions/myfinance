// Custom exception classes for better error handling

abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;

  AppException({required this.message, this.code, this.originalException});

  @override
  String toString() => message;
}

/// Network-related exceptions
class NetworkException extends AppException {
  NetworkException({
    required super.message,
    super.code,
    super.originalException,
  });
}

/// Server/API exceptions
class ServerException extends AppException {
  final int? statusCode;
  final dynamic responseData;

  ServerException({
    required super.message,
    this.statusCode,
    this.responseData,
    super.code,
    super.originalException,
  });
}

/// Authentication exceptions
class AuthException extends AppException {
  AuthException({
    required super.message,
    super.code,
    super.originalException,
  });
}

/// Validation exceptions
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  ValidationException({
    required super.message,
    this.fieldErrors,
    super.code,
    super.originalException,
  });
}

/// Cache/Storage exceptions
class CacheException extends AppException {
  CacheException({
    required super.message,
    super.code,
    super.originalException,
  });
}

/// Not Found exceptions
class NotFoundException extends AppException {
  NotFoundException({
    required super.message,
    super.code,
    super.originalException,
  });
}

/// Timeout exceptions
class TimeoutException extends AppException {
  TimeoutException({
    required super.message,
    super.code,
    super.originalException,
  });
}

/// Generic app exceptions
class GenericException extends AppException {
  GenericException({
    required super.message,
    super.code,
    super.originalException,
  });
}

/// Exception mapper - converts various exceptions to AppException
class ExceptionMapper {
  static AppException mapException(dynamic exception) {
    if (exception is AppException) {
      return exception;
    }

    if (exception is TimeoutException) {
      return TimeoutException(
        message: 'Request timed out',
        originalException: exception,
      );
    }

    if (exception is ServerException) {
      return exception;
    }

    if (exception is NetworkException) {
      return exception;
    }

    // Default to generic exception
    return GenericException(
      message: exception.toString(),
      originalException: exception,
    );
  }
}
