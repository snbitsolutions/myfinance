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
      if (response.containsKey('status')) 'status': response['status'],
      if (response.containsKey('message')) 'message': response['message'],
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

  Future<void> confirmPhoneNumber({required String phoneNumber}) async {
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
    });
  }

  Future<void> confirmAccountNumber({
    required String phoneNumber,
    required String accountNumber,
  }) async {
    return handleApiCall(() async {
      final request = {
        'phone_number': phoneNumber,
        'account_number': accountNumber,
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

      if (data.isNotEmpty) {
        final status = data['status'];
        final isExplicitFailure =
            status != null &&
            status != 1 &&
            status != '1' &&
            !(status is String && status.toLowerCase() == 'success');

        if (isExplicitFailure) {
          throw AuthException(
            message:
                data['message'] as String? ?? 'Account verification failed.',
          );
        }
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
    return <String, int>{
      // The backend expects numeric values for both identifiers, not strings.
      'phone_number': int.parse(_toInternationalPhoneNumber(phoneNumber)),
      'member_id': _memberIdFromAccountNumber(accountNumber),
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
      final request = <String, dynamic>{
        'member_id': _memberIdFromAccountNumber(accountNumber),
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
      return result;
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

  String _toInternationalPhoneNumber(String phoneNumber) {
    final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('233')) return digits;
    if (digits.startsWith('0') && digits.length == 10) {
      return '233${digits.substring(1)}';
    }
    throw ValidationException(message: 'Enter a valid Ghana phone number.');
  }

  /// Register a new member via /register
  Future<Map<String, dynamic>> register({
    String? phoneNumber,
    required String accountNumber,
    required String pin,
  }) async {
    return handleApiCall(() async {
      final request = <String, dynamic>{
        'acc_number': int.tryParse(accountNumber) ?? accountNumber,
        'phone_number': int.tryParse(phoneNumber ?? '') ?? phoneNumber ?? '',
        'pin': int.tryParse(pin) ?? pin,
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

  /// Login with email and password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    Map<String, dynamic>? deviceContext,
  }) async {
    return handleApiCall(() async {
      AppLogger.logApiRequest('POST', ApiEndpoints.login, {
        'email': email,
        'device_context': deviceContext,
      });
      throw ValidationException(
        message:
            'Email/password login is not supported by the STCCU API. Use phone/account/PIN sign in.',
      );
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
        'imei_number': 100200300,
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
  final HttpClient _httpClient = HttpClient.instance;

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '')) ?? 0;
  }

  /// Get user profile via live /getAccountBalance endpoint
  Future<Map<String, dynamic>> getUserProfile({
    required String phoneNumber,
    required String accountNumber,
    required String pin,
  }) async {
    return handleApiCall(() async {
      final request = {
        'phone_number': phoneNumber,
        'account_number': accountNumber,
        'pin': pin,
      };
      AppLogger.logApiRequest('POST', ApiEndpoints.getAccountBalance, request);

      final response = await _httpClient.post<dynamic>(
        ApiEndpoints.getAccountBalance,
        data: request,
        options: BaseService.stccuFormOptions,
      );

      final raw = response.data;
      if (raw is String && (raw.trim().isEmpty || raw.trim() == '""')) {
        throw AuthException(
          message:
              'No account data returned. Please confirm your account number and PIN.',
        );
      }
      final data = normalizeResponsePayload(raw);

      AppLogger.logApiResponse('POST', ApiEndpoints.getAccountBalance, data);

      final status = data['status'];
      if (!AuthSession.isSuccessStatus(status)) {
        throw AuthException(
          message:
              data['message'] as String? ?? 'Failed to load account details',
        );
      }

      // Normalise multiple possible field name patterns from STCCU API
      final name =
          data['account_name'] as String? ??
          data['name'] as String? ??
          data['full_name'] as String? ??
          'Account Holder';
      final balance = _toDouble(
        data['available_balance'] ??
            data['balance'] ??
            data['account_balance'] ??
            0,
      );
      final branch =
          data['branch'] as String? ?? data['branch_name'] as String? ?? '';

      return {
        'data': {
          'user_id': accountNumber,
          'name': name,
          'account_number': accountNumber,
          'balance': balance,
          'branch': branch,
          'phone': phoneNumber,
          'status': 'Active',
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

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '')) ?? 0;
  }

  /// Get list of loans for user via live /getLoans endpoint
  Future<Map<String, dynamic>> getLoansList({
    required String phoneNumber,
    required String accountNumber,
    required String pin,
  }) async {
    return handleApiCall(() async {
      final request = {
        'phone_number': phoneNumber,
        'account_number': accountNumber,
        'pin': pin,
      };
      AppLogger.logApiRequest('POST', ApiEndpoints.getLoans, request);

      final response = await _httpClient.post<dynamic>(
        ApiEndpoints.getLoans,
        data: request,
        options: BaseService.stccuFormOptions,
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

      final status = data['status'];
      if (!AuthSession.isSuccessStatus(status)) {
        return {'status': 'success', 'data': []};
      }

      // Normalise STCCU loans response
      final loansRaw = data['loans'] as List? ?? [];
      final normalizedLoans = loansRaw
          .whereType<Map<String, dynamic>>()
          .map(
            (loan) => {
              'loan_id':
                  loan['id'] as String? ?? loan['loan_id'] as String? ?? '',
              'amount': _toDouble(
                loan['original_amount'] ?? loan['amount'] ?? 0,
              ),
              'outstanding': _toDouble(
                loan['outstanding_balance'] ?? loan['balance'] ?? 0,
              ),
              'status': (loan['status'] as String? ?? 'active').toLowerCase(),
              'interest_rate': _toDouble(loan['interest_rate'] ?? 0),
              'due_date': loan['due_date'] as String? ?? '',
              'created_at': loan['created_date'] as String? ?? '',
            },
          )
          .toList();

      return {'status': 'success', 'data': normalizedLoans};
    });
  }

  /// Get loan detail
  Future<Map<String, dynamic>> getLoanDetail({required String loanId}) async {
    return handleApiCall(() async {
      AppLogger.logApiRequest('GET', ApiEndpoints.getLoanDetail, {
        'loan_id': loanId,
      });
      throw ValidationException(
        message:
            'Loan detail endpoint is not available in STCCU API. Use getLoans list response.',
      );
    });
  }

  /// Apply for a loan
  Future<Map<String, dynamic>> applyLoan({
    required String userId,
    required double amount,
    required String purpose,
    required String repaymentPlan,
  }) async {
    return handleApiCall(() async {
      AppLogger.logApiRequest('POST', ApiEndpoints.applyLoan, {
        'user_id': userId,
        'amount': amount,
        'purpose': purpose,
        'repayment_plan': repaymentPlan,
      });
      if (amount < AppConstants.loanMinAmount ||
          amount > AppConstants.loanMaxAmount) {
        throw ValidationException(
          message:
              'Loan amount must be between ${AppConstants.loanMinAmount} and ${AppConstants.loanMaxAmount}',
        );
      }
      throw ValidationException(
        message: 'Loan application endpoint is not available in STCCU API.',
      );
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
        'account_number': accountNumber,
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

      final now = DateTime.now();
      final newOutstanding = (currentOutstanding - amount).clamp(
        0,
        currentOutstanding,
      );

      return {
        'status': 'success',
        'message': data['message'] as String? ?? 'Loan repayment successful',
        'data': {
          'loan_id': loanId,
          'transaction_id':
              data['transaction_id'] as String? ??
              'TXN_${now.millisecondsSinceEpoch}',
          'amount': amount,
          'previous_outstanding': currentOutstanding,
          'new_outstanding': newOutstanding,
          'processed_at': now.toIso8601String(),
          'payment_method': paymentMethod,
          'phone_number': momoPhoneNumber,
        },
      };
    });
  }
}

/// Savings service
class SavingsService extends BaseService {
  final HttpClient _httpClient = HttpClient.instance;

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '')) ?? 0;
  }

  /// Get list of savings products/accounts via live /getSavingsProducts endpoint
  Future<Map<String, dynamic>> getSavingsList({
    required String phoneNumber,
    required String accountNumber,
    required String pin,
  }) async {
    return handleApiCall(() async {
      final request = {
        'phone_number': phoneNumber,
        'account_number': accountNumber,
        'pin': pin,
      };
      AppLogger.logApiRequest(
        'POST',
        ApiEndpoints.getSavingsProductsList,
        request,
      );

      final response = await _httpClient.post<dynamic>(
        ApiEndpoints.getSavingsProductsList,
        data: request,
        options: BaseService.stccuFormOptions,
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

      final status = data['status'];
      if (!AuthSession.isSuccessStatus(status)) {
        return {'status': 'success', 'data': []};
      }

      final savingsRaw =
          data['savings'] as List? ??
          data['data'] as List? ??
          data['products'] as List? ??
          [];

      final normalizedSavings = savingsRaw
          .whereType<Map<String, dynamic>>()
          .map(
            (s) => {
              'savings_id':
                  s['id'] as String? ??
                  s['savings_id'] as String? ??
                  s['product_id'] as String? ??
                  '',
              'name':
                  s['name'] as String? ??
                  s['product_name'] as String? ??
                  s['account_name'] as String? ??
                  'Savings',
              'balance': _toDouble(
                s['balance'] ?? s['current_balance'] ?? s['amount'] ?? 0,
              ),
              'target': _toDouble(
                s['target'] ?? s['target_amount'] ?? s['goal_amount'] ?? 0,
              ),
              'interest_rate': _toDouble(s['interest_rate'] ?? s['rate'] ?? 0),
              'type':
                  s['type'] as String? ??
                  s['product_type'] as String? ??
                  s['savings_type'] as String? ??
                  'member',
            },
          )
          .toList();

      return {'status': 'success', 'data': normalizedSavings};
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
      throw ValidationException(
        message:
            'Savings goal creation endpoint is not available in STCCU API.',
      );
    });
  }

  /// Deposit to savings
  Future<Map<String, dynamic>> depositSavings({
    required String phoneNumber,
    required String accountNumber,
    required String pin,
    required double amount,
    String? savingsId,
  }) async {
    return handleApiCall(() async {
      if (amount <= 0) {
        throw ValidationException(message: 'Amount must be greater than zero');
      }

      final request = <String, dynamic>{
        'phone_number': phoneNumber,
        'account_number': accountNumber,
        'pin': pin,
        'amount': amount,
        'savings_id': savingsId,
      };
      request.removeWhere((key, value) => value == null);
      AppLogger.logApiRequest('POST', ApiEndpoints.depositFunds, request);

      final response = await _httpClient.post<dynamic>(
        ApiEndpoints.depositFunds,
        data: request,
        options: BaseService.stccuFormOptions,
      );

      final raw = response.data;
      final data = normalizeResponsePayload(raw);

      AppLogger.logApiResponse('POST', ApiEndpoints.depositFunds, data);

      final status = data['status'];
      if (!AuthSession.isSuccessStatus(status)) {
        throw GenericException(
          message: data['message'] as String? ?? 'Deposit failed.',
        );
      }

      return {
        'status': 'success',
        'message': data['message'] as String? ?? 'Deposit successful',
        'transaction_id':
            data['transaction_id'] as String? ??
            'TXN_${DateTime.now().millisecondsSinceEpoch}',
        'new_balance': _toDouble(data['new_balance'] ?? data['balance'] ?? 0),
      };
    });
  }

  /// Withdraw from savings
  Future<Map<String, dynamic>> withdrawSavings({
    required String phoneNumber,
    required String accountNumber,
    required String pin,
    required double amount,
    String? savingsId,
  }) async {
    return handleApiCall(() async {
      if (amount <= 0) {
        throw ValidationException(message: 'Amount must be greater than zero');
      }

      final request = <String, dynamic>{
        'phone_number': phoneNumber,
        'account_number': accountNumber,
        'pin': pin,
        'amount': amount,
        'savings_id': savingsId,
      };
      request.removeWhere((key, value) => value == null);
      AppLogger.logApiRequest('POST', ApiEndpoints.withdrawFunds, request);

      final response = await _httpClient.post<dynamic>(
        ApiEndpoints.withdrawFunds,
        data: request,
        options: BaseService.stccuFormOptions,
      );

      final raw = response.data;
      final data = normalizeResponsePayload(raw);

      AppLogger.logApiResponse('POST', ApiEndpoints.withdrawFunds, data);

      final status = data['status'];
      if (!AuthSession.isSuccessStatus(status)) {
        throw GenericException(
          message: data['message'] as String? ?? 'Withdrawal failed.',
        );
      }

      return {
        'status': 'success',
        'message': data['message'] as String? ?? 'Withdrawal successful',
        'transaction_id':
            data['transaction_id'] as String? ??
            'TXN_${DateTime.now().millisecondsSinceEpoch}',
        'new_balance': _toDouble(data['new_balance'] ?? data['balance'] ?? 0),
      };
    });
  }
}

/// Transaction service
class PaymentService extends BaseService {
  final HttpClient _httpClient = HttpClient.instance;

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

      if (AppConstants.enableOfflineMode) {
        final transactionId = 'TXN_OFFLINE_${DateTime.now().millisecondsSinceEpoch}';
        return {
          'status': 'success',
          'message': 'Payment successful',
          'transaction_id': transactionId,
          'new_balance': amount + 250,
        };
      }

      final request = <String, dynamic>{
        'phone_number': phoneNumber,
        'account_number': accountNumber,
        'amount': amount,
        'payment_method': paymentMethod,
        if (momoPhoneNumber != null && momoPhoneNumber.isNotEmpty)
          'momo_number': momoPhoneNumber,
      };
      request.removeWhere((key, value) => value == null);

      AppLogger.logApiRequest('POST', ApiEndpoints.initiatePayment, request);

      final response = await _httpClient.post<dynamic>(
        ApiEndpoints.initiatePayment,
        data: request,
      );

      final raw = response.data;
      final data = normalizeResponsePayload(raw);

      AppLogger.logApiResponse('POST', ApiEndpoints.initiatePayment, data);

      final status = data['status'];
      if (!AuthSession.isSuccessStatus(status)) {
        throw GenericException(
          message: data['message'] as String? ?? 'Payment failed.',
        );
      }

      return {
        'status': 'success',
        'message': data['message'] as String? ?? 'Payment successful',
        'transaction_id':
            data['transaction_id'] as String? ??
            'TXN_${DateTime.now().millisecondsSinceEpoch}',
        'new_balance': data['new_balance'] ?? data['balance'] ?? 0,
      };
    });
  }
}

/// Transaction service
class TransactionService extends BaseService {
  final HttpClient _httpClient = HttpClient.instance;

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '')) ?? 0;
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
      final request = {
        'phone_number': phoneNumber,
        'account_number': accountNumber,
        'pin': pin,
        'page': page,
        'limit': limit,
      };
      AppLogger.logApiRequest('POST', ApiEndpoints.miniStatement, request);

      final response = await _httpClient.post<dynamic>(
        ApiEndpoints.miniStatement,
        data: request,
        options: BaseService.stccuFormOptions,
      );

      final raw = response.data;
      if (isBackendEmptyPayload(raw)) {
        throw GenericException(
          message:
              'No transaction data returned from server. Please verify your credentials and try again.',
        );
      }
      final data = normalizeResponsePayload(raw);

      AppLogger.logApiResponse('POST', ApiEndpoints.miniStatement, data);

      final status = data['status'];
      if (!AuthSession.isSuccessStatus(status)) {
        return {
          'status': 'success',
          'data': [],
          'pagination': {
            'current_page': page,
            'total_pages': 1,
            'total_items': 0,
          },
        };
      }

      // Normalise STCCU statement response
      final statementsRaw =
          data['statement'] as List? ?? data['transactions'] as List? ?? [];
      final normalizedTransactions = statementsRaw
          .whereType<Map<String, dynamic>>()
          .map(
            (txn) => {
              'transaction_id':
                  txn['id'] as String? ??
                  txn['transaction_id'] as String? ??
                  '',
              'type': (txn['type'] as String? ?? 'debit').toLowerCase(),
              'amount': _toDouble(
                txn['debit'] ?? txn['credit'] ?? txn['amount'] ?? 0,
              ),
              'description':
                  txn['narration'] as String? ??
                  txn['description'] as String? ??
                  '',
              'date':
                  txn['date'] as String? ?? DateTime.now().toIso8601String(),
              'status': 'success',
              'balance': _toDouble(txn['balance'] ?? 0),
            },
          )
          .toList();

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
