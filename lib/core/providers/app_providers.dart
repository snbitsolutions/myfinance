import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../exceptions/app_exceptions.dart';
import '../models/auth_session.dart';
import '../models/auth_state.dart';
import '../repositories/notification_repository.dart';
import '../services/api_service.dart';
import '../services/device_identity_service.dart';
import '../services/http_client.dart';
import '../services/network_service.dart';
import '../services/notification_service.dart';
import '../services/secure_auth_storage.dart';
import '../utils/logger.dart';
import '../../router/app_router.dart';

// Core infrastructure providers
final httpClientProvider = Provider<HttpClient>((ref) {
  return HttpClient.instance;
});

final networkServiceProvider = Provider<NetworkService>((ref) {
  return NetworkService.instance;
});

// Network connectivity state provider
final connectivityProvider = StreamProvider<bool>((ref) {
  final networkService = ref.watch(networkServiceProvider);
  return networkService.connectivityStream;
});

// Service providers
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

final loanServiceProvider = Provider<LoanService>((ref) {
  return LoanService();
});

final savingsServiceProvider = Provider<SavingsService>((ref) {
  return SavingsService();
});

final transactionServiceProvider = Provider<TransactionService>((ref) {
  return TransactionService();
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationService.instance;
});

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});

final deviceIdentityServiceProvider = Provider<DeviceIdentityService>((ref) {
  return DeviceIdentityService();
});

// SharedPreferences provider
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return await SharedPreferences.getInstance();
});

// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService authService;
  final UserService userService;
  final DeviceIdentityService deviceIdentityService;
  SharedPreferences? _prefs;

  AuthNotifier({
    required this.authService,
    required this.userService,
    required this.deviceIdentityService,
    SharedPreferences? prefs,
  }) : super(AuthState.unauthenticated()) {
    _prefs = prefs;
    _loadStoredAuth();
  }

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// Load stored authentication from SharedPreferences
  void _loadStoredAuth() {
    _restoreStoredAuth();
  }

  Future<void> _restoreStoredAuth() async {
    final prefs = await _getPrefs();
    final debugBypassAuth = AppRouter.isDebugAuthBypassEnabled(
      savedPreferenceValue: prefs.getBool(
        AppConstants.sharedPrefKeyDebugBypassAuth,
      ),
    );

    if (debugBypassAuth) {
      final savedUserId =
          prefs.getString(AppConstants.sharedPrefKeyUserId)?.trim() ??
          AppConstants.debugApiAccountNumber.trim();
      final savedUserEmail =
          prefs.getString(AppConstants.sharedPrefKeyUserEmail)?.trim() ??
          AppConstants.debugApiPhoneNumber.trim();

      if (savedUserId.isEmpty || savedUserEmail.isEmpty) {
        if (!mounted) {
          return;
        }
        state = AuthState.unauthenticated();
        AppLogger.info(
          'Debug bypass enabled, but no test account identity found.',
        );
        return;
      }

      if (!mounted) {
        return;
      }
      state = AuthState.authenticated(
        userId: savedUserId,
        userEmail: savedUserEmail,
        authToken: 'debug-token',
      );
      AppLogger.info('Loaded debug authentication bypass');
      return;
    }

    final token = await SecureAuthStorage.instance.readAuthToken();
    final userId = prefs.getString(AppConstants.sharedPrefKeyUserId);
    final email = prefs.getString(AppConstants.sharedPrefKeyUserEmail);

    if (token == null || token.isEmpty || userId == null || email == null) {
      return;
    }

    final currentFingerprint = await deviceIdentityService
        .getInstallationFingerprint();
    final isBoundToCurrentDevice = await SecureAuthStorage.instance
        .hasSessionBoundToFingerprint(currentFingerprint);

    if (!isBoundToCurrentDevice) {
      await _clearStoredAuth(prefs: prefs);
      AppLogger.warning(
        'Stored authentication rejected due to device fingerprint mismatch.',
      );
      return;
    }

    // Check if notifier is still mounted before setting state
    // (e.g., it may have been disposed during async operations)
    if (!mounted) {
      return;
    }

    state = AuthState.authenticated(
      userId: userId,
      userEmail: email,
      authToken: token,
    );
    AppLogger.info('Loaded stored authentication');
  }

  /// Login user
  Future<void> login({required String email, required String password}) async {
    state = AuthState.loading();

    try {
      final deviceContext = await deviceIdentityService.getSecurityPayload(
        action: 'login',
      );
      final response = await authService.login(
        email: email,
        password: password,
        deviceContext: deviceContext,
      );

      final session = AuthSession.fromResponse(response);
      if (session == null) {
        throw AuthException(
          message:
              'Sign-in succeeded, but no session token was returned by the server.',
        );
      }

      final data = response['data'] is Map
          ? Map<String, dynamic>.from(response['data'] as Map)
          : <String, dynamic>{};
      final token = session.accessToken;
      final refreshToken = session.refreshToken;
      final userId =
          (data['user_id'] as String?) ??
          (data['account_number'] as String?) ??
          'unknown-user';
      final prefs = await _getPrefs();
      final currentFingerprint = await deviceIdentityService
          .getInstallationFingerprint();

      await SecureAuthStorage.instance.storeSession(
        authToken: token,
        refreshToken: refreshToken,
        deviceFingerprint: currentFingerprint,
      );

      await prefs.setString(AppConstants.sharedPrefKeyUserId, userId);
      await prefs.setString(AppConstants.sharedPrefKeyUserEmail, email);

      state = AuthState.authenticated(
        userId: userId,
        userEmail: email,
        authToken: token,
      );

      AppLogger.info('User logged in successfully: $userId');
    } on AppException catch (e) {
      state = AuthState.error(e.message);
      AppLogger.error('Login failed', e);
      rethrow;
    }
  }

  Future<void> confirmPhoneNumber({required String phoneNumber}) async {
    try {
      await authService.confirmPhoneNumber(phoneNumber: phoneNumber);
      AppLogger.info('Phone number confirmed: $phoneNumber');
    } on AppException catch (e) {
      AppLogger.error('Phone confirmation failed', e);
      rethrow;
    }
  }

  Future<void> confirmAccountNumber({
    required String phoneNumber,
    required String accountNumber,
  }) async {
    try {
      await authService.confirmAccountNumber(
        phoneNumber: phoneNumber,
        accountNumber: accountNumber,
      );
      AppLogger.info('Account number confirmed: $accountNumber');
    } on AppException catch (e) {
      AppLogger.error('Account confirmation failed', e);
      rethrow;
    }
  }

  Future<void> sendLoginOtp({
    required String phoneNumber,
    required String accountNumber,
  }) async {
    try {
      await authService.sendLoginOtp(
        phoneNumber: phoneNumber,
        accountNumber: accountNumber,
      );
      AppLogger.info('Login OTP requested for account: $accountNumber');
    } on AppException catch (e) {
      AppLogger.error('Login OTP request failed', e);
      rethrow;
    }
  }

  Future<void> signInWithPin({
    required String phoneNumber,
    required String accountNumber,
    required String pin,
  }) async {
    state = AuthState.loading();

    try {
      final response = await authService.confirmPin(
        phoneNumber: phoneNumber,
        accountNumber: accountNumber,
        pin: pin,
      );
      final status = response['status'];
      final message = response['message'] as String?;
      final isSuccess =
          AuthSession.isSuccessStatus(status) ||
          AuthSession.isSuccessStatus(response['success']) ||
          AuthSession.isSuccessStatus(response['is_success']);

      if (!isSuccess) {
        throw AuthException(
          message: message ?? AppConstants.invalidCredentialsMessage,
        );
      }

      final session = AuthSession.fromResponse(response);
      final prefs = await _getPrefs();
      if (session != null) {
        final currentFingerprint = await deviceIdentityService
            .getInstallationFingerprint();
        await SecureAuthStorage.instance.storeSession(
          authToken: session.accessToken,
          refreshToken: session.refreshToken,
          deviceFingerprint: currentFingerprint,
        );
      }
      await SecureAuthStorage.instance.storePin(pin);
      await prefs.setString(AppConstants.sharedPrefKeyUserId, accountNumber);
      await prefs.setString(AppConstants.sharedPrefKeyUserEmail, phoneNumber);

      state = AuthState.authenticated(
        userId: accountNumber,
        userEmail: phoneNumber,
        authToken: session?.accessToken,
      );

      AppLogger.info('User signed in successfully: $accountNumber');
    } on AppException catch (e) {
      state = AuthState.error(e.message);
      AppLogger.error('PIN sign in failed', e);
      rethrow;
    }
  }

  /// Send OTP
  Future<String> sendOtp({required String email}) async {
    try {
      final deviceContext = await deviceIdentityService.getSecurityPayload(
        action: 'send_otp',
      );
      final response = await authService.sendOtp(
        email: email,
        deviceContext: deviceContext,
      );
      final otpId = response['otp_id'] as String;
      AppLogger.info('OTP sent to $email');
      return otpId;
    } on AppException catch (e) {
      AppLogger.error('Send OTP failed', e);
      rethrow;
    }
  }

  /// Verify OTP
  Future<String> verifyOtp({required String otpId, required String otp}) async {
    try {
      final deviceContext = await deviceIdentityService.getSecurityPayload(
        action: 'verify_otp',
      );
      final response = await authService.verifyOtp(
        otpId: otpId,
        otp: otp,
        deviceContext: deviceContext,
      );
      final verificationToken = response['verification_token'] as String;
      AppLogger.info('OTP verified successfully');
      return verificationToken;
    } on AppException catch (e) {
      AppLogger.error('OTP verification failed', e);
      rethrow;
    }
  }

  /// Set PIN
  Future<void> setPin({required String userId, required String pin}) async {
    try {
      final deviceContext = await deviceIdentityService.getSecurityPayload(
        action: 'set_pin',
      );
      await authService.setPin(
        userId: userId,
        pin: pin,
        deviceContext: deviceContext,
      );
      AppLogger.info('PIN set successfully for user: $userId');
    } on AppException catch (e) {
      AppLogger.error('Set PIN failed', e);
      rethrow;
    }
  }

  /// Login using the SMS OTP sent by [confirmAccountNumber]. PIN verification
  /// is a separate authentication flow and must not receive an OTP value.
  Future<void> loginWithOtp({
    required String phoneNumber,
    required String accountNumber,
    required String otp,
  }) async {
    state = AuthState.loading();
    try {
      if (!RegExp(r'^\d{4}$').hasMatch(otp.trim())) {
        throw ValidationException(message: AppConstants.invalidOtpMessage);
      }

      final response = await authService.verifyLoginOtp(
        accountNumber: accountNumber,
        otp: otp,
      );
      final status = response['status'];
      final message = response['message'] as String?;
      final isSuccess =
          // The published Verify OTP example uses status 0 for a confirmed
          // OTP, unlike the other auth endpoints.
          status == 0 ||
          status == '0' ||
          AuthSession.isSuccessStatus(status) ||
          AuthSession.isSuccessStatus(response['success']) ||
          AuthSession.isSuccessStatus(response['is_success']);

      if (!isSuccess) {
        throw AuthException(
          message: message ?? 'Invalid OTP. Please try again.',
        );
      }

      final session = AuthSession.fromResponse(response);
      final prefs = await _getPrefs();
      final currentFingerprint = await deviceIdentityService
          .getInstallationFingerprint();
      final storedAuthToken =
          session?.accessToken ??
          'otp-session-${DateTime.now().millisecondsSinceEpoch}';

      await SecureAuthStorage.instance.storeSession(
        authToken: storedAuthToken,
        refreshToken: session?.refreshToken,
        deviceFingerprint: currentFingerprint,
      );
      await prefs.setString(AppConstants.sharedPrefKeyUserId, accountNumber);
      await prefs.setString(AppConstants.sharedPrefKeyUserEmail, phoneNumber);

      state = AuthState.authenticated(
        userId: accountNumber,
        userEmail: phoneNumber,
        authToken: storedAuthToken,
      );

      AppLogger.info('User logged in via OTP: $accountNumber');
    } on AppException catch (e) {
      state = AuthState.error(e.message);
      AppLogger.error('OTP login failed', e);
      rethrow;
    }
  }

  /// Register a new member (account number + PIN). No session is created —
  /// the backend must approve the registration before the user can log in.
  Future<String> submitRegistration({
    required String accountNumber,
    required String pin,
    String? phoneNumber,
  }) async {
    try {
      final response = await authService.register(
        accountNumber: accountNumber,
        phoneNumber: phoneNumber,
        pin: pin,
      );

      final status = response['status'];
      final message = response['message'] as String? ?? '';
      final isSuccess =
          status == 1 ||
          status == '1' ||
          (status is String && status.toLowerCase() == 'success');

      if (!isSuccess) {
        throw AuthException(
          message: message.isNotEmpty
              ? message
              : 'Registration failed. Please try again.',
        );
      }

      AppLogger.info('Registration submitted for: $accountNumber');
      return message.isNotEmpty ? message : 'Registration submitted!';
    } on AppException catch (e) {
      AppLogger.error('Registration failed', e);
      rethrow;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await _clearStoredAuth();

      state = AuthState.unauthenticated();
      AppLogger.info('User logged out');
    } on AppException catch (e) {
      AppLogger.error('Logout failed', e);
      rethrow;
    }
  }

  /// Clear error
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  Future<void> _clearStoredAuth({SharedPreferences? prefs}) async {
    final resolvedPrefs = prefs ?? await _getPrefs();
    await SecureAuthStorage.instance.clearAuthSecrets();
    await resolvedPrefs.remove(AppConstants.sharedPrefKeyUserId);
    await resolvedPrefs.remove(AppConstants.sharedPrefKeyUserEmail);
    await resolvedPrefs.remove(AppConstants.sharedPrefKeyUserToken);
    await resolvedPrefs.remove(AppConstants.sharedPrefKeyUserRefreshToken);
  }
}

// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final userService = ref.watch(userServiceProvider);
  final deviceIdentityService = ref.watch(deviceIdentityServiceProvider);
  final prefs = ref
      .watch(sharedPreferencesProvider)
      .maybeWhen(data: (prefs) => prefs, orElse: () => null);

  return AuthNotifier(
    authService: authService,
    userService: userService,
    deviceIdentityService: deviceIdentityService,
    prefs: prefs,
  );
});

Map<String, dynamic> _buildFallbackProfile({String? userId, String? phone}) {
  final resolvedUserId = userId ?? 'demo-user';
  final resolvedPhone = phone ?? '233200000000';

  return {
    'user_id': resolvedUserId,
    'name': 'Member $resolvedUserId',
    'account_number': resolvedUserId,
    'balance': 0.0,
    'branch': 'Primary Branch',
    'phone': resolvedPhone,
    'status': 'Active',
  };
}

// ignore: unused_element
Map<String, dynamic> _buildFallbackProfileForAuth(AuthState auth) =>
    _buildFallbackProfile(
      userId: auth.userId ?? 'member',
      phone: auth.userEmail,
    );

List<Map<String, dynamic>> _buildFallbackTransactionsForAuth(AuthState auth) {
  final account = auth.userId ?? 'member';
  final phone = auth.userEmail ?? 'N/A';

  return [
    {
      'transaction_id': 'otp-account-sync',
      'type': 'credit',
      'amount': 0.0,
      'description': 'Account synced for $account',
      'date': DateTime.now().toIso8601String(),
      'status': 'success',
      'balance': 0.0,
    },
    {
      'transaction_id': 'otp-phone-sync',
      'type': 'debit',
      'amount': 0.0,
      'description': 'Phone linked: $phone',
      'date': DateTime.now().toIso8601String(),
      'status': 'success',
      'balance': 0.0,
    },
  ];
}

