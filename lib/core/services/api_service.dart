import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import '../exceptions/app_exceptions.dart';
import '../models/auth_session.dart';
import 'http_client.dart';
import '../utils/logger.dart';

/// Abstract service for all API calls with error handling
abstract class BaseService {
  static final Options stccuFormOptions = Options(
    contentType: Headers.formUrlEncodedContentType,
  );

  Map<String, dynamic> normalizeResponsePayload(dynamic raw) {
    if (raw == null) {
      return <String, dynamic>{};
    }

    final response = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{'data': raw};

    final payload = AuthSession.extractPayload(response);

    final normalized = <String, dynamic>{
      ...payload,
      if (response.containsKey('status'))
        'status': response['status']
      else if (payload.containsKey('status'))
        'status': payload['status'],
      if (response.containsKey('message'))
        'message': response['message']
      else if (payload.containsKey('message'))
        'message': payload['message'],
      if (response.containsKey('pagination'))
        'pagination': response['pagination'],
      if (response.containsKey('meta')) 'meta': response['meta'],
      if (response.containsKey('error')) 'error': response['error'],
      if (response.containsKey('data')) 'data': response['data'],
    };

    // Preserve arrays/objects nested under the server's data envelope without
    // losing any sibling metadata like pagination or status.
    if (response.containsKey('data') && response['data'] is Map) {
      final nested = Map<String, dynamic>.from(response['data'] as Map);
      for (final entry in nested.entries) {
        normalized.putIfAbsent(entry.key, () => entry.value);
      }
    }

    return normalized;
  }

  bool isBackendEmptyPayload(dynamic raw) {
    if (raw == null) return true;
    if (raw is String) {
      final trimmed = raw.trim();
      return trimmed.isEmpty || trimmed == '""' || trimmed == 'null';
    }
    return false;
  }

  bool hasExplicitFailure(Map<String, dynamic> payload) {
    final status = payload['status'];
    if (status == null) return false;
    return !AuthSession.isSuccessStatus(status) &&
        !(status is String && status.trim().isEmpty);
  }

  Future<T> handleApiCall<T>(Future<T> Function() apiCall) async {
    try {
      AppLogger.debug('Executing API call');
      final result = await apiCall();
      AppLogger.debug('API call successful');
      return result;
    } on TimeoutException catch (e) {
      // TimeoutException is not a subtype of AppException, so handle it first
      AppLogger.error('Timeout error', e);
      throw TimeoutException(
        message: AppConstants.timeoutErrorMessage,
        originalException: e,
      );
    } on AppException {
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error in API call', e, stackTrace);
      throw GenericException(
        message: AppConstants.genericErrorMessage,
        originalException: e,
      );
    }
  }
}

/// User authentication service
class AuthService extends BaseService {
  final HttpClient _httpClient = HttpClient.instance;

  Future<Map<String, dynamic>> confirmPhoneNumber({
    required String phoneNumber,
  }) async {
    return handleApiCall(() async {
      final request = {
        'phone_number': phoneNumber,
        's_key': AppConstants.defaultMobileApiSKey,
      };

      AppLogger.logApiRequest('POST', ApiEndpoints.confirmPhoneNumber, request);

      final response = await _httpClient.post<dynamic>(
        ApiEndpoints.confirmPhoneNumber,
        data: request,
        options: BaseService.stccuFormOptions,
      );

      final raw = response.data;
      final data = normalizeResponsePayload(raw);

      AppLogger.logApiResponse('POST', ApiEndpoints.confirmPhoneNumber, data);

      if (data.isNotEmpty) {
        final status = data['status'];
        final isExplicitFailure =
            status != null &&
            status != 1 &&
            status != '1' &&
            !(status is String && status.toLowerCase() == 'success');

        if (isExplicitFailure) {
          throw AuthException(
            message: data['message'] as String? ?? 'Phone verification failed.',
          );
        }
      }
      return data;
    });
  }

  Future<void> confirmAccountNumber({
    required String phoneNumber,
    required String accountNumber,
    required String birthDate,
  }) async {
    return handleApiCall(() async {
      final request = {
        'phone_number': phoneNumber,
        'account_number': accountNumber,
        'birth_date': _validBirthDate(birthDate),
        's_key': AppConstants.defaultMobileApiSKey,
      };

      AppLogger.logApiRequest(
        'POST',
        ApiEndpoints.confirmAccountNumber,
        request,
      );

      final response = await _httpClient.post<dynamic>(
        ApiEndpoints.confirmAccountNumber,
        data: request,
        options: BaseService.stccuFormOptions,
      );

      final raw = response.data;
      final data = normalizeResponsePayload(raw);

      AppLogger.logApiResponse('POST', ApiEndpoints.confirmAccountNumber, data);

      final status = data['status'] ?? data['success'] ?? data['is_success'];
      if (status != null && !AuthSession.isSuccessStatus(status)) {
        throw AuthException(
          message:
              data['message'] as String? ??
              'We could not verify your account details. Check your account '
                  'number, phone number, and date of birth, then try again.',
        );
      }
    });
  }

  Future<Map<String, dynamic>> confirmPin({
    required String phoneNumber,
    required String accountNumber,
    required String pin,
  }) async {
    return handleApiCall(() async {
      final request = <String, dynamic>{
        if (phoneNumber.trim().isNotEmpty) 'phone_number': phoneNumber,
        // Keep as string so leading zeros are preserved during OTP/PIN checks.
        'pin': pin.trim(),
        'account_number': accountNumber.trim(),
        's_key': AppConstants.defaultMobileApiSKey,
      };

      AppLogger.logApiRequest('POST', ApiEndpoints.confirmPin, request);

      final response = await _httpClient.post<dynamic>(
        ApiEndpoints.confirmPin,
        data: request,
      );

      final data = response.data;
      final result = normalizeResponsePayload(data);

      AppLogger.logApiResponse('POST', ApiEndpoints.confirmPin, result);
      return result;
    });
  }

  /// Sends the documented login OTP request. The mobile API identifies a
  /// member by the last five digits of their account number.
  Map<String, int> _loginIdentifierPayload({
    required String phoneNumber,
    required String accountNumber,
  }) {
    final resolvedAccount = accountNumber.trim().isNotEmpty
        ? accountNumber
        : phoneNumber;
    return <String, int>{
      // The backend expects numeric values for both identifiers, not strings.
      'phone_number': int.parse(_toInternationalPhoneNumber(phoneNumber)),
      'member_id': _memberIdFromAccountNumber(resolvedAccount),
    };
  }

  Future<void> sendLoginOtp({
    required String phoneNumber,
    required String accountNumber,
  }) async {
    return handleApiCall(() async {
      final request = _loginIdentifierPayload(
        phoneNumber: phoneNumber,
        accountNumber: accountNumber,
      );

      AppLogger.logApiRequest('POST', ApiEndpoints.sendLoginOtp, request);
      final response = await _httpClient.post<dynamic>(
        ApiEndpoints.sendLoginOtp,
        data: request,
      );

      if (response.statusCode == 200 && isBackendEmptyPayload(response.data)) {
        AppLogger.warning(
          'Legacy STCCU OTP endpoint returned an empty payload; this is not a valid success response.',
        );
        throw AuthException(
          message:
              'The OTP service returned an empty response. Please verify the member credentials and API contract.',
        );
      }

      final result = normalizeResponsePayload(response.data);
      AppLogger.logApiResponse('POST', ApiEndpoints.sendLoginOtp, result);

      if (!AuthSession.isSuccessStatus(result['status'])) {
        throw AuthException(
          message:
              result['message'] as String? ??
              'The OTP service returned an empty or invalid response.',
        );
      }
    });
  }

  /// Verifies the SMS code issued during login. This is deliberately distinct
  /// from [confirmPin], which is for PIN sign-in.
  Future<Map<String, dynamic>> verifyLoginOtp({
    required String accountNumber,
    required String otp,
  }) async {
    return handleApiCall(() async {
      final fullAccountNumber = accountNumber.trim();
      final request = <String, dynamic>{
        'member_id': _memberIdFromAccountNumber(
          fullAccountNumber.isNotEmpty
              ? fullAccountNumber
              : '0$fullAccountNumber',
        ),
        'otp': int.parse(otp.trim()),
      };

      AppLogger.logApiRequest('POST', ApiEndpoints.verifyLoginOtp, request);
      final response = await _httpClient.post<dynamic>(
        ApiEndpoints.verifyLoginOtp,
        data: request,
      );

      if (response.statusCode == 200 && isBackendEmptyPayload(response.data)) {
        AppLogger.warning(
          'Legacy STCCU verify-login-OTP endpoint returned an empty payload; this is not a valid verification response.',
        );
        throw AuthException(
          message:
              'The OTP verification endpoint returned an empty response. Please verify the member credentials and API contract.',
        );
      }

      final result = normalizeResponsePayload(response.data);
      AppLogger.logApiResponse('POST', ApiEndpoints.verifyLoginOtp, result);
      return {
        ...result,
        if (!result.containsKey('account_number'))
          'account_number': fullAccountNumber,
      };
    });
  }

