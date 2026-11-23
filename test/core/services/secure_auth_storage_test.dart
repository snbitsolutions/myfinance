import 'package:adepa_teachers/core/constants/app_constants.dart';
import 'package:adepa_teachers/core/exceptions/app_exceptions.dart';
import 'package:adepa_teachers/core/services/secure_auth_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final secureStore = <String, String>{};
  var failWrites = false;
  var failReads = false;

  setUp(() {
    secureStore.clear();
    failWrites = false;
    failReads = false;
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          final arguments =
              (call.arguments as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{};
          final key = arguments['key'] as String?;

          switch (call.method) {
            case 'read':
              if (failReads) {
                throw PlatformException(code: 'secure_storage_unavailable');
              }
              return key == null ? null : secureStore[key];
            case 'write':
              if (failWrites) {
                throw PlatformException(code: 'secure_storage_unavailable');
              }
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

  test('stores the PIN only in secure storage', () async {
    final storage = SecureAuthStorage();
    await storage.storePin('4321');

    final prefs = await SharedPreferences.getInstance();
    expect(secureStore[AppConstants.secureStorageKeyUserPin], '4321');
    expect(prefs.containsKey(AppConstants.sharedPrefKeyUserPin), isFalse);
    expect(await storage.readPin(), '4321');
  });

  test('fails closed when secure PIN storage is unavailable', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.sharedPrefKeyUserPin, '1234');
    failWrites = true;

    await expectLater(
      SecureAuthStorage().storePin('4321'),
      throwsA(isA<CacheException>()),
    );

    expect(prefs.containsKey(AppConstants.sharedPrefKeyUserPin), isFalse);
    expect(
      secureStore.containsKey(AppConstants.secureStorageKeyUserPin),
      isFalse,
    );
  });

  test('does not restore a legacy PIN from shared preferences', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.sharedPrefKeyUserPin, '1234');

    expect(await SecureAuthStorage().readPin(), isNull);
    expect(prefs.containsKey(AppConstants.sharedPrefKeyUserPin), isFalse);
  });

  test(
    'clears legacy PIN even when secure storage initialization fails',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.sharedPrefKeyUserPin, '1234');
      failReads = true;

      await expectLater(
        SecureAuthStorage().readPin(),
        throwsA(isA<CacheException>()),
      );

      expect(prefs.containsKey(AppConstants.sharedPrefKeyUserPin), isFalse);
    },
  );

  test('clears session secrets without deleting the transaction PIN', () async {
    final storage = SecureAuthStorage();
    await storage.storePin('4321');
    await storage.storeSession(
      authToken: 'token',
      refreshToken: 'refresh',
      deviceFingerprint: 'device',
    );
    await storage.storeDeviceVerifiedSession(deviceFingerprint: 'device');

    await storage.clearAuthSecrets();

    expect(await storage.readPin(), '4321');
    expect(await storage.readAuthToken(), isNull);
  });
}
