import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../exceptions/app_exceptions.dart';
import '../models/auth_session.dart';
import '../models/auth_state.dart';
import '../repositories/notification_repository.dart';
import '../../screens/savings/savings_model.dart';
import '../../screens/savings/savings_storage.dart';
import '../services/api_service.dart';
import '../services/device_identity_service.dart';
import '../services/http_client.dart';
import '../services/network_service.dart';
import '../services/notification_service.dart';
import '../services/secure_auth_storage.dart';
import '../utils/logger.dart';
import '../../router/app_router.dart';

String _firstNonEmpty(Iterable<dynamic> values) {
  for (final value in values) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) return text;
  }
  return '';
}

String _normalizePhoneNumber(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('233')) return digits;
  if (digits.startsWith('0') && digits.length == 10) {
    return '233${digits.substring(1)}';
  }
  return digits;
}

String _findAccountNumber(dynamic value) {
  const accountNumberKeys = {
    'account_number',
    'accountnumber',
    'acc_number',
    'account_no',
    'account',
  };
  const memberIdentifierKeys = {
    'member_id',
    'memberid',
    'member_no',
    'member_number',
    'customer_id',
    'customer_number',
    'user_id',
    'userid',
  };

  String findByKeys(dynamic candidate, Set<String> keys) {
    if (candidate is Map) {
      for (final entry in candidate.entries) {
        if (keys.contains(entry.key.toString().trim().toLowerCase())) {
          final text = entry.value?.toString().trim() ?? '';
          if (text.isNotEmpty) return text;
        }
      }
      for (final nested in candidate.values) {
        final text = findByKeys(nested, keys);
        if (text.isNotEmpty) return text;
      }
    } else if (candidate is Iterable) {
      for (final nested in candidate) {
        final text = findByKeys(nested, keys);
        if (text.isNotEmpty) return text;
      }
    }

    return '';
  }

  final accountNumber = findByKeys(value, accountNumberKeys);
  return accountNumber.isNotEmpty
      ? accountNumber
      : findByKeys(value, memberIdentifierKeys);
}

String _findMemberName(dynamic value) {
  const keys = {
    'name',
    'full_name',
    'fullname',
    'account_name',
    'accountname',
    'member_name',
    'membername',
    'customer_name',
    'customername',
    'display_name',
    'displayname',
  };

  if (value is Map) {
    for (final entry in value.entries) {
      if (keys.contains(entry.key.toString().trim().toLowerCase())) {
        final candidate = entry.value?.toString().trim() ?? '';
        if (candidate.isNotEmpty) return candidate;
      }
    }
    for (final nested in value.values) {
      final candidate = _findMemberName(nested);
      if (candidate.isNotEmpty) return candidate;
    }
  } else if (value is Iterable) {
    for (final nested in value) {
      final candidate = _findMemberName(nested);
      if (candidate.isNotEmpty) return candidate;
    }
  }

  return '';
}

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

final investmentServiceProvider = Provider<InvestmentService>((ref) {
  return InvestmentService();
});

final sharesServiceProvider = Provider<SharesService>((ref) {
  return SharesService();
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

final productCatalogServiceProvider = Provider<ProductCatalogService>((ref) {
  return ProductCatalogService();
});

final savingsProductsCatalogProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
      return ref
          .watch(productCatalogServiceProvider)
          .getProducts(endpoint: ApiEndpoints.getSavingsProducts);
    });

final localSavingsGoalsProvider = FutureProvider<List<Savings>>((ref) async {
  return SavingsStorage.loadGoals();
});

final sharesProductsCatalogProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
      return ref
          .watch(productCatalogServiceProvider)
          .getProducts(endpoint: ApiEndpoints.getSharesProducts);
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
  String? _lastRegisteredAccountNumber;

  String? get lastRegisteredAccountNumber => _lastRegisteredAccountNumber;

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

  Future<Map<String, dynamic>> _authenticateWithDeviceNumberFallback({
    required int deviceNumber,
    required Future<Map<String, dynamic>> Function(int) authenticate,
  }) async {
    try {
      final response = await authenticate(deviceNumber);
      if (_isSuccessfulAuthResponse(response)) {
        await deviceIdentityService.rememberBackendDeviceNumber(deviceNumber);
        return response;
      }
      if (!_isDeviceAuthenticationFailure(response['message']?.toString()) ||
          deviceNumber == AppConstants.legacyMobileApiImeiNumber) {
        return response;
      }
    } on AuthException catch (error) {
      if (!_isDeviceAuthenticationFailure(error.message) ||
          deviceNumber == AppConstants.legacyMobileApiImeiNumber) {
        rethrow;
      }
    }

    // Older app builds registered devices with this shared number.
    final response = await authenticate(AppConstants.legacyMobileApiImeiNumber);
    if (_isSuccessfulAuthResponse(response)) {
      await deviceIdentityService.rememberBackendDeviceNumber(
        AppConstants.legacyMobileApiImeiNumber,
      );
    }
    return response;
  }

  bool _isSuccessfulAuthResponse(Map<String, dynamic> response) {
    return AuthSession.isSuccessStatus(response['status']) ||
        AuthSession.isSuccessStatus(response['success']) ||
        AuthSession.isSuccessStatus(response['is_success']) ||
        AuthSession.fromResponse(response) != null;
  }

  bool _isDeviceAuthenticationFailure(String? message) {
    final normalized = message?.trim().toLowerCase() ?? '';
    return normalized.contains('device authentication failed') ||
        normalized.contains('device auth failed');
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

    final userId = prefs.getString(AppConstants.sharedPrefKeyUserId);
    final email = prefs.getString(AppConstants.sharedPrefKeyUserEmail);

    if (userId == null || email == null) {
      return;
    }

    final currentFingerprint = await deviceIdentityService
        .getInstallationFingerprint();
    final token = await SecureAuthStorage.instance.readAuthToken();
    if (token == null || token.isEmpty) {
      if (await SecureAuthStorage.instance
          .hasDeviceVerifiedSessionBoundToFingerprint(currentFingerprint)) {
        if (!mounted) return;
        state = AuthState.authenticated(userId: userId, userEmail: email);
        AppLogger.info('Loaded device-bound PIN-verified authentication');
      }
      return;
    }

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

  /// Authenticates with the member's phone number and password.
  Future<String> login({
    required String phoneNumber,
    required String password,
  }) async {
    state = AuthState.loading();

    try {
      final imeiNumber = await deviceIdentityService.getBackendDeviceNumber();
      final response = await _authenticateWithDeviceNumberFallback(
        deviceNumber: imeiNumber,
        authenticate: (number) => authService.login(
          phoneNumber: phoneNumber,
          password: password,
          imeiNumber: number,
        ),
      );
      AppLogger.info('Login password accepted by backend.');

      final session = AuthSession.fromResponse(response);
      final status = response['status'];
      final isSuccess =
          AuthSession.isSuccessStatus(status) ||
          AuthSession.isSuccessStatus(response['success']) ||
          AuthSession.isSuccessStatus(response['is_success']) ||
          session != null;

      if (!isSuccess) {
        throw AuthException(
          message:
              response['message']?.toString() ??
              AppConstants.invalidCredentialsMessage,
        );
      }

      final prefs = await _getPrefs();
      final storedPhoneNumber =
          prefs.getString(AppConstants.sharedPrefKeyUserEmail)?.trim() ?? '';
      final storedAccountNumber =
          _normalizePhoneNumber(storedPhoneNumber) ==
              _normalizePhoneNumber(phoneNumber)
          ? prefs.getString(AppConstants.sharedPrefKeyUserId)?.trim() ?? ''
          : '';
      final userId = _firstNonEmpty([
        _findAccountNumber(response),
        storedAccountNumber,
      ]).replaceAll(RegExp(r'\D'), '');
      if (userId.length < 6) {
        throw AuthException(
          message:
              'Your password was accepted, but this device has no linked account number. '
              'Choose Sign up > I have an account to link your account first.',
        );
      }
      AppLogger.info('Linked account number resolved for password login.');

      await prefs.setString(AppConstants.sharedPrefKeyUserId, userId);
      await prefs.setString(AppConstants.sharedPrefKeyUserEmail, phoneNumber);
      final memberName = _findMemberName(response);
      if (memberName.isNotEmpty) {
        await prefs.setString(AppConstants.sharedPrefKeyUserName, memberName);
      } else {
        await prefs.remove(AppConstants.sharedPrefKeyUserName);
      }

      final fingerprint = await deviceIdentityService
          .getInstallationFingerprint();
      if (session != null) {
        await SecureAuthStorage.instance.storeSession(
          authToken: session.accessToken,
          refreshToken: session.refreshToken,
          deviceFingerprint: fingerprint,
        );
      } else {
        await SecureAuthStorage.instance.storeDeviceVerifiedSession(
          deviceFingerprint: fingerprint,
        );
      }

      if (mounted) {
        state = AuthState.authenticated(
          userId: userId,
          userEmail: phoneNumber,
          authToken: session?.accessToken,
        );
      }
      AppLogger.info('Password login completed.');
      return userId;
    } on AppException catch (e) {
      if (mounted) {
        state = AuthState.error(e.message);
      }
      AppLogger.error('Login failed', e);
      rethrow;
    }
  }

  Future<void> loginWithPhonePin({
    required String phoneNumber,
    required String pin,
  }) async {
    state = AuthState.loading();

    try {
      final imeiNumber = await deviceIdentityService.getBackendDeviceNumber();
      final fingerprint = await deviceIdentityService
          .getInstallationFingerprint();
      final response = await _authenticateWithDeviceNumberFallback(
        deviceNumber: imeiNumber,
        authenticate: (number) => authService.loginWithPhonePin(
          phoneNumber: phoneNumber,
          pin: pin,
          imeiNumber: number,
        ),
      );
      final session = AuthSession.fromResponse(response);
      final status = response['status'];
      final isSuccess =
          AuthSession.isSuccessStatus(status) ||
          AuthSession.isSuccessStatus(response['success']) ||
          AuthSession.isSuccessStatus(response['is_success']) ||
          session != null;

      if (!isSuccess) {
        throw AuthException(
          message:
              response['message']?.toString() ??
              AppConstants.invalidCredentialsMessage,
        );
      }

      final prefs = await _getPrefs();
      final storedPhoneNumber =
          prefs.getString(AppConstants.sharedPrefKeyUserEmail)?.trim() ?? '';
      final accountNumber = _firstNonEmpty([
        _findAccountNumber(response),
        if (_normalizePhoneNumber(storedPhoneNumber) ==
            _normalizePhoneNumber(phoneNumber))
          prefs.getString(AppConstants.sharedPrefKeyUserId),
      ]).replaceAll(RegExp(r'\D'), '');
      if (accountNumber.length < 6) {
        throw AuthException(
          message:
              'Your PIN was verified, but this device has no linked account number. '
              'Enroll your existing account before signing in.',
        );
      }
      final userId = accountNumber;
      await SecureAuthStorage.instance.storePin(pin);
      if (session != null) {
        await SecureAuthStorage.instance.storeSession(
          authToken: session.accessToken,
          refreshToken: session.refreshToken,
          deviceFingerprint: fingerprint,
        );
      } else {
        await SecureAuthStorage.instance.storeDeviceVerifiedSession(
          deviceFingerprint: fingerprint,
        );
      }
      await prefs.setString(AppConstants.sharedPrefKeyUserId, userId);
      await prefs.setString(AppConstants.sharedPrefKeyUserEmail, phoneNumber);

      state = AuthState.authenticated(
        userId: userId,
        userEmail: phoneNumber,
        authToken: session?.accessToken,
      );
      AppLogger.info('User logged in with phone and PIN');
    } on AppException catch (e) {
      state = AuthState.error(e.message);
      AppLogger.error('Phone and PIN login failed', e);
      rethrow;
    }
  }

  Future<bool> restoreStoredSessionAfterBiometric() async {
    final prefs = await _getPrefs();
    final token = await SecureAuthStorage.instance.readAuthToken();
    final userId = prefs.getString(AppConstants.sharedPrefKeyUserId);
    final userEmail = prefs.getString(AppConstants.sharedPrefKeyUserEmail);
    if (userId == null || userEmail == null) {
      return false;
    }

    final fingerprint = await deviceIdentityService
        .getInstallationFingerprint();
    final hasBoundTokenSession =
        token != null &&
        token.isNotEmpty &&
        await SecureAuthStorage.instance.hasSessionBoundToFingerprint(
          fingerprint,
        );
    final hasBoundPinSession = await SecureAuthStorage.instance
        .hasDeviceVerifiedSessionBoundToFingerprint(fingerprint);
    if (!hasBoundTokenSession && !hasBoundPinSession) {
      return false;
    }

    state = AuthState.authenticated(
      userId: userId,
      userEmail: userEmail,
      authToken: hasBoundTokenSession ? token : null,
    );
    return true;
  }

  Future<String> preparePhonePinLogin({
    required String phoneNumber,
    required String pin,
  }) async {
    try {
      final imeiNumber = await deviceIdentityService.getBackendDeviceNumber();
      final response = await _authenticateWithDeviceNumberFallback(
        deviceNumber: imeiNumber,
        authenticate: (number) => authService.loginWithPhonePin(
          phoneNumber: phoneNumber,
          pin: pin,
          imeiNumber: number,
        ),
      );
      final status = response['status'];
      final accountNumber = _findAccountNumber(response).trim();
      final isSuccess =
          AuthSession.isSuccessStatus(status) ||
          AuthSession.isSuccessStatus(response['success']) ||
          AuthSession.isSuccessStatus(response['is_success']);

      if (!isSuccess || accountNumber.isEmpty) {
        throw AuthException(
          message:
              response['message']?.toString() ??
              'We could not verify your phone number and PIN.',
        );
      }

      final prefs = await _getPrefs();
      await prefs.setString(AppConstants.sharedPrefKeyUserId, accountNumber);
      await prefs.setString(AppConstants.sharedPrefKeyUserEmail, phoneNumber);
      final memberName = _findMemberName(response);
      if (memberName.isNotEmpty) {
        await prefs.setString(AppConstants.sharedPrefKeyUserName, memberName);
      }

      await sendLoginOtp(
        phoneNumber: phoneNumber,
        accountNumber: accountNumber,
      );
      return accountNumber;
    } on AppException catch (e) {
      AppLogger.error('Phone and PIN login preparation failed', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> confirmPhoneNumber({
    required String phoneNumber,
  }) async {
    try {
      final response = await authService.confirmPhoneNumber(
        phoneNumber: phoneNumber,
      );
      AppLogger.info('Phone number confirmed: $phoneNumber');
      return response;
    } on AppException catch (e) {
      AppLogger.error('Phone confirmation failed', e);
      rethrow;
    }
  }

  Future<void> confirmAccountNumber({
    required String phoneNumber,
    required String accountNumber,
    required String birthDate,
  }) async {
    try {
      await authService.confirmAccountNumber(
        phoneNumber: phoneNumber,
        accountNumber: accountNumber,
        birthDate: birthDate,
      );
      AppLogger.info('Account number confirmed: $accountNumber');
    } on AppException catch (e) {
      AppLogger.error('Account confirmation failed', e);
      rethrow;
    }
  }

  String _resolveAccountNumber({
    required String phoneNumber,
    required String accountNumber,
  }) {
    final normalisedAccount = accountNumber.replaceAll(RegExp(r'\D'), '');
    if (normalisedAccount.length >= 5) {
      return normalisedAccount;
    }

    final phoneDigits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (phoneDigits.length >= 5) {
      return phoneDigits.substring(phoneDigits.length - 5);
    }

    return '00000';
  }

  Future<void> sendLoginOtp({
    required String phoneNumber,
    required String accountNumber,
  }) async {
    try {
      final resolvedAccountNumber = _resolveAccountNumber(
        phoneNumber: phoneNumber,
        accountNumber: accountNumber,
      );
      await authService.sendLoginOtp(
        phoneNumber: phoneNumber,
        accountNumber: resolvedAccountNumber,
      );
      AppLogger.info('Login OTP requested for account: $resolvedAccountNumber');
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
      await SecureAuthStorage.instance.storePin(pin);
      if (session != null) {
        final currentFingerprint = await deviceIdentityService
            .getInstallationFingerprint();
        await SecureAuthStorage.instance.storeSession(
          authToken: session.accessToken,
          refreshToken: session.refreshToken,
          deviceFingerprint: currentFingerprint,
        );
      }
      await prefs.setString(AppConstants.sharedPrefKeyUserId, accountNumber);
      await prefs.setString(AppConstants.sharedPrefKeyUserEmail, phoneNumber);
      final memberName = _findMemberName(response);
      if (memberName.isNotEmpty) {
        await prefs.setString(AppConstants.sharedPrefKeyUserName, memberName);
      }

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
      final imeiNumber = await deviceIdentityService.getBackendDeviceNumber();
      final response = await authService.setPin(
        userId: userId,
        pin: pin,
        imeiNumber: imeiNumber,
      );
      final status = response['status'];
      final isSuccess =
          AuthSession.isSuccessStatus(status) ||
          AuthSession.isSuccessStatus(response['success']) ||
          AuthSession.isSuccessStatus(response['is_success']);
      if (!isSuccess) {
        throw AuthException(
          message:
              response['message']?.toString() ??
              'We could not set your PIN. Please try again.',
        );
      }

      await SecureAuthStorage.instance.storePin(pin);
      AppLogger.info('PIN set successfully for user: $userId');
    } on AppException catch (e) {
      AppLogger.error('Set PIN failed', e);
      rethrow;
    }
  }

  Future<void> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    final prefs = await _getPrefs();
    final accountNumber =
        prefs.getString(AppConstants.sharedPrefKeyUserId)?.trim() ?? '';
    final normalizedAccountNumber = accountNumber.replaceAll(RegExp(r'\D'), '');
    if (normalizedAccountNumber.length < 6) {
      throw AuthException(
        message:
            'Your full account number is unavailable. Enroll or link your account before changing your PIN.',
      );
    }

    final imeiNumber = await deviceIdentityService.getBackendDeviceNumber();
    final response = await authService.changePin(
      accountNumber: normalizedAccountNumber,
      currentPin: currentPin,
      newPin: newPin,
      imeiNumber: imeiNumber,
    );
    final succeeded =
        AuthSession.isSuccessStatus(response['status']) ||
        AuthSession.isSuccessStatus(response['success']) ||
        AuthSession.isSuccessStatus(response['is_success']);
    if (!succeeded) {
      throw AuthException(
        message:
            response['message']?.toString() ??
            'We could not change your PIN. Please try again.',
      );
    }

    await SecureAuthStorage.instance.storePin(newPin);
  }

  /// Login using the SMS OTP sent by [confirmAccountNumber]. PIN verification
  /// is a separate authentication flow and must not receive an OTP value.
  Future<void> loginWithOtp({
    required String phoneNumber,
    required String accountNumber,
    required String otp,
    String? transactionPin,
    bool transactionPinAlreadyProvisioned = false,
  }) async {
    state = AuthState.loading();

    try {
      if (!RegExp(r'^\d{4}$').hasMatch(otp.trim())) {
        throw ValidationException(message: AppConstants.invalidOtpMessage);
      }

      final prefs = await _getPrefs();
      final storedAccountNumber =
          prefs.getString(AppConstants.sharedPrefKeyUserId)?.trim() ?? '';
      final effectiveAccountNumber = accountNumber.trim().isNotEmpty
          ? accountNumber.trim()
          : (storedAccountNumber.isNotEmpty
                ? storedAccountNumber
                : (_lastRegisteredAccountNumber ?? ''));

      // The phone-only flow may not know the full account number yet. Use the
      // member identifier only to verify the OTP; the successful response must
      // provide the full account number for customer-data requests.
      final otpAccountIdentifier = _resolveAccountNumber(
        phoneNumber: phoneNumber,
        accountNumber: effectiveAccountNumber,
      );

      final response = await authService.verifyLoginOtp(
        accountNumber: otpAccountIdentifier,
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

      var accountForSession = _firstNonEmpty([
        _findAccountNumber(response),
        effectiveAccountNumber,
      ]).replaceAll(RegExp(r'\D'), '');

      Map<String, dynamic>? phoneConfirmation;
      if (accountForSession.length < 6) {
        phoneConfirmation = await authService.confirmPhoneNumber(
          phoneNumber: phoneNumber,
        );
        accountForSession = _findAccountNumber(
          phoneConfirmation,
        ).replaceAll(RegExp(r'\D'), '');
      }

      if (accountForSession.length < 6) {
        throw AuthException(
          message:
              'OTP verified, but the account number was not available in this '
              'session. Please start registration again.',
        );
      }

      if (transactionPin != null) {
        if (!RegExp(r'^\d{4}$').hasMatch(transactionPin)) {
          throw ValidationException(
            message: 'Transaction PIN must be exactly 4 digits.',
          );
        }
        if (transactionPinAlreadyProvisioned) {
          await SecureAuthStorage.instance.storePin(transactionPin);
        } else {
          await setPin(userId: accountForSession, pin: transactionPin);
        }
      }

      final currentFingerprint = await deviceIdentityService
          .getInstallationFingerprint();
      if (session != null) {
        await SecureAuthStorage.instance.storeSession(
          authToken: session.accessToken,
          refreshToken: session.refreshToken,
          deviceFingerprint: currentFingerprint,
        );
      } else {
        await SecureAuthStorage.instance.storeDeviceVerifiedSession(
          deviceFingerprint: currentFingerprint,
        );
      }
      await prefs.setString(
        AppConstants.sharedPrefKeyUserId,
        accountForSession,
      );
      await prefs.setString(AppConstants.sharedPrefKeyUserEmail, phoneNumber);
      final memberName = _firstNonEmpty([
        _findMemberName(response),
        _findMemberName(phoneConfirmation),
      ]);
      if (memberName.isNotEmpty) {
        await prefs.setString(AppConstants.sharedPrefKeyUserName, memberName);
      }

      state = AuthState.authenticated(
        userId: accountForSession,
        userEmail: phoneNumber,
        authToken: session?.accessToken,
      );

      AppLogger.info(
        'User logged in via OTP using FULL account number length '
        '${accountForSession.length}',
      );

      AppLogger.info(
        'Full account number preserved: '
        '${accountForSession.substring(0, 3)}******'
        '${accountForSession.substring(accountForSession.length - 3)}',
      );
    } on AppException catch (e) {
      state = AuthState.error(e.message);
      AppLogger.error('OTP login failed', e);
      rethrow;
    }
  }

  /// Enroll an existing member for mobile banking. The backend sends the
  /// verification code after accepting the member and device details.
  Future<String> submitRegistration({
    required String accountNumber,
    required String phoneNumber,
    required String birthDate,
    required String password,
    required String? pin,
    required String transactionPin,
  }) async {
    try {
      final imeiNumber = await deviceIdentityService.getBackendDeviceNumber();
      final phoneMake = await deviceIdentityService.getBackendDeviceMake();
      final response = await authService.register(
        accountNumber: accountNumber,
        phoneNumber: phoneNumber,
        birthDate: birthDate,
        password: password,
        pin: pin,
        transactionPin: transactionPin,
        imeiNumber: imeiNumber,
        phoneMake: phoneMake,
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

      await deviceIdentityService.rememberBackendDeviceNumber(imeiNumber);

      // The register response confirms enrollment but does not include an OTP.
      // Request the SMS code explicitly before opening the verification screen.
      await authService.sendLoginOtp(
        phoneNumber: phoneNumber,
        accountNumber: accountNumber,
      );

      AppLogger.info('Registration submitted for: $accountNumber');
      return message.isNotEmpty ? message : 'Registration submitted!';
    } on AppException catch (e) {
      AppLogger.error('Registration failed', e);
      rethrow;
    }
  }

  Future<String> submitNewMemberRegistration({
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
  }) async {
    final imeiNumber = await deviceIdentityService.getBackendDeviceNumber();
    final phoneMake = await deviceIdentityService.getBackendDeviceMake();
    final normalizedPhoneNumber = _normalizePhoneNumber(phoneNumber);
    final response = await authService.createMember(
      fullName: fullName,
      ghanaCard: ghanaCard,
      phoneNumber: normalizedPhoneNumber,
      birthDate: birthDate,
      gender: gender,
      address: address,
      email: email,
      savingsProduct: savingsProduct,
      sharesProduct: sharesProduct,
      password: password,
      transactionPin: transactionPin,
      imeiNumber: imeiNumber,
      phoneMake: phoneMake,
    );
    final status = response['status'];
    final message = response['message'] as String? ?? '';
    final responseData = response['data'] is Map
        ? Map<String, dynamic>.from(response['data'] as Map)
        : const <String, dynamic>{};
    final successStatus = responseData['status'];
    final success =
        AuthSession.isSuccessStatus(status) ||
        (status == null && response['_http_success'] == true) ||
        AuthSession.isSuccessStatus(response['success']) ||
        AuthSession.isSuccessStatus(response['is_success']) ||
        AuthSession.isSuccessStatus(successStatus) ||
        AuthSession.isSuccessStatus(responseData['success']) ||
        AuthSession.isSuccessStatus(responseData['is_success']);
    if (!success) {
      throw AuthException(
        message: message.isNotEmpty
            ? message
            : 'New member registration failed. Please try again.',
      );
    }
    await deviceIdentityService.rememberBackendDeviceNumber(imeiNumber);

    final generatedAccountNumber = _findAccountNumber(response).trim();
    _lastRegisteredAccountNumber = generatedAccountNumber.isEmpty
        ? null
        : generatedAccountNumber;

    final prefs = await _getPrefs();
    if (generatedAccountNumber.isNotEmpty) {
      await prefs.setString(
        AppConstants.sharedPrefKeyUserId,
        generatedAccountNumber,
      );
    } else {
      // Some successful registrations return the account number only after
      // OTP verification. Keep the phone-based flow moving until then.
      await prefs.remove(AppConstants.sharedPrefKeyUserId);
    }
    await prefs.setString(
      AppConstants.sharedPrefKeyUserEmail,
      normalizedPhoneNumber,
    );
    await prefs.setString(AppConstants.sharedPrefKeyUserName, fullName);

    // Creating a new member does not reliably trigger the mobile OTP
    // endpoint. Request it explicitly before showing the OTP screen.
    await authService.sendLoginOtp(
      phoneNumber: normalizedPhoneNumber,
      accountNumber: generatedAccountNumber,
    );

    return message.isNotEmpty ? message : 'Registration successful.';
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
    await resolvedPrefs.remove(AppConstants.sharedPrefKeyUserName);
    await resolvedPrefs.remove(AppConstants.sharedPrefKeyUserToken);
    await resolvedPrefs.remove(AppConstants.sharedPrefKeyUserRefreshToken);
  }
}

// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final userService = ref.watch(userServiceProvider);
  final deviceIdentityService = ref.watch(deviceIdentityServiceProvider);

  return AuthNotifier(
    authService: authService,
    userService: userService,
    deviceIdentityService: deviceIdentityService,
  );
});

// User profile provider
final userProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final auth = ref.watch(authProvider);
  final authService = ref.watch(authServiceProvider);
  final savingsService = ref.watch(savingsServiceProvider);

  final phone = (auth.userEmail ?? '').trim();
  final account = (auth.userId ?? '').trim();
  final prefs = await SharedPreferences.getInstance();
  final storedName = prefs
      .getString(AppConstants.sharedPrefKeyUserName)
      ?.trim();

  if (phone.isEmpty || account.isEmpty) {
    throw ValidationException(
      message:
          'Your account session is incomplete. Please sign in again before loading customer data.',
    );
  }

  var memberName = storedName ?? '';
  if (memberName.isEmpty) {
    try {
      final phoneConfirmation = await authService.confirmPhoneNumber(
        phoneNumber: phone,
      );
      memberName = _findMemberName(phoneConfirmation);
      if (memberName.isNotEmpty) {
        await prefs.setString(AppConstants.sharedPrefKeyUserName, memberName);
      }
    } on AppException catch (error) {
      AppLogger.warning(
        'Account name unavailable from phone confirmation',
        error,
      );
    }
  }

  final pin = await SecureAuthStorage.instance.readPin() ?? '';
  final imeiNumber = await ref
      .watch(deviceIdentityServiceProvider)
      .getBackendDeviceNumber();
  List<Map<String, dynamic>> savings = const [];
  var savingsDataAvailable = true;
  try {
    final savingsResponse = await savingsService.getSavingsList(
      phoneNumber: phone,
      accountNumber: account,
      pin: pin,
      imeiNumber: imeiNumber,
    );
    savings = savingsResponse['data'] is List
        ? (savingsResponse['data'] as List)
              .whereType<Map<String, dynamic>>()
              .where((item) => !SavingsService.isShareProduct(item))
              .toList()
        : const [];
  } on AppException catch (error) {
    AppLogger.warning('Savings data unavailable while loading profile', error);
    savingsDataAvailable = false;
  }
  final balance = savings.fold<double>(
    0,
    (total, item) =>
        total + _readAmount(item['balance'] ?? item['current_balance']),
  );
  final savingsBalancesAvailable =
      savingsDataAvailable &&
      savings.every(
        (item) => item['balance'] != null || item['current_balance'] != null,
      );

  return {
    'user_id': account,
    'name': memberName.isNotEmpty ? memberName : 'Account holder',
    'account_number': account,
    'balance': savingsBalancesAvailable ? balance : null,
    'savings': savingsDataAvailable ? savings.toList() : null,
    'branch': null,
    'phone': phone,
    'status': null,
    'kyc_status': null,
  };
});