bool _shouldUseLocalDemoData(AuthState auth) {
  // Temporary local/dev fallback for testing. Flip this off once the real
  // authentication/API flow is ready to be restored.
  const useLocalDemoData = bool.fromEnvironment(
    'USE_LOCAL_DEMO_DATA',
    defaultValue: false,
  );
  return useLocalDemoData;
}

// User profile provider
final userProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final auth = ref.watch(authProvider);
  final userService = ref.watch(userServiceProvider);

  if (_shouldUseLocalDemoData(auth)) {
    return _buildFallbackProfile();
  }

  final phone = auth.userEmail ?? '';
  final account = auth.userId ?? '';
  final pin = await SecureAuthStorage.instance.readPin() ?? '';

  if (pin.isEmpty) {
    throw ValidationException(
      message:
          'Your account PIN is missing. Please complete sign-in and set your PIN before loading account data.',
    );
  }

  try {
    final response = await userService.getUserProfile(
      phoneNumber: phone,
      accountNumber: account,
      pin: pin,
    );
    final data = response['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw GenericException(
      message: 'The backend returned an empty profile payload.',
    );
  } on AppException {
    rethrow;
  }
});

// Loans list provider
final loansProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final auth = ref.watch(authProvider);
  final loanService = ref.watch(loanServiceProvider);

  if (_shouldUseLocalDemoData(auth)) {
    return [
      {
        'loan_id': 'demo-loan-1',
        'amount': 1500.0,
        'status': 'Approved',
        'purpose': 'Emergency fund',
      },
    ];
  }

  final pin = await SecureAuthStorage.instance.readPin() ?? '';
  final phone = auth.userEmail ?? '';
  final account = auth.userId ?? '';

  if (pin.isEmpty) {
    throw ValidationException(
      message:
          'Your account PIN is missing. Please complete sign-in and set your PIN before loading loans.',
    );
  }

  try {
    final response = await loanService.getLoansList(
      phoneNumber: phone,
      accountNumber: account,
      pin: pin,
    );
    final data = response['data'];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }

    return [];
  } on AppException {
    rethrow;
  }
});

