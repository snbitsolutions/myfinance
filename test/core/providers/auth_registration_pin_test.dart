import 'package:adepa_teachers/core/constants/app_constants.dart';
import 'package:adepa_teachers/core/providers/app_providers.dart';
import 'package:adepa_teachers/core/services/api_service.dart';
import 'package:adepa_teachers/core/services/device_identity_service.dart';
import 'package:adepa_teachers/core/services/secure_auth_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RegistrationOtpAuthService extends AuthService {
  String? setPinAccountNumber;
  String? setPinValue;
  String? loginPassword;
  String? loginMemberName;
  Map<String, dynamic>? loginResponse;
  String? otpPhoneNumber;
  String? otpAccountNumber;

  @override
  Future<Map<String, dynamic>> login({
    required String phoneNumber,
    required String password,
    required int imeiNumber,
  }) async {
    loginPassword = password;
    return loginResponse ??
        {
          'status': 1,
          'member_id': '40752',
          'account_number': '0010100000144795',
          if (loginMemberName != null) 'member_name': loginMemberName,
        };
  }

  @override
  Future<void> sendLoginOtp({
    required String phoneNumber,
    required String accountNumber,
  }) async {
    otpPhoneNumber = phoneNumber;
    otpAccountNumber = accountNumber;
  }

  @override
  Future<Map<String, dynamic>> verifyLoginOtp({
    required String accountNumber,
    required String otp,
  }) async {
    return {'status': 0, 'account_number': accountNumber};
  }

  @override
  Future<Map<String, dynamic>> setPin({
    required String userId,
    required String pin,
    required int imeiNumber,
    Map<String, dynamic>? deviceContext,
  }) async {
    setPinAccountNumber = userId;
    setPinValue = pin;
    return {'status': 1, 'message': 'PIN set'};
  }
}

class _RegistrationDeviceIdentityService extends DeviceIdentityService {
  @override
  Future<String> getInstallationFingerprint() async => 'test-fingerprint';

  @override
  Future<int> getBackendDeviceNumber() async => 100200300;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final secureStore = <String, String>{};

  setUp(() {
    secureStore.clear();
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          final arguments =
              (call.arguments as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{};
          final key = arguments['key'] as String?;

          switch (call.method) {
            case 'read':
              return key == null ? null : secureStore[key];
            case 'write':
              if (key != null) {
                secureStore[key] = arguments['value']?.toString() ?? '';
              }
              return null;
            case 'delete':
              if (key != null) secureStore.remove(key);
              return null;
            case 'deleteAll':
              secureStore.clear();
              return null;
            case 'containsKey':
              return key != null && secureStore.containsKey(key);
            case 'readAll':
              return Map<String, String>.from(secureStore);
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('provisions an existing-member PIN after successful OTP', () async {
    final authService = _RegistrationOtpAuthService();
    final notifier = AuthNotifier(
      authService: authService,
      userService: UserService(),
      deviceIdentityService: _RegistrationDeviceIdentityService(),
    );
    addTearDown(notifier.dispose);

    await notifier.loginWithOtp(
      phoneNumber: '233241952608',
      accountNumber: '0010100000144795',
      otp: '1234',
      transactionPin: '2468',
    );

    final prefs = await SharedPreferences.getInstance();
    expect(notifier.state.isAuthenticated, isTrue);
    expect(authService.setPinAccountNumber, '0010100000144795');
    expect(authService.setPinValue, '2468');
    expect(secureStore[AppConstants.secureStorageKeyUserPin], '2468');
    expect(prefs.containsKey(AppConstants.sharedPrefKeyUserPin), isFalse);
  });

  test(
    'does not provision the new-member PIN twice after successful OTP',
    () async {
      final authService = _RegistrationOtpAuthService();
      final notifier = AuthNotifier(
        authService: authService,
        userService: UserService(),
        deviceIdentityService: _RegistrationDeviceIdentityService(),
      );
      addTearDown(notifier.dispose);

      await notifier.loginWithOtp(
        phoneNumber: '233241952608',
        accountNumber: '0010100000144795',
        otp: '1234',
        transactionPin: '2468',
        transactionPinAlreadyProvisioned: true,
      );

      expect(notifier.state.isAuthenticated, isTrue);
      expect(authService.setPinAccountNumber, isNull);
      expect(authService.setPinValue, isNull);
      expect(secureStore[AppConstants.secureStorageKeyUserPin], '2468');
    },
  );

  test('password login authenticates without requesting OTP', () async {
    final authService = _RegistrationOtpAuthService();
    final notifier = AuthNotifier(
      authService: authService,
      userService: UserService(),
      deviceIdentityService: _RegistrationDeviceIdentityService(),
    );
    addTearDown(notifier.dispose);
    await SecureAuthStorage.instance.storePin('1357');

    final accountNumber = await notifier.login(
      phoneNumber: '233241952608',
      password: 'member-password',
    );

    expect(accountNumber, '0010100000144795');
    expect(notifier.state.isAuthenticated, isTrue);
    expect(notifier.state.userId, accountNumber);
    expect(authService.loginPassword, 'member-password');
    expect(authService.otpPhoneNumber, isNull);
    expect(authService.otpAccountNumber, isNull);
    expect(secureStore[AppConstants.secureStorageKeyUserPin], '1357');
    expect(
      secureStore[AppConstants.secureStorageKeyDeviceVerifiedSession],
      'true',
    );
  });

  test('password login accepts an is_success-only response', () async {
    final authService = _RegistrationOtpAuthService()
      ..loginResponse = {
        'is_success': true,
        'account_number': '0010100000144795',
      };
    final notifier = AuthNotifier(
      authService: authService,
      userService: UserService(),
      deviceIdentityService: _RegistrationDeviceIdentityService(),
    );
    addTearDown(notifier.dispose);

    final accountNumber = await notifier.login(
      phoneNumber: '233241952608',
      password: 'member-password',
    );

    expect(accountNumber, '0010100000144795');
    expect(notifier.state.isAuthenticated, isTrue);
  });

  test(
    'password login refreshes the cached name from the active account',
    () async {
      final authService = _RegistrationOtpAuthService()
        ..loginMemberName = 'Current Account Holder';
      final notifier = AuthNotifier(
        authService: authService,
        userService: UserService(),
        deviceIdentityService: _RegistrationDeviceIdentityService(),
      );
      addTearDown(notifier.dispose);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AppConstants.sharedPrefKeyUserName,
        'Previous Account Holder',
      );

      await notifier.login(
        phoneNumber: '233241952608',
        password: 'member-password',
      );

      expect(
        prefs.getString(AppConstants.sharedPrefKeyUserName),
        'Current Account Holder',
      );
    },
  );

  test(
    'password login clears a cached name when response has no account name',
    () async {
      final authService = _RegistrationOtpAuthService();
      final notifier = AuthNotifier(
        authService: authService,
        userService: UserService(),
        deviceIdentityService: _RegistrationDeviceIdentityService(),
      );
      addTearDown(notifier.dispose);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AppConstants.sharedPrefKeyUserName,
        'Previous Account Holder',
      );

      await notifier.login(
        phoneNumber: '233241952608',
        password: 'member-password',
      );

      expect(prefs.containsKey(AppConstants.sharedPrefKeyUserName), isFalse);
    },
  );
}
