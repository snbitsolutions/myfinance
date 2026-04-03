import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../exceptions/app_exceptions.dart';
import '../models/auth_state.dart';
import '../services/api_service.dart';
import '../services/device_identity_service.dart';
import '../services/http_client.dart';
import '../services/network_service.dart';
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
    _getPrefs().then((prefs) {
      final token = prefs.getString(AppConstants.sharedPrefKeyUserToken);
      final userId = prefs.getString(AppConstants.sharedPrefKeyUserId);
      final email = prefs.getString(AppConstants.sharedPrefKeyUserEmail);

      if (token != null && userId != null && email != null) {
        state = AuthState.authenticated(
          userId: userId,
          userEmail: email,
          authToken: token,
        );
        AppLogger.info('Loaded stored authentication');
      }
    });
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
      final userId = data['user_id'] as String;
      final prefs = await _getPrefs();

      // Save to SharedPreferences
      await prefs.setString(AppConstants.sharedPrefKeyUserToken, token);
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

  /// Logout user
  Future<void> logout() async {
    try {
      final userId = state.userId;
      if (userId != null) {
        await authService.logout(userId: userId);
      }

      final prefs = await _getPrefs();

      // Clear from SharedPreferences
      await prefs.remove(AppConstants.sharedPrefKeyUserToken);
      await prefs.remove(AppConstants.sharedPrefKeyUserId);
      await prefs.remove(AppConstants.sharedPrefKeyUserEmail);

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

  final response = await userService.getUserProfile(userId: auth.userId!);
  return response['data'] as Map<String, dynamic>;
});

// Loans list provider
final loansProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final auth = ref.watch(authProvider);
  final loanService = ref.watch(loanServiceProvider);

  if (!auth.isAuthenticated || auth.userId == null) {
    throw AuthException(message: 'User not authenticated');
  }

  final response = await loanService.getLoansList(userId: auth.userId!);
  return List<Map<String, dynamic>>.from(response['data'] as List);
});

// Savings list provider
final savingsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final auth = ref.watch(authProvider);
  final savingsService = ref.watch(savingsServiceProvider);

  if (!auth.isAuthenticated || auth.userId == null) {
    throw AuthException(message: 'User not authenticated');
  }

  final response = await savingsService.getSavingsList(userId: auth.userId!);
  return List<Map<String, dynamic>>.from(response['data'] as List);
});

// Transactions provider
final transactionsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final auth = ref.watch(authProvider);
  final transactionService = ref.watch(transactionServiceProvider);

  if (!auth.isAuthenticated || auth.userId == null) {
    throw AuthException(message: 'User not authenticated');
  }

  final response = await transactionService.getTransactions(
    userId: auth.userId!,
  );
  return List<Map<String, dynamic>>.from(response['data'] as List);
});