  int _memberIdFromAccountNumber(String accountNumber) {
    final digits = accountNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 5) {
      throw ValidationException(
        message: 'Account number must contain at least five digits.',
      );
    }
    return int.parse(digits.substring(digits.length - 5));
  }

  String _validAccountNumber(String accountNumber) {
    final digits = accountNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 5) {
      throw ValidationException(
        message: 'Account number must contain at least five digits.',
      );
    }
    return digits;
  }

  String _validBirthDate(String birthDate) {
    final trimmed = birthDate.trim();
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(trimmed)) {
      throw ValidationException(
        message: 'Date of birth must use the format YYYY-MM-DD.',
      );
    }

    final year = int.tryParse(trimmed.substring(0, 4));
    final month = int.tryParse(trimmed.substring(5, 7));
    final day = int.tryParse(trimmed.substring(8, 10));
    if (year == null || month == null || day == null) {
      throw ValidationException(
        message: 'Date of birth must use the format YYYY-MM-DD.',
      );
    }

    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      throw ValidationException(
        message: 'Date of birth must be a valid calendar date.',
      );
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    if (parsed.isAfter(todayDate)) {
      throw ValidationException(
        message: 'Date of birth cannot be later than today.',
      );
    }

    return trimmed;
  }

  String _toInternationalPhoneNumber(String phoneNumber) {
    final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('233')) return digits;
    if (digits.startsWith('0') && digits.length == 10) {
      return '233${digits.substring(1)}';
    }
    throw ValidationException(message: 'Enter a valid Ghana phone number.');
  }

  /// Enroll an existing member via the documented mobile app /register API.
  Future<Map<String, dynamic>> register({
    required String accountNumber,
    required String phoneNumber,
    required String birthDate,
    String? password,
    String? pin,
    String? transactionPin,
    required int imeiNumber,
    required String phoneMake,
  }) async {
    return handleApiCall(() async {
      final normalizedAccountNumber = _validAccountNumber(accountNumber);
      final normalizedBirthDate = _validBirthDate(birthDate);
      final normalizedPassword = password?.trim();
      if (normalizedPassword != null && normalizedPassword.length < 8) {
        throw ValidationException(
          message: 'Password must be at least 8 characters.',
        );
      }

      final normalizedPin = pin?.trim();
      if (normalizedPin != null &&
          !RegExp(r'^\d{4}$').hasMatch(normalizedPin)) {
        throw ValidationException(message: 'App PIN must be exactly 4 digits.');
      }

      final normalizedTransactionPin = transactionPin?.trim();
      if (normalizedTransactionPin != null &&
          !RegExp(r'^\d{4}$').hasMatch(normalizedTransactionPin)) {
        throw ValidationException(
          message: 'Transaction PIN must be exactly 4 digits.',
        );
      }
      if (normalizedTransactionPin == null) {
        throw ValidationException(
          message: 'Transaction PIN is required for registration.',
        );
      }

      final request = <String, dynamic>{
        'acc_number':
            int.tryParse(normalizedAccountNumber) ?? normalizedAccountNumber,
        'phone_number': int.parse(_toInternationalPhoneNumber(phoneNumber)),
        'birth_date': normalizedBirthDate,
        'password': ?normalizedPassword,
        if (normalizedPin != null)
          'pin': int.tryParse(normalizedPin) ?? normalizedPin,
        'trans_pin':
            int.tryParse(normalizedTransactionPin) ?? normalizedTransactionPin,
        // The API's legacy field name is imei_number; the value is an
        // app-installation ID because iOS and modern Android do not expose IMEI.
        'imei_number': imeiNumber,
        'phone_make': phoneMake,
        's_key': AppConstants.defaultMobileApiSKey,
      };
      AppLogger.logApiRequest('POST', ApiEndpoints.register, request);

      final response = await _httpClient.post<dynamic>(
        ApiEndpoints.register,
        data: request,
      );

      final raw = response.data;
      final data = normalizeResponsePayload(raw);

      AppLogger.logApiResponse('POST', ApiEndpoints.register, data);
      return data;
    });
  }

  Future<Map<String, dynamic>> createMember({
    required String fullName,
    required String ghanaCard,
    required String phoneNumber,
    required String birthDate,
    required String gender,
    required String address,
    required String email,
    required int savingsProduct,
    required int sharesProduct,
    required String password,
    required String transactionPin,
    required int imeiNumber,
    required String phoneMake,
  }) async {
    return handleApiCall(() async {
      final normalizedPhoneNumber = _toInternationalPhoneNumber(phoneNumber);
      final normalizedBirthDate = _validBirthDate(birthDate);
      if (fullName.trim().isEmpty) {
        throw ValidationException(message: 'Full name is required.');
      }
      if (!RegExp(r'^GHA-\d{8,9}-\d$').hasMatch(ghanaCard.trim())) {
        throw ValidationException(
          message:
              'Enter a valid Ghana Card number in the format GHA-XXXXXXXXX-X.',
        );
      }
      if (!RegExp(r'^\d{4}$').hasMatch(transactionPin.trim())) {
        throw ValidationException(
          message: 'Transaction PIN must be exactly 4 digits.',
        );
      }

      final request = <String, dynamic>{
        'full_name': fullName,
        'ghana_card': ghanaCard,
        'phone_number': int.parse(normalizedPhoneNumber),
        'birth_date': normalizedBirthDate,
        'gender': gender,
        'address': address,
        'email': email,
        'savings_product': savingsProduct,
        'shares_product': sharesProduct,
        // Passwords must remain strings even when the user enters only digits.
        'password': password,
        'trans_pin': int.tryParse(transactionPin) ?? transactionPin,
        // The API's legacy field name is imei_number; the value is an
        // app-installation ID because iOS and modern Android do not expose IMEI.
        'imei_number': imeiNumber,
        'phone_make': phoneMake,
        's_key': AppConstants.defaultMobileApiSKey,
      };
      AppLogger.logApiRequest('POST', ApiEndpoints.createMember, request);
      final response = await _httpClient.post<dynamic>(
        ApiEndpoints.createMember,
        data: request,
      );
      final data = normalizeResponsePayload(response.data);
      AppLogger.logApiResponse(
        'POST',
        ApiEndpoints.createMember,
        data,
        statusCode: response.statusCode,
      );
      return {
        ...data,
        if (!data.containsKey('status'))
          '_http_success':
              response.statusCode != null &&
              response.statusCode! >= 200 &&
              response.statusCode! < 300,
      };
    });
  }

  static dynamic _normalizeNumberLikeJsonValue(String value) {
    final trimmed = value.trim();
    if (!RegExp(r'^(0|[1-9]\d*)$').hasMatch(trimmed)) return trimmed;
    return int.tryParse(trimmed) ?? trimmed;
  }

  /// Login with a phone number and the member's login password.
  Future<Map<String, dynamic>> login({
    required String phoneNumber,
    required String password,
    required int imeiNumber,
  }) async {
    return handleApiCall(() async {
      final normalizedPhone = _toInternationalPhoneNumber(phoneNumber);
      final normalizedPassword = password.trim();
      if (normalizedPhone.length < 9 || normalizedPassword.isEmpty) {
        throw ValidationException(
          message: 'Enter a valid phone number and password.',
        );
      }

      final request = <String, dynamic>{
        'phone_number': int.parse(normalizedPhone),
        'password': _normalizeNumberLikeJsonValue(normalizedPassword),
        's_key': AppConstants.defaultMobileApiSKey,
        'imei_number': imeiNumber,
      };

      AppLogger.logApiRequest('POST', ApiEndpoints.login, request);
      final response = await _httpClient.post<dynamic>(
        ApiEndpoints.login,
        data: request,
        options: Options(
          extra: {'skipAuthHeader': true, 'skipAuthRefresh': true},
        ),
      );
      final data = normalizeResponsePayload(response.data);
      AppLogger.logApiResponse(
        'POST',
        ApiEndpoints.login,
        data,
        statusCode: response.statusCode,
      );

      if (hasExplicitFailure(data)) {
        final message =
            data['message']?.toString() ??
            AppConstants.invalidCredentialsMessage;
        final normalizedMessage = message.toLowerCase();
        final isInvalidPin =
            normalizedMessage.contains('invalid pin') ||
            normalizedMessage.contains('incorrect pin') ||
            normalizedMessage.contains('wrong pin') ||
            normalizedMessage.contains('invalid credential') ||
            normalizedMessage.contains('invalid password') ||
            normalizedMessage.contains('incorrect password');
        throw AuthException(
          message: message,
          code: isInvalidPin ? AppConstants.invalidCredentialsErrorCode : null,
        );
      }

      return data;
    });
  }

  /// Login using the documented phone number and PIN contract.
  Future<Map<String, dynamic>> loginWithPhonePin({
    required String phoneNumber,
    required String pin,
    required int imeiNumber,
  }) async {
    return handleApiCall(() async {
      final normalizedPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
      final normalizedPin = pin.trim();
      if (normalizedPhone.isEmpty ||
          !RegExp(r'^\d{4}$').hasMatch(normalizedPin)) {
        throw ValidationException(
          message: 'Enter a valid phone number and 4-digit PIN.',
        );
      }

      final request = <String, dynamic>{
        'password': _normalizeNumberLikeJsonValue(normalizedPin),
        'phone_number': int.tryParse(normalizedPhone) ?? normalizedPhone,
        's_key': AppConstants.defaultMobileApiSKey,
        'imei_number': imeiNumber,
      };

      AppLogger.logApiRequest('POST', ApiEndpoints.login, request);
      final response = await _httpClient.post<dynamic>(
        ApiEndpoints.login,
        data: request,
      );
      final data = normalizeResponsePayload(response.data);
      AppLogger.logApiResponse(
        'POST',
        ApiEndpoints.login,
        data,
        statusCode: response.statusCode,
      );

      return data;
    });
  }

  /// Request a password reset code using the documented mobile-app contract.
  Future<Map<String, dynamic>> requestPasswordReset({
    required String accountNumber,
    required int imeiNumber,
  }) async {
    return handleApiCall(() async {
      final normalizedAccount = accountNumber.replaceAll(RegExp(r'\D'), '');
      if (normalizedAccount.isEmpty) {
        throw ValidationException(message: 'Account number is required.');
      }

      final request = <String, dynamic>{
        'account_number': normalizedAccount,
        'imei_number': imeiNumber,
        's_key': AppConstants.defaultMobileApiSKey,
      };

      AppLogger.logApiRequest(
        'POST',
        ApiEndpoints.requestPasswordReset,
        request,
      );
      final response = await _httpClient.post<dynamic>(
        ApiEndpoints.requestPasswordReset,
        data: request,
      );

      final data = normalizeResponsePayload(response.data);
      AppLogger.logApiResponse(
        'POST',
        ApiEndpoints.requestPasswordReset,
        data,
        statusCode: response.statusCode,
      );

      if (hasExplicitFailure(data)) {
        throw AuthException(
          message:
              data['message']?.toString() ??
              'We could not send the reset code. Please try again.',
        );
      }

      return data;
    });
  }

  /// Verify the one-time password sent during a reset request.
  Future<Map<String, dynamic>> verifyPasswordResetOtp({
    required String requestId,
    required String otp,
  }) async {
    return handleApiCall(() async {
      final request = <String, dynamic>{
        'request_id': requestId,
        'otp': int.tryParse(otp.trim()) ?? otp.trim(),
      };

      AppLogger.logApiRequest(
        'POST',
        ApiEndpoints.verifyPasswordResetOtp,
        request,
      );
      final response = await _httpClient.post<dynamic>(
        ApiEndpoints.verifyPasswordResetOtp,
        data: request,
      );

      final data = normalizeResponsePayload(response.data);
      AppLogger.logApiResponse(
        'POST',
        ApiEndpoints.verifyPasswordResetOtp,
        data,
        statusCode: response.statusCode,
      );

      if (hasExplicitFailure(data)) {
        throw AuthException(
          message:
              data['message']?.toString() ??
              'The reset code could not be verified.',
        );
      }

      return data;
    });
  }

  /// Complete the password reset using the verified request ID and the new password.
  Future<Map<String, dynamic>> passwordReset({
    required String requestId,
    required String newPassword,
    required int imeiNumber,
  }) async {
    return handleApiCall(() async {
      final normalizedPassword = newPassword.trim();
      if (normalizedPassword.isEmpty) {
        throw ValidationException(message: 'New password is required.');
      }

      final request = <String, dynamic>{
        'imei_number': imeiNumber,
        'password': int.tryParse(normalizedPassword) ?? normalizedPassword,
        'request_id': requestId,
        's_key': AppConstants.defaultMobileApiSKey,
      };

      AppLogger.logApiRequest('POST', ApiEndpoints.passwordReset, request);
      final response = await _httpClient.post<dynamic>(
        ApiEndpoints.passwordReset,
        data: request,
      );

      final data = normalizeResponsePayload(response.data);
      AppLogger.logApiResponse(
        'POST',
        ApiEndpoints.passwordReset,
        data,
        statusCode: response.statusCode,
      );

      if (hasExplicitFailure(data)) {
        throw AuthException(
          message:
              data['message']?.toString() ??
              'The password could not be reset. Please try again.',
        );
      }

      return data;
    });
  }

  /// Request an account deletion verification code.
  Future<Map<String, dynamic>> requestAccountDeletion({
    required int imeiNumber,
  }) async {
    return handleApiCall(() async {
      final request = <String, dynamic>{
        'imei_number': imeiNumber,
        's_key': AppConstants.defaultMobileApiSKey,
      };

      AppLogger.logApiRequest('POST', ApiEndpoints.requestDeletion, request);
      final response = await _httpClient.post<dynamic>(
        ApiEndpoints.requestDeletion,
        data: request,
      );

      final data = normalizeResponsePayload(response.data);
      AppLogger.logApiResponse(
        'POST',
        ApiEndpoints.requestDeletion,
        data,
        statusCode: response.statusCode,
      );

      if (hasExplicitFailure(data)) {
        throw AuthException(
          message:
              data['message']?.toString() ??
              'We could not start account deletion. Please try again.',
        );
      }

      return data;
    });
  }

  /// Verify the OTP used to authorize account deletion.
  Future<Map<String, dynamic>> verifyAccountDeletionOtp({
    required String requestId,
    required String otp,
  }) async {
    return handleApiCall(() async {
      final request = <String, dynamic>{
        'request_id': requestId,
        'otp': int.tryParse(otp.trim()) ?? otp.trim(),
      };

      AppLogger.logApiRequest('POST', ApiEndpoints.verifyDeletionOtp, request);
      final response = await _httpClient.post<dynamic>(
        ApiEndpoints.verifyDeletionOtp,
        data: request,
      );

      final data = normalizeResponsePayload(response.data);
      AppLogger.logApiResponse(
        'POST',
        ApiEndpoints.verifyDeletionOtp,
        data,
        statusCode: response.statusCode,
      );

      if (hasExplicitFailure(data)) {
        throw AuthException(
          message:
              data['message']?.toString() ??
              'The deletion code could not be verified.',
        );
      }

      return data;
    });
  }

  /// Permanently delete the account after verification.
  Future<Map<String, dynamic>> deleteAccount({
    required String requestId,
    required int imeiNumber,
  }) async {
    return handleApiCall(() async {
      final request = <String, dynamic>{
        'request_id': requestId,
        'imei_number': imeiNumber,
        's_key': AppConstants.defaultMobileApiSKey,
      };

      AppLogger.logApiRequest('POST', ApiEndpoints.deleteAccount, request);
      final response = await _httpClient.post<dynamic>(
        ApiEndpoints.deleteAccount,
        data: request,
      );

      final data = normalizeResponsePayload(response.data);
      AppLogger.logApiResponse(
        'POST',
        ApiEndpoints.deleteAccount,
        data,
        statusCode: response.statusCode,
      );

      if (hasExplicitFailure(data)) {
        throw AuthException(
          message:
              data['message']?.toString() ??
              'Account deletion could not be completed. Please try again.',
        );
      }

      return data;
    });
  }

  /// Send OTP to email/phone
  Future<Map<String, dynamic>> sendOtp({
    required String email,
    Map<String, dynamic>? deviceContext,
  }) async {
    return handleApiCall(() async {
      AppLogger.logApiRequest('POST', ApiEndpoints.sendOtp, {
        'email': email,
        'device_context': deviceContext,
      });
      throw ValidationException(
        message:
            'Legacy send OTP endpoint is not supported by the STCCU API. Use phone/account verification flow.',
      );
    });
  }

  /// Verify OTP
  Future<Map<String, dynamic>> verifyOtp({
    required String otpId,
    required String otp,
    Map<String, dynamic>? deviceContext,
  }) async {
    return handleApiCall(() async {
      AppLogger.logApiRequest('POST', ApiEndpoints.verifyOtp, {
        'otp_id': otpId,
        'device_context': deviceContext,
      });
      throw ValidationException(
        message:
            'Legacy verify OTP endpoint is not supported by the STCCU API. Use phone/account/PIN sign in.',
      );
    });
  }

  /// Set PIN
  Future<Map<String, dynamic>> setPin({
    required String userId,
    required String pin,
    required int imeiNumber,
    Map<String, dynamic>? deviceContext,
  }) async {
    return handleApiCall(() async {
      if (pin.isEmpty || pin.length != AppConstants.pinLength) {
        throw ValidationException(
          message: 'PIN must be ${AppConstants.pinLength} digits',
        );
      }

      final request = {
        'pin': int.tryParse(pin) ?? pin,
        'imei_number': imeiNumber,
        'account_number': int.tryParse(userId) ?? userId,
        's_key': AppConstants.defaultMobileApiSKey,
      };
      AppLogger.logApiRequest('POST', ApiEndpoints.setPin, request);

      final response = await _httpClient.post<dynamic>(
        ApiEndpoints.setPin,
        data: request,
      );

      final raw = response.data;
      final data = normalizeResponsePayload(raw);

      AppLogger.logApiResponse('POST', ApiEndpoints.setPin, data);

      return data;
    });
  }

  /// Change the transaction PIN using the documented mobile-app endpoint.
  Future<Map<String, dynamic>> changePin({
    required String accountNumber,
    required String currentPin,
    required String newPin,
    required int imeiNumber,
  }) async {
    return handleApiCall(() async {
      if (!RegExp(r'^\d{4}$').hasMatch(currentPin) ||
          !RegExp(r'^\d{4}$').hasMatch(newPin)) {
        throw ValidationException(
          message: 'PIN must be ${AppConstants.pinLength} digits',
        );
      }

      final request = {
        'current_pin': int.tryParse(currentPin) ?? currentPin,
        'new_pin': int.tryParse(newPin) ?? newPin,
        'account_number': int.tryParse(accountNumber) ?? accountNumber,
        'imei_number': imeiNumber,
        's_key': AppConstants.defaultMobileApiSKey,
      };
      AppLogger.logApiRequest('POST', ApiEndpoints.changePin, request);

      final response = await _httpClient.post<dynamic>(
        ApiEndpoints.changePin,
        data: request,
      );
      final data = normalizeResponsePayload(response.data);
      AppLogger.logApiResponse('POST', ApiEndpoints.changePin, data);
      return data;
    });
  }

  /// Logout
  Future<Map<String, dynamic>> logout({required String userId}) async {
    return handleApiCall(() async {
      AppLogger.logApiRequest('POST', ApiEndpoints.logout, {'user_id': userId});
      // STCCU API has no server-side logout endpoint; session is cleared locally.
      final response = {'status': 'success', 'message': 'Logged out locally'};
      AppLogger.logApiResponse('POST', ApiEndpoints.logout, response);
      return response;
    });
  }
}