double _readAmount(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString().replaceAll(',', '') ?? '') ?? 0;
}

final memberCredentialsProvider = Provider<Map<String, String>>((ref) {
  final auth = ref.watch(authProvider);
  final profile = ref.watch(userProfileProvider).valueOrNull;
  final phone = _firstNonEmpty([
    profile?['phone'],
    profile?['phone_number'],
    profile?['mobile'],
    auth.userEmail,
  ]);

  // Customer-data endpoints require the full account number.
  // Never substitute the five-digit member ID here.
  final account = _firstNonEmpty([
    profile?['account_number'],
    profile?['accountNumber'],
    auth.userId,
  ]);

  return {'phone': phone, 'account': account};
});

// Loans list provider
final loansProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final credentials = ref.watch(memberCredentialsProvider);
  final loanService = ref.watch(loanServiceProvider);

  final pin = await SecureAuthStorage.instance.readPin() ?? '';
  final imeiNumber = await ref
      .watch(deviceIdentityServiceProvider)
      .getBackendDeviceNumber();
  final phone = credentials['phone']!;
  final account = credentials['account']!;

  try {
    final response = await loanService.getLoansList(
      phoneNumber: phone,
      accountNumber: account,
      pin: pin,
      imeiNumber: imeiNumber,
    );
    final data = response['data'];
    if (data is List) {
      final loans = data.whereType<Map<String, dynamic>>().toList();
      return await Future.wait(
        loans.map((loan) async {
          final loanId = (loan['loan_id'] ?? loan['id'] ?? loan['product_id'])
              ?.toString()
              .trim();
          final hasBalance =
              loan['outstanding_balance'] != null || loan['balance'] != null;
          if (loanId == null || loanId.isEmpty || hasBalance) {
            return loan;
          }

          try {
            final balanceResponse = await loanService.getLoanBalance(
              accountNumber: account,
              loanId: loanId,
            );
            return {
              ...loan,
              'outstanding_balance': balanceResponse['balance'],
              'balance_source': 'getLoanBalance',
            };
          } on AppException catch (error) {
            AppLogger.warning(
              'Exact loan balance unavailable for loan $loanId; keeping the list balance.',
              error,
            );
            return loan;
          }
        }),
      );
    }

    return [];
  } on AppException {
    rethrow;
  }
});

