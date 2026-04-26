import '../constants/app_constants.dart';
import '../exceptions/app_exceptions.dart';
import '../utils/logger.dart';

/// Abstract service for all API calls with error handling
abstract class BaseService {
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

  /// Simulate network delay (for mock data)
  Future<void> _simulateNetworkDelay({
    Duration delay = const Duration(milliseconds: 500),
  }) {
    return Future.delayed(delay);
  }
}

/// User authentication service
class AuthService extends BaseService {
  /// Login with email and password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    Map<String, dynamic>? deviceContext,
  }) async {
    return handleApiCall(() async {
      AppLogger.logApiRequest('POST', ApiEndpoints.login, {
        'email': email,
        'device_context': ?deviceContext,
      });
      await _simulateNetworkDelay();

      // Mock validation
      if (email.isEmpty || password.isEmpty) {
        throw ValidationException(message: AppConstants.validationErrorMessage);
      }

      if (!email.contains('@')) {
        throw ValidationException(message: 'Invalid email format');
      }

      // Mock response - simulate successful login
      final response = {
        'status': 'success',
        'data': {
          'user_id': 'USR_12345',
          'email': email,
          'auth_token':
              'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
          'refresh_token':
              'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
          'token_expires_in': 3600, // 1 hour
        },
      };

      AppLogger.logApiResponse('POST', ApiEndpoints.login, response);
      return response;
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
        'device_context': ?deviceContext,
      });
      await _simulateNetworkDelay();

      if (email.isEmpty) {
        throw ValidationException(message: AppConstants.validationErrorMessage);
      }

      final response = {
        'status': 'success',
        'message': 'OTP sent to your email',
        'otp_id': 'OTP_${DateTime.now().millisecondsSinceEpoch}',
        'expires_in': 300, // 5 minutes
      };

      AppLogger.logApiResponse('POST', ApiEndpoints.sendOtp, response);
      return response;
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
        'device_context': ?deviceContext,
      });
      await _simulateNetworkDelay();

      if (otp.isEmpty || otp.length != AppConstants.otpLength) {
        throw ValidationException(message: AppConstants.invalidOtpMessage);
      }

      // Mock: any 4-digit code is valid
      final response = {
        'status': 'success',
        'message': 'OTP verified successfully',
        'verification_token': 'VER_${DateTime.now().millisecondsSinceEpoch}',
      };

      AppLogger.logApiResponse('POST', ApiEndpoints.verifyOtp, response);
      return response;
    });
  }

  /// Set PIN
  Future<Map<String, dynamic>> setPin({
    required String userId,
    required String pin,
    Map<String, dynamic>? deviceContext,
  }) async {
    return handleApiCall(() async {
      AppLogger.logApiRequest('POST', ApiEndpoints.setPin, {
        'user_id': userId,
        'device_context': ?deviceContext,
      });
      await _simulateNetworkDelay();

      if (pin.isEmpty || pin.length != AppConstants.pinLength) {
        throw ValidationException(
          message: 'PIN must be ${AppConstants.pinLength} digits',
        );
      }

      final response = {'status': 'success', 'message': 'PIN set successfully'};

      AppLogger.logApiResponse('POST', ApiEndpoints.setPin, response);
      return response;
    });
  }

  /// Logout
  Future<Map<String, dynamic>> logout({required String userId}) async {
    return handleApiCall(() async {
      AppLogger.logApiRequest('POST', ApiEndpoints.logout, {'user_id': userId});
      await _simulateNetworkDelay();

      final response = {
        'status': 'success',
        'message': 'Logged out successfully',
      };

      AppLogger.logApiResponse('POST', ApiEndpoints.logout, response);
      return response;
    });
  }
}

/// User profile service
class UserService extends BaseService {
  /// Get user profile
  Future<Map<String, dynamic>> getUserProfile({required String userId}) async {
    return handleApiCall(() async {
      AppLogger.logApiRequest(
        'GET',
        '${ApiEndpoints.getUserProfile}/$userId',
        null,
      );
      await _simulateNetworkDelay();

      final response = {
        'status': 'success',
        'data': {
          'user_id': userId,
          'name': 'Steven Boadu',
          'branch': 'Accra Main',
          'account_number': '0123456789',
          'email': 'steven@email.com',
          'phone': '0241234567',
          'balance': 4500.50,
          'kyc_status': 'not_started',
          'created_at': DateTime.now()
              .subtract(const Duration(days: 30))
              .toIso8601String(),
        },
      };

      AppLogger.logApiResponse('GET', ApiEndpoints.getUserProfile, response);
      return response;
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
      await _simulateNetworkDelay();

      final response = {
        'status': 'success',
        'message': 'Profile updated successfully',
        'data': data,
      };

      AppLogger.logApiResponse('PUT', ApiEndpoints.updateUserProfile, response);
      return response;
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
      await _simulateNetworkDelay();

      final response = {
        'status': 'success',
        'message': 'KYC submitted for review',
        'kyc_id': 'KYC_${DateTime.now().millisecondsSinceEpoch}',
        'kyc_status': 'pending', // renamed to avoid duplicate map key
      };

      AppLogger.logApiResponse('POST', ApiEndpoints.submitKyc, response);
      return response;
    });
  }
}