/// User profile service
class UserService extends BaseService {
  /// The published collection does not expose a profile endpoint.
  ///
  /// Keep this method for callers that still need a normalized account-shaped
  /// response, but do not use the undocumented /getAccountBalance route.
  Future<Map<String, dynamic>> getUserProfile({
    required String phoneNumber,
    required String accountNumber,
    required String pin,
  }) async {
    return handleApiCall(() async {
      return {
        'data': {
          'user_id': accountNumber,
          'name': 'Account holder',
          'account_number': accountNumber,
          'balance': null,
          'branch': null,
          'phone': phoneNumber,
          'status': null,
        },
      };
    });
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    return handleApiCall(() async {
      AppLogger.logApiRequest(
        'PUT',
        '${ApiEndpoints.updateUserProfile}/$userId',
        data,
      );
      throw ValidationException(
        message: 'Profile update endpoint is not available in STCCU API.',
      );
    });
  }

  /// Submit KYC verification
  Future<Map<String, dynamic>> submitKyc({
    required String userId,
    required Map<String, dynamic> kycData,
  }) async {
    return handleApiCall(() async {
      AppLogger.logApiRequest(
        'POST',
        '${ApiEndpoints.submitKyc}/$userId',
        kycData,
      );
      throw ValidationException(
        message: 'KYC submission endpoint is not available in STCCU API.',
      );
    });
  }
}