// Savings list provider
final savingsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final auth = ref.watch(authProvider);
  final savingsService = ref.watch(savingsServiceProvider);

  if (_shouldUseLocalDemoData(auth)) {
    return [
      {
        'savings_id': 'demo-savings-1',
        'name': 'Emergency Fund',
        'target_amount': 5000.0,
        'current_amount': 2350.0,
      },
    ];
  }

  final pin = await SecureAuthStorage.instance.readPin() ?? '';
  final phone = auth.userEmail ?? '';
  final account = auth.userId ?? '';

  if (pin.isEmpty) {
    throw ValidationException(
      message:
          'Your account PIN is missing. Please complete sign-in and set your PIN before loading savings.',
    );
  }

  try {
    final response = await savingsService.getSavingsList(
      phoneNumber: phone,
      accountNumber: account,
      pin: pin,
    );
    final data = response['data'];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }

    return [];
  } on AppException {
    rethrow;
  }
});

List<Map<String, dynamic>> _buildFallbackTransactions() {
  return [
    {
      'transaction_id': 'demo-1',
      'type': 'credit',
      'amount': 1250.0,
      'description': 'Salary deposit',
      'date': '2026-08-09',
    },
    {
      'transaction_id': 'demo-2',
      'type': 'debit',
      'amount': 320.5,
      'description': 'Groceries',
      'date': '2026-08-08',
    },
    {
      'transaction_id': 'demo-3',
      'type': 'repayment',
      'amount': 150.0,
      'description': 'Loan repayment',
      'date': '2026-08-07',
    },
  ];
}

// Transactions provider
final transactionsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final auth = ref.watch(authProvider);
  final transactionService = ref.watch(transactionServiceProvider);

  if (_shouldUseLocalDemoData(auth)) {
    return _buildFallbackTransactions();
  }

  final pin = await SecureAuthStorage.instance.readPin() ?? '';
  final phone = auth.userEmail ?? '';
  final account = auth.userId ?? '';

  if (pin.isEmpty) {
    throw ValidationException(
      message:
          'Your account PIN is missing. Please complete sign-in and set your PIN before loading transactions.',
    );
  }

  try {
    final response = await transactionService.getTransactions(
      phoneNumber: phone,
      accountNumber: account,
      pin: pin,
    );
    final data = response['data'];
    if (data is List) {
      final normalized = data.whereType<Map<String, dynamic>>().toList();
      return normalized;
    }

    return _buildFallbackTransactionsForAuth(auth);
  } on AppException {
    rethrow;
  }
});