// Savings list provider
final savingsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final credentials = ref.watch(memberCredentialsProvider);
  final savingsService = ref.watch(savingsServiceProvider);

  final phone = credentials['phone']?.trim() ?? '';
  final account = credentials['account']?.trim() ?? '';
  if (phone.isEmpty || account.isEmpty) {
    throw ValidationException(
      message: 'Your account details are missing. Please sign in again.',
    );
  }

  final pin = await SecureAuthStorage.instance.readPin() ?? '';
  final imeiNumber = await ref
      .watch(deviceIdentityServiceProvider)
      .getBackendDeviceNumber();

  try {
    final response = await savingsService.getSavingsList(
      phoneNumber: phone,
      accountNumber: account,
      pin: pin,
      imeiNumber: imeiNumber,
    );
    final data = response['data'];
    var savingsAccounts = <Map<String, dynamic>>[];
    if (data is List) {
      final accounts = data
          .whereType<Map<String, dynamic>>()
          .where((account) => !SavingsService.isShareProduct(account))
          .toList();
      savingsAccounts = await Future.wait(
        accounts.map((accountData) async {
          final productId =
              (accountData['savings_id'] ??
                      accountData['product_id'] ??
                      accountData['id'])
                  ?.toString()
                  .trim();
          final hasBalance =
              accountData['balance'] != null ||
              accountData['current_balance'] != null ||
              accountData['amount'] != null;
          if (productId == null || productId.isEmpty || hasBalance) {
            return accountData;
          }

          try {
            final balanceResponse = await savingsService.getSavingsBalance(
              productId: productId,
            );
            return {
              ...accountData,
              'balance': balanceResponse['balance'],
              'balance_source': 'getSavingsBalance',
            };
          } on AppException catch (error) {
            AppLogger.warning(
              'Exact savings balance unavailable for product $productId; '
              'keeping the list balance.',
              error,
            );
            return accountData;
          }
        }),
      );
    }

    return savingsAccounts;
  } on AppException {
    rethrow;
  }
});

final sharesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final credentials = ref.watch(memberCredentialsProvider);
  final pin = await SecureAuthStorage.instance.readPin() ?? '';
  final imeiNumber = await ref
      .watch(deviceIdentityServiceProvider)
      .getBackendDeviceNumber();
  final phone = credentials['phone']?.trim() ?? '';
  final account = credentials['account']?.trim() ?? '';
  if (phone.isEmpty || account.isEmpty) {
    throw ValidationException(
      message: 'Your account details are missing. Please sign in again.',
    );
  }

  final sharesService = ref.watch(sharesServiceProvider);
  final savingsService = ref.watch(savingsServiceProvider);
  List<Map<String, dynamic>> apiShares = [];
  AppException? sharesError;
  try {
    final response = await sharesService.getShares(
      phoneNumber: phone,
      accountNumber: account,
      pin: pin,
      imeiNumber: imeiNumber,
    );
    final data = response['data'];
    if (data is List) {
      apiShares = data.whereType<Map<String, dynamic>>().toList();
    }
  } on AppException catch (error) {
    sharesError = error;
    AppLogger.warning(
      'Dedicated shares endpoint unavailable; checking member savings products.',
      error,
    );
  }

  List<Map<String, dynamic>> memberProducts;
  try {
    final response = await savingsService.getSavingsList(
      phoneNumber: phone,
      accountNumber: account,
      pin: pin,
      imeiNumber: imeiNumber,
    );
    final data = response['data'];
    memberProducts = data is List
        ? data.whereType<Map<String, dynamic>>().toList()
        : [];
  } on AppException catch (error) {
    if (apiShares.isNotEmpty) {
      AppLogger.warning(
        'Member savings products unavailable; showing dedicated shares data.',
        error,
      );
      return apiShares;
    }
    rethrow;
  }

  final sharesFromMemberProducts = memberProducts
      .where(SavingsService.isShareProduct)
      .toList();
  if (sharesError != null && sharesFromMemberProducts.isEmpty) {
    throw sharesError;
  }

  final result = <Map<String, dynamic>>[...apiShares];
  final knownIds = apiShares
      .map(
        (share) =>
            (share['id'] ??
                    share['share_id'] ??
                    share['account_id'] ??
                    share['product_id'] ??
                    share['savings_id'])
                ?.toString()
                .trim()
                .toLowerCase() ??
            '',
      )
      .where((id) => id.isNotEmpty)
      .toSet();
  for (final share in sharesFromMemberProducts) {
    final id =
        (share['id'] ??
                share['share_id'] ??
                share['account_id'] ??
                share['product_id'] ??
                share['savings_id'])
            ?.toString()
            .trim()
            .toLowerCase() ??
        '';
    if (id.isEmpty || knownIds.add(id)) {
      result.add(share);
    }
  }

  return result;
});

final investmentsApiProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final credentials = ref.watch(memberCredentialsProvider);
  final pin = await SecureAuthStorage.instance.readPin() ?? '';
  final phone = credentials['phone']?.trim() ?? '';
  final account = credentials['account']?.trim() ?? '';
  if (phone.isEmpty || account.isEmpty) {
    throw ValidationException(
      message: 'Your account details are missing. Please sign in again.',
    );
  }
  final investmentRecords = <Map<String, dynamic>>[];

  if (pin.isNotEmpty) {
    try {
      final response = await ref
          .watch(investmentServiceProvider)
          .getInvestments(phoneNumber: phone, accountNumber: account, pin: pin);
      final data = response['data'];
      if (data is List) {
        investmentRecords.addAll(data.whereType<Map<String, dynamic>>());
      }
    } on AppException catch (error) {
      AppLogger.warning(
        'General investment data is unavailable; keeping fixed deposits.',
        error,
      );
    }
  }

  try {
    final imeiNumber = await ref
        .watch(deviceIdentityServiceProvider)
        .getBackendDeviceNumber();
    final response = await ref
        .watch(savingsServiceProvider)
        .getFixedDeposits(accountNumber: account, imeiNumber: imeiNumber);
    final data = response['data'];
    if (data is List) {
      investmentRecords.addAll(
        data.whereType<Map<String, dynamic>>().map((deposit) {
          final principal =
              deposit['principal'] ??
              deposit['principal_amount'] ??
              deposit['deposit_amount'] ??
              deposit['initial_amount'] ??
              deposit['amount'] ??
              deposit['balance'];
          final currentValue =
              deposit['current_value'] ??
              deposit['maturity_value'] ??
              deposit['maturity_amount'] ??
              deposit['balance'] ??
              principal;
          return {
            ...deposit,
            'id':
                deposit['investment_id'] ??
                deposit['fixed_deposit_id'] ??
                deposit['savings_id'] ??
                deposit['id'] ??
                '',
            'type': 'Fixed Deposit',
            'plan':
                deposit['plan'] ??
                deposit['product_name'] ??
                deposit['pro_name'] ??
                deposit['name'] ??
                'Fixed Deposit',
            'status': deposit['status'] ?? deposit['pro_status'],
            'principal': principal,
            'current_value': currentValue,
            'total_interest':
                deposit['total_interest'] ?? deposit['interest_earned'],
            'maturity_date':
                deposit['maturity_date'] ??
                deposit['maturity'] ??
                deposit['end_date'] ??
                '—',
          };
        }),
      );
    }
  } on AppException catch (error) {
    if (investmentRecords.isEmpty) {
      rethrow;
    }
    AppLogger.warning(
      'Fixed deposit data is unavailable; keeping available investments.',
      error,
    );
  }

  return investmentRecords;
});