/// Loan service
class LoanService extends BaseService {
  final HttpClient _httpClient = HttpClient.instance;

  static double? _toDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', ''));
  }

  /// Get list of loans for user via live /getLoans endpoint
  Future<Map<String, dynamic>> getLoansList({
    required String phoneNumber,
    required String accountNumber,
    required String pin,
    required int imeiNumber,
  }) async {
    return handleApiCall(() async {
      final request = {
        'account_number': int.tryParse(accountNumber) ?? accountNumber,
        'imei_number': imeiNumber,
        's_key': AppConstants.defaultMobileApiSKey,
      };
      AppLogger.logApiRequest('POST', ApiEndpoints.getLoans, request);

      final response = await _httpClient.post<dynamic>(
        ApiEndpoints.getLoans,
        data: request,
      );

      final raw = response.data;
      if (isBackendEmptyPayload(raw)) {
        throw GenericException(
          message:
              'No loan data returned from server. Please verify your credentials and try again.',
        );
      }
      final data = normalizeResponsePayload(raw);

      AppLogger.logApiResponse('POST', ApiEndpoints.getLoans, data);

      if (data['data'] is String &&
          (data['data'] as String).contains('<html')) {
        throw GenericException(
          message:
              'The loans endpoint returned 404. Please verify that /getMemLoans is enabled on the backend.',
        );
      }

      if (hasExplicitFailure(data)) {
        throw GenericException(
          message: data['message']?.toString() ?? 'Unable to load loans.',
        );
      }

      // Normalise STCCU loans response
      final loansRaw =
          <dynamic>[data['loans'], data['products'], data['data']].firstWhere(
                (value) => value is List,
                orElse: () => const <dynamic>[],
              )
              as List;
      final normalizedLoans = loansRaw
          .whereType<Map<String, dynamic>>()
          .map(
            (loan) => {
              'loan_id':
                  loan['id'] as String? ?? loan['loan_id'] as String? ?? '',
              'name':
                  loan['name'] as String? ??
                  loan['product_name'] as String? ??
                  loan['pro_name'] as String? ??
                  'Loan',
              'amount': _toDoubleOrNull(
                loan['original_amount'] ?? loan['amount'],
              ),
              'outstanding_balance': _toDoubleOrNull(
                loan['outstanding_balance'] ?? loan['balance'],
              ),
              'status': loan['status']?.toString().toLowerCase(),
              'interest_rate': _toDoubleOrNull(loan['interest_rate']),
              'next_payment_due': loan['due_date'] as String? ?? '',
              'disbursement_date': loan['created_date'] as String? ?? '',
            },
          )
          .toList();

      return {'status': 'success', 'data': normalizedLoans};
    });
  }

  /// Get current outstanding loan balance for a member.
  Future<Map<String, dynamic>> getLoanBalance({
    required String accountNumber,
    String? loanId,
  }) async {
    return handleApiCall(() async {
      final request = {
        'account_number': accountNumber.trim(),
        if (loanId != null && loanId.trim().isNotEmpty) 'loan_id': loanId,
        's_key': AppConstants.defaultMobileApiSKey,
      };
      AppLogger.logApiRequest('POST', ApiEndpoints.getLoanBalance, request);

      final response = await _httpClient.post<dynamic>(
        ApiEndpoints.getLoanBalance,
        data: request,
      );

      final data = normalizeResponsePayload(response.data);
      AppLogger.logApiResponse('POST', ApiEndpoints.getLoanBalance, data);

      if (hasExplicitFailure(data)) {
        throw GenericException(
          message:
              data['message']?.toString() ??
              'Unable to retrieve the loan balance.',
        );
      }

      final outstanding =
          data['balance'] ??
          data['outstanding_balance'] ??
          data['loan_balance'] ??
          data['current_balance'] ??
          data['total_balance'] ??
          (data['data'] is Map
              ? (data['data'] as Map)['balance'] ??
                    (data['data'] as Map)['outstanding_balance'] ??
                    (data['data'] as Map)['loan_balance']
              : null);

      return {
        'status': 'success',
        'balance': _toDoubleOrNull(outstanding),
        'raw': data,
      };
    });
  }

  /// Get loan detail
  Future<Map<String, dynamic>> getLoanDetail({required String loanId}) async {
    return handleApiCall(() async {
      AppLogger.logApiRequest('GET', ApiEndpoints.getLoanDetail, {
        'loan_id': loanId,
      });
      throw BackendNotConfiguredException(
        message: 'Loan detail is waiting for the backend endpoint contract.',
      );
    });
  }

  /// Apply for a loan
  Future<Map<String, dynamic>> applyLoan({
    required String accountNumber,
    required double amount,
    required String purpose,
    required int imeiNumber,
    int productId = 1,
  }) async {
    return handleApiCall(() async {
      final normalizedAccountNumber = accountNumber.trim();
      final normalizedPurpose = purpose.trim();

      if (normalizedAccountNumber.isEmpty) {
        throw ValidationException(message: 'Account number is required.');
      }
      if (amount < AppConstants.loanMinAmount ||
          amount > AppConstants.loanMaxAmount) {
        throw ValidationException(
          message:
              'Loan amount must be between ${AppConstants.loanMinAmount} and ${AppConstants.loanMaxAmount}',
        );
      }
      if (normalizedPurpose.isEmpty) {
        throw ValidationException(message: 'Loan purpose is required.');
      }
      if (productId <= 0) {
        throw ValidationException(message: 'A valid loan product is required.');
      }

      final request = {
        'account_number': normalizedAccountNumber,
        'product_id': productId,
        'amount': amount,
        'purpose': normalizedPurpose,
        'imei_number': imeiNumber,
        's_key': AppConstants.defaultMobileApiSKey,
      };
      AppLogger.logApiRequest('POST', ApiEndpoints.applyLoan, request);

      final response = await _httpClient.post<dynamic>(
        ApiEndpoints.applyLoan,
        data: request,
      );
      if (isBackendEmptyPayload(response.data)) {
        throw GenericException(
          message: 'The loan application service returned an empty response.',
        );
      }

      final data = normalizeResponsePayload(response.data);
      AppLogger.logApiResponse('POST', ApiEndpoints.applyLoan, data);
      if (hasExplicitFailure(data)) {
        throw GenericException(
          message:
              data['message']?.toString() ??
              'Unable to submit your loan application.',
        );
      }

      final message = data['message']?.toString().trim() ?? '';
      return {
        'status': 'success',
        if (message.isNotEmpty) 'message': message,
        'data': data,
      };
    });
  }

  /// Repay loan
  Future<Map<String, dynamic>> repayLoan({
    required String loanId,
    required double amount,
    required double currentOutstanding,
    required String accountNumber,
    required String pin,
    String paymentMethod = 'Mobile Money',
    String? momoPhoneNumber,
  }) async {
    return handleApiCall(() async {
      if (amount <= 0) {
        throw ValidationException(message: 'Amount must be greater than zero');
      }
      if (amount > currentOutstanding) {
        throw ValidationException(
          message: 'Amount cannot exceed the outstanding balance.',
        );
      }

      final request = {
        'account_number': int.tryParse(accountNumber) ?? accountNumber,
        'pin': pin,
        'loan_id': loanId,
        'amount': amount,
        if (momoPhoneNumber != null && momoPhoneNumber.isNotEmpty)
          'momo_number': momoPhoneNumber,
      };
      AppLogger.logApiRequest('POST', ApiEndpoints.repayLoanStccu, request);

      final response = await _httpClient.post<dynamic>(
        ApiEndpoints.repayLoanStccu,
        data: request,
        options: BaseService.stccuFormOptions,
      );

      final raw = response.data;
      final data = normalizeResponsePayload(raw);

      AppLogger.logApiResponse('POST', ApiEndpoints.repayLoanStccu, data);

      final status = data['status'];
      if (!AuthSession.isSuccessStatus(status)) {
        throw GenericException(
          message: data['message'] as String? ?? 'Loan repayment failed.',
        );
      }

      final transactionId = data['transaction_id'] ?? data['transactionId'];
      final newOutstandingValue =
          data['new_outstanding'] ?? data['newOutstanding'];
      final processedAtValue = data['processed_at'] ?? data['processedAt'];

      if (transactionId == null ||
          transactionId.toString().trim().isEmpty ||
          newOutstandingValue is! num ||
          processedAtValue == null) {
        throw GenericException(
          message:
              'Loan repayment succeeded but the server returned incomplete transaction details.',
        );
      }

      return {
        'status': 'success',
        'message': data['message'] as String? ?? 'Loan repayment successful',
        'data': {
          'loan_id': loanId,
          'transaction_id': transactionId.toString(),
          'amount': (data['amount'] as num?)?.toDouble() ?? amount,
          'previous_outstanding':
              (data['previous_outstanding'] as num?)?.toDouble() ??
              currentOutstanding,
          'new_outstanding': newOutstandingValue.toDouble(),
          'processed_at': processedAtValue.toString(),
          'payment_method': data['payment_method']?.toString() ?? paymentMethod,
          'phone_number': data['phone_number']?.toString() ?? momoPhoneNumber,
        },
      };
    });
  }
}