Future<Map<String, String>> _runBackendProbe({
  required Future<void> Function() action,
}) async {
  try {
    await action();
    return {'status': 'ok', 'message': 'OK'};
  } on AppException catch (e) {
    return {'status': 'error', 'message': e.message};
  } catch (e) {
    return {'status': 'error', 'message': e.toString()};
  }
}

final backendDiagnosticsProvider =
    FutureProvider<Map<String, Map<String, String>>>((ref) async {
      final auth = ref.watch(authProvider);
      if (!kDebugMode) {
        return {
          'profile': {'status': 'info', 'message': 'Diagnostics disabled'},
          'loans': {'status': 'info', 'message': 'Diagnostics disabled'},
          'savings': {'status': 'info', 'message': 'Diagnostics disabled'},
          'transactions': {'status': 'info', 'message': 'Diagnostics disabled'},
        };
      }

      if (!auth.isAuthenticated ||
          auth.userId == null ||
          auth.userEmail == null) {
        return {
          'profile': {'status': 'error', 'message': 'Not authenticated'},
          'loans': {'status': 'error', 'message': 'Not authenticated'},
          'savings': {'status': 'error', 'message': 'Not authenticated'},
          'transactions': {'status': 'error', 'message': 'Not authenticated'},
        };
      }

      final phone = auth.userEmail!;
      final account = auth.userId!;
      final pin = await SecureAuthStorage.instance.readPin() ?? '';

      final userService = ref.watch(userServiceProvider);
      final loanService = ref.watch(loanServiceProvider);
      final savingsService = ref.watch(savingsServiceProvider);
      final transactionService = ref.watch(transactionServiceProvider);

      final profileResult = await _runBackendProbe(
        action: () async {
          await userService.getUserProfile(
            phoneNumber: phone,
            accountNumber: account,
            pin: pin,
          );
        },
      );

      final loansResult = await _runBackendProbe(
        action: () async {
          await loanService.getLoansList(
            phoneNumber: phone,
            accountNumber: account,
            pin: pin,
          );
        },
      );

      final savingsResult = await _runBackendProbe(
        action: () async {
          await savingsService.getSavingsList(
            phoneNumber: phone,
            accountNumber: account,
            pin: pin,
          );
        },
      );

      final transactionsResult = await _runBackendProbe(
        action: () async {
          await transactionService.getTransactions(
            phoneNumber: phone,
            accountNumber: account,
            pin: pin,
          );
        },
      );

      return {
        'profile': profileResult,
        'loans': loansResult,
        'savings': savingsResult,
        'transactions': transactionsResult,
      };
    });

final debugRegistrationProbeProvider = FutureProvider<Map<String, String>>((
  ref,
) async {
  final auth = ref.watch(authProvider);

  if (!kDebugMode) {
    return {
      'status': 'info',
      'message': 'Registration probe is available in debug builds only.',
    };
  }

  if (!auth.isAuthenticated || auth.userId == null || auth.userEmail == null) {
    return {'status': 'error', 'message': 'Not authenticated'};
  }

  final pin = await SecureAuthStorage.instance.readPin() ?? '';
  if (pin.isEmpty) {
    return {
      'status': 'error',
      'message': 'No PIN saved. Set PIN first to run registration probe.',
    };
  }

  try {
    final authService = ref.watch(authServiceProvider);
    final response = await authService.register(
      accountNumber: auth.userId!,
      phoneNumber: auth.userEmail!,
      pin: pin,
    );

    final status = response['status'];
    final message = (response['message'] as String?)?.trim();
    final ok =
        status == 1 ||
        status == '1' ||
        (status is String && status.toLowerCase() == 'success');

    return {
      'status': ok ? 'ok' : 'error',
      'message': message?.isNotEmpty == true
          ? message!
          : (ok
                ? 'Registration endpoint responded successfully.'
                : 'Registration endpoint returned an unexpected response.'),
    };
  } on AppException catch (e) {
    return {'status': 'error', 'message': e.message};
  } catch (e) {
    return {'status': 'error', 'message': e.toString()};
  }
});