/// Loan service
class LoanService extends BaseService {
  /// Get list of loans for user
  Future<Map<String, dynamic>> getLoansList({required String userId}) async {
    return handleApiCall(() async {
      AppLogger.logApiRequest('GET', ApiEndpoints.getLoansList, {
        'user_id': userId,
      });
      await _simulateNetworkDelay();

      final response = {
        'status': 'success',
        'data': [
          {
            'loan_id': 'LOAN_001',
            'amount': 1000.0,
            'outstanding': 800.0,
            'status': 'active',
            'interest_rate': 5.0,
            'due_date': DateTime.now()
                .add(const Duration(days: 30))
                .toIso8601String(),
            'created_at': DateTime.now()
                .subtract(const Duration(days: 60))
                .toIso8601String(),
          },
        ],
      };

      AppLogger.logApiResponse('GET', ApiEndpoints.getLoansList, response);
      return response;
    });
  }

  /// Get loan detail
  Future<Map<String, dynamic>> getLoanDetail({required String loanId}) async {
    return handleApiCall(() async {
      AppLogger.logApiRequest(
        'GET',
        '${ApiEndpoints.getLoanDetail}/$loanId',
        null,
      );
      await _simulateNetworkDelay();

      final response = {
        'status': 'success',
        'data': {
          'loan_id': loanId,
          'amount': 1000.0,
          'outstanding': 800.0,
          'status': 'active',
          'interest_rate': 5.0,
          'repayment_plan': 'monthly',
          'due_date': DateTime.now()
              .add(const Duration(days: 30))
              .toIso8601String(),
          'monthly_payment': 200.0,
          'next_payment_date': DateTime.now()
              .add(const Duration(days: 7))
              .toIso8601String(),
          'created_at': DateTime.now()
              .subtract(const Duration(days: 60))
              .toIso8601String(),
        },
      };

      AppLogger.logApiResponse('GET', ApiEndpoints.getLoanDetail, response);
      return response;
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
      await _simulateNetworkDelay();

      if (amount < AppConstants.loanMinAmount ||
          amount > AppConstants.loanMaxAmount) {
        throw ValidationException(
          message:
              'Loan amount must be between ${AppConstants.loanMinAmount} and ${AppConstants.loanMaxAmount}',
        );
      }

      final response = {
        'status': 'success',
        'message': 'Loan application submitted',
        'loan_id': 'LOAN_${DateTime.now().millisecondsSinceEpoch}',
        'application_status': 'pending_review',
        'estimated_approval_time': '1-2 business days',
      };

      AppLogger.logApiResponse('POST', ApiEndpoints.applyLoan, response);
      return response;
    });
  }

  /// Repay loan
  Future<Map<String, dynamic>> repayLoan({
    required String loanId,
    required double amount,
    required double currentOutstanding,
    String paymentMethod = 'Mobile Money',
    String? phoneNumber,
  }) async {
    return handleApiCall(() async {
      AppLogger.logApiRequest('POST', '${ApiEndpoints.repayLoan}/$loanId', {
        'amount': amount,
        'payment_method': paymentMethod,
        'phone_number': phoneNumber,
      });
      await _simulateNetworkDelay();

      if (amount <= 0) {
        throw ValidationException(message: 'Amount must be greater than zero');
      }

      if (amount > currentOutstanding) {
        throw ValidationException(
          message: 'Amount cannot exceed the outstanding balance.',
        );
      }

      final now = DateTime.now();
      final newOutstanding = (currentOutstanding - amount).clamp(
        0,
        currentOutstanding,
      );

      final response = {
        'status': 'success',
        'message': 'Loan repayment successful',
        'data': {
          'loan_id': loanId,
          'transaction_id': 'TXN_${now.millisecondsSinceEpoch}',
          'amount': amount,
          'previous_outstanding': currentOutstanding,
          'new_outstanding': newOutstanding,
          'processed_at': now.toIso8601String(),
          'payment_method': 'momo',
          'payment_method_label': paymentMethod,
          'phone_number': phoneNumber,
        },
      };

      AppLogger.logApiResponse('POST', ApiEndpoints.repayLoan, response);
      return response;
    });
  }
}