/// Savings service
class SavingsService extends BaseService {
  final HttpClient _httpClient = HttpClient.instance;
  final HttpClient _paymentClient = HttpClient.paymentInstance;

  static List<dynamic> _findFirstList(dynamic value) {
    if (value is List) return value;
    if (value is Map) {
      for (final nested in value.values) {
        final result = _findFirstList(nested);
        if (result.isNotEmpty) return result;
      }
    }
    return const [];
  }

  static double? _toDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', ''));
  }

  static bool isShareProduct(Map<String, dynamic> product) {
    final searchableFields = [
      product['type'],
      product['product_type'],
      product['savings_type'],
      product['name'],
      product['product_name'],
      product['pro_name'],
      product['account_name'],
    ].whereType<String>().join(' ');

    return RegExp(
      r'\bshares?\b',
      caseSensitive: false,
    ).hasMatch(searchableFields);
  }

  /// Get list of savings products/accounts via live /getSavingsProducts endpoint
  Future<Map<String, dynamic>> getSavingsList({
    required String phoneNumber,
    required String accountNumber,
    required String pin,
    required int imeiNumber,
  }) async {
    return handleApiCall(() async {
      final request = {
        'account_number': int.tryParse(accountNumber) ?? accountNumber,
        'imei_number': imeiNumber,
        's_key': AppConstants.defaultMobileApiSKey,
      };
      AppLogger.logApiRequest(
        'POST',
        ApiEndpoints.getSavingsProductsList,
        request,
      );

      final response = await _httpClient.post<dynamic>(
        ApiEndpoints.getSavingsProductsList,
        data: request,
      );

      final raw = response.data;
      if (isBackendEmptyPayload(raw)) {
        throw GenericException(
          message:
              'No savings data returned from server. Please verify your credentials and try again.',
        );
      }
      final data = normalizeResponsePayload(raw);

      AppLogger.logApiResponse(
        'POST',
        ApiEndpoints.getSavingsProductsList,
        data,
      );

      if (hasExplicitFailure(data)) {
        throw GenericException(
          message: data['message']?.toString() ?? 'Unable to load savings.',
        );
      }

      final savingsRaw = _findFirstList(data);
      final normalizedSavings = savingsRaw
          .whereType<Map<String, dynamic>>()
          .map((s) {
            String textValue(Iterable<dynamic> values, String fallback) {
              for (final value in values) {
                final text = value?.toString().trim() ?? '';
                if (text.isNotEmpty) return text;
              }
              return fallback;
            }

            return {
              'savings_id': textValue([
                s['id'],
                s['savings_id'],
                s['product_id'],
              ], ''),
              'name': textValue([
                s['name'],
                s['product_name'],
                s['pro_name'],
                s['account_name'],
              ], 'Savings'),
              'balance': _toDoubleOrNull(
                s['balance'] ?? s['current_balance'] ?? s['amount'],
              ),
              'daily_limit': _toDoubleOrNull(
                s['daily_limit'] ?? s['withdrawal_daily_limit'],
              ),
              'monthly_limit': _toDoubleOrNull(
                s['monthly_limit'] ?? s['withdrawal_monthly_limit'],
              ),
              'used_daily_limit': _toDoubleOrNull(s['used_daily_limit']),
              'used_monthly_limit': _toDoubleOrNull(s['used_monthly_limit']),
              'target': _toDoubleOrNull(
                s['target'] ?? s['target_amount'] ?? s['goal_amount'],
              ),
              'interest_rate': _toDoubleOrNull(s['interest_rate'] ?? s['rate']),
              'product_type': textValue([
                s['product_type'],
                s['savings_type'],
              ], ''),
              'type': textValue([
                s['type'],
                s['product_type'],
                s['savings_type'],
              ], 'member'),
            };
          })
          .toList();

      return {'status': 'success', 'data': normalizedSavings};
    });
  }

  Future<Map<String, dynamic>> getFixedDeposits({
    required String accountNumber,
    required int imeiNumber,
  }) async {
    return handleApiCall(() async {
      final request = {
        'account_number': accountNumber,
        'imei_number': imeiNumber,
        's_key': AppConstants.defaultMobileApiSKey,
      };
      AppLogger.logApiRequest('POST', ApiEndpoints.getFixedDeposits, request);

      final response = await _httpClient.post<dynamic>(
        ApiEndpoints.getFixedDeposits,
        data: request,
      );
      final raw = response.data;
      final data = normalizeResponsePayload(raw);

      AppLogger.logApiResponse('POST', ApiEndpoints.getFixedDeposits, data);

      final message = data['message']?.toString().trim().toLowerCase() ?? '';
      if (message == 'no record found' ||
          (raw is String && raw.trim().toLowerCase() == 'no record found')) {
        return {'status': 'success', 'data': <Map<String, dynamic>>[]};
      }
      if (isBackendEmptyPayload(raw)) {
        return {'status': 'success', 'data': <Map<String, dynamic>>[]};
      }
      if (hasExplicitFailure(data)) {
        throw GenericException(
          message:
              data['message']?.toString() ?? 'Unable to load fixed deposits.',
        );
      }

      String textValue(Iterable<dynamic> values, String fallback) {
        for (final value in values) {
          final text = value?.toString().trim() ?? '';
          if (text.isNotEmpty) return text;
        }
        return fallback;
      }

      final fixedDeposits = _findFirstList(data).whereType<Map>().map((record) {
        final entry = Map<String, dynamic>.from(record);
        return {
          ...entry,
          'savings_id': textValue([
            entry['id'],
            entry['fixed_deposit_id'],
            entry['deposit_id'],
            entry['fd_id'],
            entry['account_number'],
          ], ''),
          'name': textValue([
            entry['name'],
            entry['product_name'],
            entry['pro_name'],
            entry['account_name'],
          ], 'Fixed Deposit'),
          'balance':
              entry['balance'] ??
              entry['principal'] ??
              entry['principal_amount'] ??
              entry['deposit_amount'] ??
              entry['amount'] ??
              entry['initial_amount'] ??
              entry['current_balance'],
          'type': 'fixed_deposit',
        };
      }).toList();

      return {'status': 'success', 'data': fixedDeposits};
    });
  }

  Future<Map<String, dynamic>> getSavingsBalance({
    required String productId,
  }) async {
    return handleApiCall(() async {
      final request = {
        'product_id': int.tryParse(productId) ?? productId,
        's_key': AppConstants.defaultMobileApiSKey,
      };
      AppLogger.logApiRequest('POST', ApiEndpoints.getSavingsBalance, request);
      final response = await _httpClient.post<dynamic>(
        ApiEndpoints.getSavingsBalance,
        data: request,
      );
      final data = normalizeResponsePayload(response.data);
      AppLogger.logApiResponse('POST', ApiEndpoints.getSavingsBalance, data);
      if (hasExplicitFailure(data)) {
        throw GenericException(
          message:
              data['message']?.toString() ??
              'Unable to retrieve the savings balance.',
        );
      }
      final balance =
          data['balance'] ??
          data['savings_balance'] ??
          data['current_balance'] ??
          data['available_balance'] ??
          (data['data'] is Map
              ? (data['data'] as Map)['balance'] ??
                    (data['data'] as Map)['savings_balance']
              : null);
      return {'status': 'success', 'balance': _toDoubleOrNull(balance)};
    });
  }

  /// Create savings goal
  Future<Map<String, dynamic>> createSavings({
    required String userId,
    required String name,
    required double targetAmount,
    bool autoSave = false,
  }) async {
    return handleApiCall(() async {
      AppLogger.logApiRequest('POST', ApiEndpoints.createSavings, {
        'user_id': userId,
        'name': name,
        'target_amount': targetAmount,
        'auto_save': autoSave,
      });
      if (name.isEmpty || targetAmount <= 0) {
        throw ValidationException(message: AppConstants.validationErrorMessage);
      }
      throw BackendNotConfiguredException(
        message:
            'Savings goal creation is waiting for the backend endpoint contract.',
      );
    });
  }

  /// Deposit to savings
  Future<Map<String, dynamic>> depositSavings({
    required String phoneNumber,
    required double amount,
    required String savingsId,
    String channel = 'mtn-gh',
    String username = 'Member',
    String email = '',
  }) async {
    return handleApiCall(() async {
      if (amount <= 0) {
        throw ValidationException(message: 'Amount must be greater than zero');
      }

      final reference =
          'ATCCU-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';
      final request = <String, dynamic>{
        'phone_number': phoneNumber,
        'channel': channel,
        'amount': amount,
        'description': 'Edeposit',
        'email': email,
        'username': username,
        'product_id': savingsId,
        's_key': AppConstants.defaultMobileApiSKey,
        'ExternalTransactionId': DateTime.now().millisecondsSinceEpoch
            .toString(),
        'ClientReference': reference,
      };
      request.removeWhere((key, value) => value == null);
      AppLogger.logApiRequest('POST', ApiEndpoints.depositFunds, request);

      final response = await _paymentClient.post<dynamic>(
        ApiEndpoints.depositFunds,
        data: request,
      );

      final raw = response.data;
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300 &&
          isBackendEmptyPayload(raw)) {
        return {
          'status': 'success',
          'is_pending': true,
          'message': 'Deposit initiated',
          'transaction_id': reference,
          'reference': reference,
        };
      }
      final data = normalizeResponsePayload(raw);

      AppLogger.logApiResponse('POST', ApiEndpoints.depositFunds, data);

      final status = data['status'];
      final normalizedStatus = status?.toString().trim().toLowerCase();
      final isPending = const {
        '0',
        'accepted',
        'awaiting_authorization',
        'awaiting_confirmation',
        'created',
        'initiated',
        'pending',
        'processing',
        'queued',
      }.contains(normalizedStatus);
      final isConfirmed =
          AuthSession.isSuccessStatus(status) ||
          AuthSession.isSuccessStatus(data['success']) ||
          AuthSession.isSuccessStatus(data['is_success']) ||
          const {
            'complete',
            'completed',
            'paid',
            'successful',
          }.contains(normalizedStatus);
      final isExplicitFailure =
          status == false ||
          data['success'] == false ||
          data['is_success'] == false ||
          const {
            'cancelled',
            'canceled',
            'declined',
            'denied',
            'error',
            'failed',
            'failure',
            'rejected',
          }.contains(normalizedStatus);

      if (isExplicitFailure) {
        throw GenericException(
          message: data['message'] as String? ?? 'Deposit failed.',
        );
      }

      final providerReference =
          data['transaction_id'] ??
          data['transactionId'] ??
          data['reference'] ??
          data['client_reference'];
      final hasProviderReference =
          providerReference != null &&
          providerReference.toString().trim().isNotEmpty;
      final isAwaitingConfirmation =
          isPending || !isConfirmed || !hasProviderReference;
      final transactionId = hasProviderReference
          ? providerReference.toString()
          : reference;
      final backendMessage = data['message']?.toString().trim();
      final message = isAwaitingConfirmation
          ? [
              if (backendMessage != null && backendMessage.isNotEmpty)
                backendMessage,
              'Do not submit another deposit until you confirm this transaction in your balance or transaction history.',
            ].join(' ')
          : backendMessage?.isNotEmpty == true
          ? backendMessage!
          : 'Deposit successful';

      return {
        'status': isAwaitingConfirmation ? 'pending' : 'success',
        'is_pending': isAwaitingConfirmation,
        'message': message,
        'transaction_id': transactionId,
        'reference': transactionId,
        'new_balance': _toDoubleOrNull(data['new_balance'] ?? data['balance']),
      };
    });
  }

  /// Withdraw from savings
  Future<Map<String, dynamic>> withdrawSavings({
    required String phoneNumber,
    required String accountNumber,
    required String pin,
    required double amount,
    required double currentBalance,
    required int imeiNumber,
    String? savingsId,
    String channel = 'mtn-gh',
    String username = 'Member',
    String email = '',
  }) async {
    return handleApiCall(() async {
      if (amount <= 0) {
        throw ValidationException(message: 'Amount must be greater than zero');
      }
      if (currentBalance < AppConstants.minimumSavingsBalanceAfterWithdrawal ||
          amount >
              currentBalance -
                  AppConstants.minimumSavingsBalanceAfterWithdrawal) {
        throw ValidationException(
          message:
              'Insufficient balance. At least GH₵'
              '${AppConstants.minimumSavingsBalanceAfterWithdrawal.toStringAsFixed(2)} '
              'must remain in your account after withdrawal.',
        );
      }

      final reference =
          'ATCCU-W-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';
      final request = <String, dynamic>{
        'phone_number': phoneNumber,
        'channel': channel,
        'amount': amount,
        'description': 'EWithdrawal',
        'email': email,
        'username': username,
        'product_id': savingsId,
        's_key': AppConstants.defaultMobileApiSKey,
        'imei_number': imeiNumber,
        'pin': int.tryParse(pin) ?? pin,
        'ClientReference': reference,
      };
      request.removeWhere((key, value) => value == null);
      AppLogger.logApiRequest('POST', ApiEndpoints.withdrawFunds, request);

      final response = await _paymentClient.post<dynamic>(
        ApiEndpoints.withdrawFunds,
        data: request,
        options: BaseService.stccuFormOptions,
      );

      final raw = response.data;
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300 &&
          isBackendEmptyPayload(raw)) {
        return {
          'status': 'pending',
          'is_pending': true,
          'message': 'Withdrawal initiated',
          'transaction_id': reference,
          'reference': reference,
        };
      }
      final data = normalizeResponsePayload(raw);

      AppLogger.logApiResponse('POST', ApiEndpoints.withdrawFunds, data);

      final status = data['status'];
      final isPending =
          data['is_pending'] == true ||
          (status is String && status.trim().toLowerCase() == 'pending');
      if (!AuthSession.isSuccessStatus(status) && !isPending) {
        throw GenericException(
          message: data['message'] as String? ?? 'Withdrawal failed.',
        );
      }

      final providerReference =
          data['transaction_id'] ??
          data['transactionId'] ??
          data['reference'] ??
          data['provider_transaction_id'] ??
          data['providerTransactionId'];
      final isConfirmed =
          !isPending &&
          AuthSession.isSuccessStatus(status) &&
          providerReference != null &&
          providerReference.toString().trim().isNotEmpty;
      final transactionId = isConfirmed ? providerReference : reference;

      return {
        'status': isConfirmed ? 'success' : 'pending',
        'is_pending': !isConfirmed,
        'message':
            data['message'] as String? ??
            (isConfirmed
                ? 'Withdrawal successful'
                : 'Withdrawal submitted and awaiting provider confirmation.'),
        'transaction_id': transactionId.toString(),
        'reference': transactionId.toString(),
        'processed_at': data['processed_at'] ?? data['processedAt'],
        'new_balance': _toDoubleOrNull(data['new_balance'] ?? data['balance']),
      };
    });
  }
}

