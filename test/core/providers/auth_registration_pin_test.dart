import 'package:adepa_teachers/core/constants/app_constants.dart';
import 'package:adepa_teachers/core/providers/app_providers.dart';
import 'package:adepa_teachers/core/services/api_service.dart';
import 'package:adepa_teachers/core/services/device_identity_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RegistrationOtpAuthService extends AuthService {
  @override
  Future<Map<String, dynamic>> verifyLoginOtp({
    required String accountNumber,
    required String otp,
  }) async {
    return {'status': 0, 'account_number': accountNumber};
  }
}

class _RegistrationDeviceIdentityService extends DeviceIdentityService {
  @override
  Future<String> getInstallationFingerprint() async => 'test-fingerprint';
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

  test(
    'stores the registration transaction PIN after successful OTP',
    () async {
      final notifier = AuthNotifier(
        authService: _RegistrationOtpAuthService(),
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
      expect(secureStore[AppConstants.secureStorageKeyUserPin], '2468');
      expect(prefs.containsKey(AppConstants.sharedPrefKeyUserPin), isFalse);
    },
  );
}
