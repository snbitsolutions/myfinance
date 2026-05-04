import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../exceptions/app_exceptions.dart';
import '../models/auth_state.dart';
import '../repositories/notification_repository.dart';
import '../services/api_service.dart';
import '../services/device_identity_service.dart';
import '../services/http_client.dart';
import '../services/network_service.dart';
import '../services/notification_service.dart';
import '../services/secure_auth_storage.dart';
import '../utils/logger.dart';

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

      final data = response['data'] as Map<String, dynamic>;
      final token = data['auth_token'] as String;
      final refreshToken = data['refresh_token'] as String?;
      final userId = data['user_id'] as String;
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
      final status = (response['status'] as num?)?.toInt() ?? 0;
      final message = response['message'] as String?;

      if (status != 1) {
        throw AuthException(
          message: message ?? AppConstants.invalidCredentialsMessage,
        );
      }

      final prefs = await _getPrefs();
      final currentFingerprint = await deviceIdentityService
          .getInstallationFingerprint();
      final sessionToken = 'stccu-session:$accountNumber';

      await SecureAuthStorage.instance.storeSession(
        authToken: sessionToken,
        deviceFingerprint: currentFingerprint,
      );
      await SecureAuthStorage.instance.storePin(pin);
      await prefs.setString(AppConstants.sharedPrefKeyUserId, accountNumber);
      await prefs.setString(AppConstants.sharedPrefKeyUserEmail, phoneNumber);

      state = AuthState.authenticated(
        userId: accountNumber,
        userEmail: phoneNumber,
        authToken: sessionToken,
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

  /// Login using OTP (OTP is sent when confirmAccountNumber is called; user
  /// enters it here and we verify via /confirmPin).
  Future<void> loginWithOtp({
    required String phoneNumber,
    required String accountNumber,
    required String otp,
  }) async {
    state = AuthState.loading();
    try {
      final response = await authService.confirmPin(
        phoneNumber: phoneNumber,
        accountNumber: accountNumber,
        pin: otp,
      );
      final status = (response['status'] as num?)?.toInt() ?? 0;
      final message = response['message'] as String?;

      if (status != 1) {
        throw AuthException(
          message: message ?? 'Invalid OTP. Please try again.',
        );
      }

      final prefs = await _getPrefs();
      final currentFingerprint =
          await deviceIdentityService.getInstallationFingerprint();
      final sessionToken = 'stccu-session:$accountNumber';

      await SecureAuthStorage.instance.storeSession(
        authToken: sessionToken,
        deviceFingerprint: currentFingerprint,
      );
      await SecureAuthStorage.instance.storePin(otp);
      await prefs.setString(AppConstants.sharedPrefKeyUserId, accountNumber);
      await prefs.setString(AppConstants.sharedPrefKeyUserEmail, phoneNumber);

      state = AuthState.authenticated(
        userId: accountNumber,
        userEmail: phoneNumber,
        authToken: sessionToken,
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
  }) async {
    try {
      final response = await authService.register(
        accountNumber: accountNumber,
        pin: pin,
      );

      final status = response['status'];
      final message = response['message'] as String? ?? '';
      final isSuccess = status == 1 ||
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

// User profile provider
final userProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final auth = ref.watch(authProvider);
  final userService = ref.watch(userServiceProvider);

  if (!auth.isAuthenticated || auth.userId == null) {
    throw AuthException(message: 'User not authenticated');
  }

  final pin = await SecureAuthStorage.instance.readPin() ?? '';
  final phone = auth.userEmail ?? '';
  final account = auth.userId!;

  final response = await userService.getUserProfile(
    phoneNumber: phone,
    accountNumber: account,
    pin: pin,
  );
  return response['data'] as Map<String, dynamic>;
});

// Loans list provider
final loansProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final auth = ref.watch(authProvider);
  final loanService = ref.watch(loanServiceProvider);

  if (!auth.isAuthenticated || auth.userId == null) {
    throw AuthException(message: 'User not authenticated');
  }

  final pin = await SecureAuthStorage.instance.readPin() ?? '';
  final phone = auth.userEmail ?? '';
  final account = auth.userId!;

  final response = await loanService.getLoansList(
    phoneNumber: phone,
    accountNumber: account,
    pin: pin,
  );
  return List<Map<String, dynamic>>.from(response['data'] as List);
});

// Savings list provider
final savingsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final auth = ref.watch(authProvider);
  final savingsService = ref.watch(savingsServiceProvider);

  if (!auth.isAuthenticated || auth.userId == null) {
    throw AuthException(message: 'User not authenticated');
  }

  final pin = await SecureAuthStorage.instance.readPin() ?? '';
  final phone = auth.userEmail ?? '';
  final account = auth.userId!;

  final response = await savingsService.getSavingsList(
    phoneNumber: phone,
    accountNumber: account,
    pin: pin,
  );
  return List<Map<String, dynamic>>.from(response['data'] as List);
});

// Transactions provider
final transactionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final auth = ref.watch(authProvider);
  final transactionService = ref.watch(transactionServiceProvider);

  if (!auth.isAuthenticated || auth.userId == null) {
    throw AuthException(message: 'User not authenticated');
  }

  final pin = await SecureAuthStorage.instance.readPin() ?? '';
  final phone = auth.userEmail ?? '';
  final account = auth.userId!;

  final response = await transactionService.getTransactions(
    phoneNumber: phone,
    accountNumber: account,
    pin: pin,
  );
  return List<Map<String, dynamic>>.from(response['data'] as List);
});