/// Transaction service
class ProductCatalogService extends BaseService {
  final HttpClient _httpClient = HttpClient.instance;

  Future<List<Map<String, dynamic>>> getProducts({
    required String endpoint,
  }) async {
    return handleApiCall(() async {
      AppLogger.logApiRequest('GET', endpoint, const {});
      final response = await _httpClient.get<dynamic>(endpoint);
      final payload = normalizeResponsePayload(response.data);
      AppLogger.logApiResponse('GET', endpoint, payload);
      final raw = payload['products'] ?? payload['data'] ?? payload['items'];
      return raw is List
          ? raw.whereType<Map<String, dynamic>>().toList()
          : <Map<String, dynamic>>[];
    });
  }
}

class PaymentService extends BaseService {
  final HttpClient _httpClient = HttpClient.paymentInstance;

  Future<Map<String, dynamic>> repayLoan({
    required String phoneNumber,
    required String channel,
    required double amount,
    required double currentOutstanding,
    required String username,
    required String productId,
    String email = '',
  }) async {
    return handleApiCall(() async {
      if (amount <= 0) {
        throw ValidationException(message: 'Amount must be greater than zero');
      }
      if (amount > currentOutstanding) {
        throw ValidationException(
          message: 'Amount cannot exceed the outstanding balance.',
        );
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final reference = 'ATCCU-LR-${timestamp.toRadixString(36).toUpperCase()}';
      final request = {
        'phone_number': phoneNumber,
        'channel': channel,
        'amount': amount,
        'description': 'Edeposit',
        'email': email,
        'username': username,
        'product_id': productId,
        's_key': AppConstants.defaultMobileApiSKey,
        'ExternalTransactionId': timestamp.toString(),
        'ClientReference': reference,
      };
      AppLogger.logApiRequest('POST', ApiEndpoints.depositFunds, request);

      final response = await _httpClient.post<dynamic>(
        ApiEndpoints.depositFunds,
        data: request,
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300 &&
          isBackendEmptyPayload(response.data)) {
        return {
          'status': 'success',
          'is_pending': true,
          'message': 'Loan repayment request submitted for confirmation.',
          'transaction_id': reference,
          'reference': reference,
        };
      }

      final data = normalizeResponsePayload(response.data);
      AppLogger.logApiResponse(
        'POST',
        ApiEndpoints.depositFunds,
        data,
        statusCode: response.statusCode,
      );
      if (hasExplicitFailure(data) ||
          !AuthSession.isSuccessStatus(data['status'])) {
        throw GenericException(
          message: data['message']?.toString() ?? 'Loan repayment failed.',
        );
      }

      final transactionId =
          data['transaction_id'] ??
          data['transactionId'] ??
          data['reference'] ??
          reference;
      return {
        ...data,
        'status': 'success',
        'is_pending': false,
        'transaction_id': transactionId.toString(),
        'reference': transactionId.toString(),
      };
    });
  }

  Future<Map<String, dynamic>> transferToSelf({
    required String accountNumber,
    required int imeiNumber,
  }) async {
    return handleApiCall(() async {
      final request = {
        'account_number': int.tryParse(accountNumber) ?? accountNumber,
        'imei_number': imeiNumber,
        's_key': AppConstants.defaultMobileApiSKey,
      };
      AppLogger.logApiRequest('POST', ApiEndpoints.transferToSelf, request);
      final response = await _httpClient.post<dynamic>(
        ApiEndpoints.transferToSelf,
        data: request,
      );
      final data = normalizeResponsePayload(response.data);
      AppLogger.logApiResponse('POST', ApiEndpoints.transferToSelf, data);
      if (!AuthSession.isSuccessStatus(data['status'])) {
        throw GenericException(
          message: data['message'] as String? ?? 'Transfer failed.',
        );
      }
      return data;
    });
  }

  Future<Map<String, dynamic>> buyAirtime({
    required String phoneNumber,
    required String channel,
    required double amount,
    required String username,
    required String productId,
    required String pin,
    String email = '',
  }) async {
    return _submitMobilePurchase(
      description: 'Edeposit',
      phoneNumber: phoneNumber,
      channel: channel,
      amount: amount,
      username: username,
      productId: productId,
      pin: pin,
      email: email,
      failureMessage: 'Airtime purchase failed.',
      emptyResponseMessage:
          'The airtime service returned no confirmation. Check your transaction history or contact support before trying again.',
    );
  }

  Future<Map<String, dynamic>> buyDataBundle({
    required String phoneNumber,
    required String channel,
    required double amount,
    required String username,
    required String productId,
    required String pin,
    String email = '',
  }) async {
    return _submitMobilePurchase(
      description: 'Edeposit',
      phoneNumber: phoneNumber,
      channel: channel,
      amount: amount,
      username: username,
      productId: productId,
      pin: pin,
      email: email,
      failureMessage: 'Data bundle purchase failed.',
      emptyResponseMessage:
          'The data bundle service returned no confirmation. Check your transaction history or contact support before trying again.',
    );
  }

  Future<Map<String, dynamic>> _submitMobilePurchase({
    required String description,
    required String phoneNumber,
    required String channel,
    required double amount,
    required String username,
    required String productId,
    required String pin,
    required String email,
    required String failureMessage,
    required String emptyResponseMessage,
  }) async {
    return handleApiCall(() async {
      if (amount <= 0) {
        throw ValidationException(message: 'Amount must be greater than zero');
      }
      if (pin.trim().isEmpty) {
        throw ValidationException(
          message: 'A saved PIN is required to authorize this purchase.',
        );
      }

      final request = {
        'phone_number': phoneNumber,
        'channel': channel,
        'amount': amount,
        'description': description,
        'email': email,
        'username': username,
        'product_id': productId,
        'pin': int.tryParse(pin) ?? pin,
        's_key': AppConstants.defaultMobileApiSKey,
      };
      final endpoint = ApiEndpoints.buyAirtime;
      AppLogger.logApiRequest('POST', endpoint, request);

      final response = await _httpClient.post<dynamic>(endpoint, data: request);
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300 &&
          isBackendEmptyPayload(response.data)) {
        return {
          'status': 'success',
          'is_pending': true,
          'message': emptyResponseMessage,
        };
      }
      final data = normalizeResponsePayload(response.data);
      AppLogger.logApiResponse('POST', endpoint, data);

      final status = data['status'];
      final normalizedStatus = status?.toString().trim().toLowerCase();
      final responseCode = data['ResponseCode']?.toString().trim();
      final responseMessage =
          data['message']?.toString() ??
          data['Message']?.toString() ??
          data['error']?.toString() ??
          '';
      final indicatesInsufficientBalance = RegExp(
        r'insufficient\s+(?:(?:account|available)\s+)?(?:funds?|balance)|'
        r'(?:not enough|too low).{0,40}(?:funds?|balance)|'
        r'(?:funds?|balance).{0,40}(?:not enough|too low)',
        caseSensitive: false,
      ).hasMatch(responseMessage);
      final isExplicitFailure =
          status == false ||
          normalizedStatus == '0' ||
          data['success'] == false ||
          data['is_success'] == false ||
          indicatesInsufficientBalance ||
          const {
            'cancelled',
            'canceled',
            'declined',
            'denied',
            'error',
            'failed',
            'failure',
            'rejected',
          }.contains(normalizedStatus);
      if (isExplicitFailure) {
        throw GenericException(
          message: responseMessage.isNotEmpty
              ? responseMessage
              : failureMessage,
        );
      }

      final isAcceptedPending = const {
        'accepted',
        'awaiting_authorization',
        'awaiting_confirmation',
        'created',
        'initiated',
        'in_progress',
        'pending',
        'processing',
        'queued',
        'request_received',
      }.contains(normalizedStatus);
      final isProviderPending = responseCode == '0001';
      final isConfirmed =
          AuthSession.isSuccessStatus(status) ||
          AuthSession.isSuccessStatus(data['success']) ||
          AuthSession.isSuccessStatus(data['is_success']) ||
          const {
            'complete',
            'completed',
            'paid',
            'successful',
          }.contains(normalizedStatus);
      final isPending =
          data['is_pending'] == true ||
          isProviderPending ||
          isAcceptedPending ||
          !isConfirmed;
      final providerData = data['Data'] is Map
          ? Map<String, dynamic>.from(data['Data'] as Map)
          : const <String, dynamic>{};
      final transactionId =
          providerData['TransactionId'] ??
          data['transaction_id'] ??
          data['transactionId'];
      final reference =
          providerData['ClientReference'] ?? data['reference'] ?? transactionId;

      return {
        ...data,
        'status': isPending ? 'pending' : 'success',
        'is_pending': isPending,
        'message':
            data['message']?.toString() ??
            data['Message']?.toString() ??
            (isPending
                ? 'The request was accepted and is awaiting provider confirmation.'
                : 'The provider reported that the purchase completed.'),
        if (transactionId != null) 'transaction_id': transactionId.toString(),
        if (reference != null) 'reference': reference.toString(),
      };
    });
  }

