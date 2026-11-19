import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../constants/app_constants.dart';
import '../exceptions/app_exceptions.dart';
import 'secure_auth_storage.dart';
import '../utils/logger.dart';

/// HTTP client singleton for all API calls
class HttpClient {
  static HttpClient? _instance;
  static HttpClient? _paymentInstance;
  late Dio _dio;
  final bool _supportsAuthRefresh;

  HttpClient._internal({
    required String baseUrl,
    bool supportsAuthRefresh = true,
  }) : _supportsAuthRefresh = supportsAuthRefresh {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: AppConstants.networkTimeout,
        receiveTimeout: AppConstants.apiTimeout,
        sendTimeout: AppConstants.apiTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) {
          // Route every non-success response through Dio's error interceptor.
          // In particular, 401 must reach the token refresh handler below.
          return status != null && status >= 200 && status < 300;
        },
      ),
    );

    _initializeInterceptors();
  }

  /// Get singleton instance
  static HttpClient get instance {
    _instance ??= HttpClient._internal(baseUrl: ApiEndpoints.baseUrl);
    return _instance!;
  }

  /// Client for the third-party payment gateway.
  static HttpClient get paymentInstance {
    _paymentInstance ??= HttpClient._internal(
      baseUrl: ApiEndpoints.paymentServiceBaseUrl,
      supportsAuthRefresh: false,
    );
    return _paymentInstance!;
  }

  /// Get Dio instance (for advanced use cases)
  Dio get dio => _dio;

  /// Initialize SharedPreferences
  Future<void> initializePreferences() async {
    await SecureAuthStorage.instance.initialize();
  }

  bool get _isDebugNoAuthMode {
    return kDebugMode && AppConstants.disableApiAuthInDebug;
  }

  /// Initialize interceptors
  void _initializeInterceptors() {
    _dio.interceptors.addAll([
      // Token injection interceptor
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Keep API auth optional in debug mode for backend endpoints that
          // rely on request payload credentials instead of bearer tokens.
          if (_isDebugNoAuthMode || options.extra['skipAuthHeader'] == true) {
            options.headers.remove('Authorization');
          } else if (options.extra['skipAuthRefresh'] != true) {
            await initializePreferences();
            final token = await SecureAuthStorage.instance.readAuthToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }

          AppLogger.logApiRequest(
            options.method,
            options.uri.toString(),
            options.data,
          );

          return handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.logApiResponse(
            response.requestOptions.method,
            response.requestOptions.uri.toString(),
            response.data,
            statusCode: response.statusCode,
          );
          return handler.next(response);
        },
        onError: (error, handler) async {
          // Handle token expiration (401)
          if (_supportsAuthRefresh &&
              !_isDebugNoAuthMode &&
              error.response?.statusCode == 401 &&
              error.requestOptions.extra['skipAuthRefresh'] != true &&
              error.requestOptions.extra['authRetry'] != true) {
            // Try to refresh token
            final refreshed = await _refreshToken();
            if (refreshed) {
              // Retry the original request
              final options = error.requestOptions;
              options.extra['authRetry'] = true;
              final token = await SecureAuthStorage.instance.readAuthToken();
              options.headers['Authorization'] = 'Bearer $token';

              try {
                final response = await _dio.fetch(options);
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            }
          }

          AppLogger.logApiError(
            error.requestOptions.method,
            error.requestOptions.uri.toString(),
            error,
            null,
          );

          return handler.next(error);
        },
      ),

      // Pretty logger (debug mode only)
      if (kDebugMode)
        PrettyDioLogger(
          requestHeader: false,
          requestBody: false,
          responseHeader: false,
          responseBody: false,
          error: false,
          compact: true,
          maxWidth: 90,
        ),
    ]);
  }

  /// Refresh token
  Future<bool> _refreshToken() async {
    try {
      await initializePreferences();
      final refreshToken = await SecureAuthStorage.instance.readRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        AppLogger.warning('No refresh token available');
        return false;
      }

      final response = await _dio.post(
        ApiEndpoints.refreshToken,
        data: {'refresh_token': refreshToken},
        options: Options(
          headers: {'Authorization': 'Bearer $refreshToken'},
          extra: {'skipAuthRefresh': true},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        final newToken = data['auth_token'] as String;
        final newRefreshToken = data['refresh_token'] as String?;

        // Save new tokens
        await SecureAuthStorage.instance.writeAuthToken(newToken);
        if (newRefreshToken != null) {
          await SecureAuthStorage.instance.writeRefreshToken(newRefreshToken);
        }

        AppLogger.info('Token refreshed successfully');
        return true;
      }

      return false;
    } catch (e, stackTrace) {
      AppLogger.error('Token refresh failed', e, stackTrace);
      return false;
    }
  }

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Handle Dio errors and convert to AppExceptions
  AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(
          message: AppConstants.timeoutErrorMessage,
          originalException: error,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;

        switch (statusCode) {
          case 400:
            return ValidationException(
              message:
                  _extractErrorMessage(responseData) ??
                  AppConstants.validationErrorMessage,
              originalException: error,
            );

          case 401:
            return AuthException(
              message:
                  _extractErrorMessage(responseData) ??
                  AppConstants.invalidCredentialsMessage,
              code: AppConstants.invalidCredentialsErrorCode,
              originalException: error,
            );

          case 403:
            return AuthException(
              message:
                  _extractErrorMessage(responseData) ??
                  'Access forbidden. Please check your permissions.',
              originalException: error,
            );

          case 404:
            return NotFoundException(
              message:
                  _extractErrorMessage(responseData) ?? 'Resource not found.',
              originalException: error,
            );

          case 422:
            return ValidationException(
              message:
                  _extractErrorMessage(responseData) ??
                  'Validation failed. Please check your input.',
              originalException: error,
            );

          case 429:
            return ServerException(
              message: 'Too many requests. Please try again later.',
              originalException: error,
            );

          default:
            return ServerException(
              message:
                  _extractErrorMessage(responseData) ??
                  AppConstants.genericErrorMessage,
              originalException: error,
            );
        }

      case DioExceptionType.cancel:
        return GenericException(
          message: 'Request cancelled',
          originalException: error,
        );

      case DioExceptionType.connectionError:
        return NetworkException(
          message: AppConstants.networkErrorMessage,
          originalException: error,
        );

      case DioExceptionType.badCertificate:
        return NetworkException(
          message: 'SSL certificate error. Please check your connection.',
          originalException: error,
        );

      default:
        return GenericException(
          message: AppConstants.genericErrorMessage,
          originalException: error,
        );
    }
  }

  /// Extract error message from response data
  String? _extractErrorMessage(dynamic responseData) {
    if (responseData == null) return null;

    if (responseData is Map) {
      // Try common error message keys
      if (responseData.containsKey('message')) {
        return responseData['message'] as String?;
      }
      if (responseData.containsKey('error')) {
        final error = responseData['error'];
        if (error is String) return error;
        if (error is Map && error.containsKey('message')) {
          return error['message'] as String?;
        }
      }
      if (responseData.containsKey('errors')) {
        final errors = responseData['errors'];
        if (errors is List && errors.isNotEmpty) {
          return errors.first.toString();
        }
        if (errors is Map && errors.isNotEmpty) {
          return errors.values.first.toString();
        }
      }
    }

    return null;
  }

  /// Clear all stored tokens (for logout)
  Future<void> clearTokens() async {
    await initializePreferences();
    await SecureAuthStorage.instance.clearAuthSecrets();
    AppLogger.info('Tokens cleared');
  }

  /// Update base URL (useful for switching environments)
  void updateBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl;
    AppLogger.info('Base URL updated to: $newBaseUrl');
  }
}