/// Loads the selected savings account for mutation flows without using demo data.
final withdrawalAccountProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, savingsId) async {
      final credentials = ref.watch(memberCredentialsProvider);
      final phone = credentials['phone']?.trim() ?? '';
      final account = credentials['account']?.trim() ?? '';
      if (phone.isEmpty || account.isEmpty) {
        throw ValidationException(
          message: 'Your account details are missing. Please sign in again.',
        );
      }

      final imeiNumber = await ref
          .watch(deviceIdentityServiceProvider)
          .getBackendDeviceNumber();
      final response = await ref
          .watch(savingsServiceProvider)
          .getSavingsList(
            phoneNumber: phone,
            accountNumber: account,
            pin: '',
            imeiNumber: imeiNumber,
          );
      final data = response['data'];
      final accounts = data is List
          ? data.whereType<Map<String, dynamic>>()
          : const <Map<String, dynamic>>[];
      if (savingsId.isEmpty && accounts.isNotEmpty) {
        return accounts.first;
      }
      return accounts.firstWhere(
        (account) =>
            (account['savings_id'] ?? account['id'] ?? account['product_id'])
                .toString() ==
            savingsId,
        orElse: () => throw ValidationException(
          message: 'The selected savings account could not be found.',
        ),
      );
    });

// Transactions provider
final productStatementProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, productId) {
      return ref
          .watch(transactionServiceProvider)
          .getProductStatement(productId: productId);
    });

final transactionsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final credentials = ref.watch(memberCredentialsProvider);
  final transactionService = ref.watch(transactionServiceProvider);

  final phone = credentials['phone']?.trim() ?? '';
  final account = credentials['account']?.trim() ?? '';
  if (phone.isEmpty || account.isEmpty) {
    throw ValidationException(
      message: 'Your account details are missing. Please sign in again.',
    );
  }

  final pin = await SecureAuthStorage.instance.readPin() ?? '';

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

    return [];
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

Future<Map<String, String>> _runCountProbe({
  required Future<List<Map<String, dynamic>>> Function() action,
}) async {
  try {
    final records = await action();
    return {'status': 'ok', 'message': 'Returned ${records.length} record(s)'};
  } on AppException catch (e) {
    return {'status': 'error', 'message': e.message};
  } catch (e) {
    return {'status': 'error', 'message': e.toString()};
  }
}

String _maskDiagnosticValue(String value) {
  final trimmed = value.trim();
  if (trimmed.length <= 4) return '****';
  return '${trimmed.substring(0, 2)}••••${trimmed.substring(trimmed.length - 2)}';
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

      final credentials = ref.watch(memberCredentialsProvider);
      final phone = credentials['phone']!;
      final account = credentials['account']!;
      final pin = await SecureAuthStorage.instance.readPin() ?? '';
      final imeiNumber = await ref
          .watch(deviceIdentityServiceProvider)
          .getBackendDeviceNumber();

      final userService = ref.watch(userServiceProvider);
      final loanService = ref.watch(loanServiceProvider);
      final savingsService = ref.watch(savingsServiceProvider);
      final transactionService = ref.watch(transactionServiceProvider);
      final sharesService = ref.watch(sharesServiceProvider);

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
            imeiNumber: imeiNumber,
          );
        },
      );

      final savingsResult = await _runBackendProbe(
        action: () async {
          await savingsService.getSavingsList(
            phoneNumber: phone,
            accountNumber: account,
            pin: pin,
            imeiNumber: imeiNumber,
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

      final sharesResult = await _runCountProbe(
        action: () async {
          final response = await sharesService.getShares(
            phoneNumber: phone,
            accountNumber: account,
            pin: pin,
            imeiNumber: imeiNumber,
          );
          final data = response['data'];
          return data is List
              ? data.whereType<Map<String, dynamic>>().toList()
              : <Map<String, dynamic>>[];
        },
      );

      return {
        'identity': {
          'status': 'info',
          'message':
              'Account ${_maskDiagnosticValue(account)}, phone ${_maskDiagnosticValue(phone)}',
        },
        'profile': profileResult,
        'loans': loansResult,
        'savings': savingsResult,
        'shares': sharesResult,
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

  try {
    final authService = ref.watch(authServiceProvider);
    final deviceIdentityService = ref.watch(deviceIdentityServiceProvider);
    final imeiNumber = await deviceIdentityService.getBackendDeviceNumber();
    final phoneMake = await deviceIdentityService.getBackendDeviceMake();
    final response = await authService.register(
      accountNumber: auth.userId!,
      phoneNumber: auth.userEmail!,
      birthDate: '',
      imeiNumber: imeiNumber,
      phoneMake: phoneMake,
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