  Future<Map<String, dynamic>> chargePayment({
    required String accountNumber,
    required String phoneNumber,
    required double amount,
    required String paymentMethod,
    String? momoPhoneNumber,
  }) async {
    return handleApiCall(() async {
      if (amount <= 0) {
        throw ValidationException(message: 'Amount must be greater than zero');
      }
      throw BackendNotConfiguredException(
        message:
            'This payment method is not available because the documented API '
            'does not provide a matching payment endpoint.',
      );
    });
  }
}

abstract class _PortfolioService extends BaseService {
  final HttpClient httpClient = HttpClient.instance;

  Future<Map<String, dynamic>> fetchPortfolio({
    required String endpoint,
    required String collectionKey,
    required String phoneNumber,
    required String accountNumber,
    required String pin,
    required int imeiNumber,
  }) async {
    return handleApiCall(() async {
      final request = {
        'account_number': accountNumber,
        'imei_number': imeiNumber,
        's_key': AppConstants.defaultMobileApiSKey,
      };
      AppLogger.logApiRequest('POST', endpoint, request);
      final response = await httpClient.post<dynamic>(endpoint, data: request);
      final raw = response.data;
      if (isBackendEmptyPayload(raw)) {
        return {'status': 'success', 'data': <Map<String, dynamic>>[]};
      }
      final payload = normalizeResponsePayload(raw);
      AppLogger.logApiResponse('POST', endpoint, payload);
      final status = payload['status'];
      final hasExplicitFailure =
          status != null &&
          !AuthSession.isSuccessStatus(status) &&
          !(status is String && status.trim().isEmpty);
      if (hasExplicitFailure) {
        throw GenericException(
          message:
              payload['message']?.toString() ?? 'Unable to load portfolio.',
        );
      }
      final items =
          payload[collectionKey] ??
          payload['products'] ??
          payload['data'] ??
          payload['items'] ??
          payload['results'];
      final list = items is List
          ? items
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : <Map<String, dynamic>>[];
      return {'status': 'success', 'data': list};
    });
  }
}