/// Savings service
class SavingsService extends BaseService {
  /// Get list of savings goals
  Future<Map<String, dynamic>> getSavingsList({required String userId}) async {
    return handleApiCall(() async {
      AppLogger.logApiRequest('GET', ApiEndpoints.getSavingsList, {
        'user_id': userId,
      });
      await _simulateNetworkDelay();

      final response = {
        'status': 'success',
        'data': [
          {
            'savings_id': 'SAV_001',
            'name': 'Emergency Fund',
            'target': 2000.0,
            'current': 1200.0,
            'interest_earned': 45.50,
            'created_at': DateTime.now()
                .subtract(const Duration(days: 30))
                .toIso8601String(),
          },
        ],
      };

      AppLogger.logApiResponse('GET', ApiEndpoints.getSavingsList, response);
      return response;
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
      await _simulateNetworkDelay();

      if (name.isEmpty || targetAmount <= 0) {
        throw ValidationException(message: AppConstants.validationErrorMessage);
      }

      final response = {
        'status': 'success',
        'message': 'Savings goal created successfully',
        'savings_id': 'SAV_${DateTime.now().millisecondsSinceEpoch}',
        'created_at': DateTime.now().toIso8601String(),
      };

      AppLogger.logApiResponse('POST', ApiEndpoints.createSavings, response);
      return response;
    });
  }

  /// Deposit to savings
  Future<Map<String, dynamic>> depositSavings({
    required String savingsId,
    required double amount,
  }) async {
    return handleApiCall(() async {
      AppLogger.logApiRequest(
        'POST',
        '${ApiEndpoints.depositSavings}/$savingsId',
        {'amount': amount},
      );
      await _simulateNetworkDelay();

      if (amount <= 0) {
        throw ValidationException(message: 'Amount must be greater than zero');
      }

      final response = {
        'status': 'success',
        'message': 'Deposit successful',
        'transaction_id': 'TXN_${DateTime.now().millisecondsSinceEpoch}',
        'new_balance': 1200.0 + amount,
      };

      AppLogger.logApiResponse('POST', ApiEndpoints.depositSavings, response);
      return response;
    });
  }

  /// Withdraw from savings
  Future<Map<String, dynamic>> withdrawSavings({
    required String savingsId,
    required double amount,
  }) async {
    return handleApiCall(() async {
      AppLogger.logApiRequest(
        'POST',
        '${ApiEndpoints.withdrawSavings}/$savingsId',
        {'amount': amount},
      );
      await _simulateNetworkDelay();

      if (amount <= 0) {
        throw ValidationException(message: 'Amount must be greater than zero');
      }

      final response = {
        'status': 'success',
        'message': 'Withdrawal successful',
        'transaction_id': 'TXN_${DateTime.now().millisecondsSinceEpoch}',
        'new_balance': 1200.0 - amount,
      };

      AppLogger.logApiResponse('POST', ApiEndpoints.withdrawSavings, response);
      return response;
    });
  }
}

/// Transaction service
class TransactionService extends BaseService {
  /// Get transactions for user
  Future<Map<String, dynamic>> getTransactions({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    return handleApiCall(() async {
      AppLogger.logApiRequest('GET', ApiEndpoints.getTransactions, {
        'user_id': userId,
        'page': page,
        'limit': limit,
      });
      await _simulateNetworkDelay();

      final response = {
        'status': 'success',
        'data': [
          {
            'transaction_id': 'TXN_001',
            'type': 'deposit',
            'amount': 500.0,
            'description': 'Savings Deposit',
            'date': DateTime.now()
                .subtract(const Duration(hours: 2))
                .toIso8601String(),
            'status': 'success',
          },
          {
            'transaction_id': 'TXN_002',
            'type': 'repayment',
            'amount': 200.0,
            'description': 'Loan Repayment',
            'date': DateTime.now()
                .subtract(const Duration(days: 1))
                .toIso8601String(),
            'status': 'success',
          },
        ],
        'pagination': {
          'current_page': page,
          'total_pages': 5,
          'total_items': 100,
        },
      };

      AppLogger.logApiResponse('GET', ApiEndpoints.getTransactions, response);
      return response;
    });
  }
}