class SharesService extends _PortfolioService {
  Future<Map<String, dynamic>> getShares({
    required String phoneNumber,
    required String accountNumber,
    required String pin,
    required int imeiNumber,
  }) {
    return fetchPortfolio(
      endpoint: ApiEndpoints.getShares,
      collectionKey: 'shares',
      phoneNumber: phoneNumber,
      accountNumber: accountNumber,
      pin: pin,
      imeiNumber: imeiNumber,
    );
  }
}

class InvestmentService extends _PortfolioService {
  Future<Map<String, dynamic>> getInvestments({
    required String phoneNumber,
    required String accountNumber,
    required String pin,
  }) {
    throw GenericException(
      message:
          'The documented ATCCU API does not provide an investments endpoint.',
    );
  }
}

/// Transaction service
class TransactionService extends BaseService {
  final HttpClient _httpClient = HttpClient.instance;

  static double? _toDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', ''));
  }

  Future<List<Map<String, dynamic>>> getProductStatement({
    required String productId,
  }) async {
    return handleApiCall(() async {
      final normalizedProductId = productId.trim();
      if (normalizedProductId.isEmpty) {
        throw ValidationException(message: 'A product ID is required.');
      }

      final request = {
        'product_id': int.tryParse(normalizedProductId) ?? normalizedProductId,
        's_key': AppConstants.defaultMobileApiSKey,
      };
      AppLogger.logApiRequest('POST', ApiEndpoints.savingsStatement, request);

      final response = await _httpClient.post<dynamic>(
        ApiEndpoints.savingsStatement,
        data: request,
      );
      if (isBackendEmptyPayload(response.data)) {
        throw GenericException(
          message: 'The statement service returned an empty response.',
        );
      }

      final data = normalizeResponsePayload(response.data);
      AppLogger.logApiResponse('POST', ApiEndpoints.savingsStatement, data);
      if (hasExplicitFailure(data)) {
        throw GenericException(
          message: data['message']?.toString() ?? 'Unable to load statement.',
        );
      }

      final nestedData = data['data'];
      final transactions =
          <dynamic>[
                data['transactions'],
                data['statement'],
                if (nestedData is Map) nestedData['transactions'],
                if (nestedData is Map) nestedData['statement'],
                nestedData,
              ].firstWhere(
                (value) => value is List,
                orElse: () => const <dynamic>[],
              )
              as List;

      return transactions.whereType<Map>().map((rawTransaction) {
        final transaction = Map<String, dynamic>.from(rawTransaction);
        return {
          ...transaction,
          'transaction_id':
              (transaction['trans_id'] ??
                      transaction['transaction_id'] ??
                      transaction['id'])
                  ?.toString() ??
              '',
          'description':
              (transaction['description'] ?? transaction['narration'])
                  ?.toString() ??
              '',
          'amount': _toDoubleOrNull(transaction['amount']),
          'type':
              (transaction['trans_type'] ?? transaction['type'])?.toString() ??
              'unknown',
          'date':
              (transaction['entry_date'] ??
                      transaction['transaction_date'] ??
                      transaction['date'])
                  ?.toString() ??
              '',
        };
      }).toList();
    });
  }

  /// Get transactions for user via live /miniStatement endpoint
  Future<Map<String, dynamic>> getTransactions({
    required String phoneNumber,
    required String accountNumber,
    required String pin,
    int page = 1,
    int limit = 20,
  }) async {
    return handleApiCall(() async {
      final request = <String, dynamic>{
        'phone_number': phoneNumber,
        'account_number': int.tryParse(accountNumber) ?? accountNumber,
        'page': page,
        'limit': limit,
        's_key': AppConstants.defaultMobileApiSKey,
      };
      if (pin.trim().isNotEmpty) {
        request['pin'] = pin.trim();
      }
      AppLogger.logApiRequest('POST', ApiEndpoints.miniStatement, request);

      final response = await _httpClient.post<dynamic>(
        ApiEndpoints.miniStatement,
        data: request,
      );

      final raw = response.data;
      if (isBackendEmptyPayload(raw)) {
        return {
          'status': 'success',
          'data': <Map<String, dynamic>>[],
          'pagination': {
            'current_page': page,
            'total_pages': 1,
            'total_items': 0,
          },
        };
      }
      final data = normalizeResponsePayload(raw);

      AppLogger.logApiResponse('POST', ApiEndpoints.miniStatement, data);

      if (hasExplicitFailure(data)) {
        throw GenericException(
          message:
              data['message']?.toString() ?? 'Unable to load transactions.',
        );
      }

      // Normalise STCCU statement response
      final statementsRaw =
          <dynamic>[
                data['statement'],
                data['transactions'],
                data['products'],
                data['data'],
              ].firstWhere(
                (value) => value is List,
                orElse: () => const <dynamic>[],
              )
              as List;
      final normalizedTransactions = statementsRaw.whereType<Map>().map((
        rawTxn,
      ) {
        final txn = Map<String, dynamic>.from(rawTxn);
        final credit = _toDoubleOrNull(txn['credit']) ?? 0;
        final debit = _toDoubleOrNull(txn['debit']) ?? 0;
        final rawType = txn['type']?.toString().trim().toLowerCase();
        final type = credit > 0
            ? 'credit'
            : debit > 0
            ? 'debit'
            : rawType ?? 'unknown';
        final rawDate =
            txn['date'] ?? txn['transaction_date'] ?? txn['created_at'];

        return {
          'transaction_id':
              (txn['id'] ??
                      txn['transaction_id'] ??
                      txn['trans_id'] ??
                      txn['reference'] ??
                      txn['external_transaction_id'] ??
                      txn['client_reference'])
                  ?.toString()
                  .trim() ??
              '',
          'type': type,
          'amount': credit > 0
              ? credit
              : debit > 0
              ? debit
              : _toDoubleOrNull(txn['amount']),
          'description':
              (txn['narration'] ?? txn['description'] ?? txn['details'])
                  ?.toString()
                  .trim() ??
              '',
          'date': rawDate?.toString(),
          'status':
              (txn['status'] ??
                      txn['state'] ??
                      txn['transaction_status'] ??
                      txn['payment_status'] ??
                      'unknown')
                  .toString()
                  .trim()
                  .toLowerCase(),
          'balance': _toDoubleOrNull(txn['balance'] ?? txn['running_balance']),
        };
      }).toList();

      return {
        'status': 'success',
        'data': normalizedTransactions,
        'pagination': {
          'current_page': page,
          'total_pages': data['total_pages'] as int? ?? 1,
          'total_items':
              data['total_items'] as int? ?? normalizedTransactions.length,
        },
      };
    });
  }
}
