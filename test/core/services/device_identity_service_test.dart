import 'package:adepa_teachers/core/constants/app_constants.dart';
import 'package:adepa_teachers/core/services/device_identity_service.dart';
import 'package:adepa_teachers/core/services/secure_auth_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final secureStore = <String, String>{};

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(secureStorageChannel, (call) async {
        final args = (call.arguments as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
        final key = args['key'] as String?;

        switch (call.method) {
          case 'read':
            if (key == null) return null;
            return secureStore[key];
          case 'write':
            if (key != null) {
              final value = args['value'];
              secureStore[key] = value?.toString() ?? '';
            }
            return null;
          case 'delete':
            if (key != null) {
              secureStore.remove(key);
            }
            return null;
          case 'deleteAll':
            secureStore.clear();
            return null;
          case 'containsKey':
            if (key == null) return false;
            return secureStore.containsKey(key);
          case 'readAll':
            return Map<String, String>.from(secureStore);
          default:
            return null;
        }
      });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    secureStore.clear();
  });

  group('DeviceIdentityService', () {
    test('uses a per-installation backend device number when no debug override is set', () async {
      final service = DeviceIdentityService();
      final first = await service.getBackendDeviceNumber();
      final second = await service.getBackendDeviceNumber();

      expect(first, second);
      expect(first, inInclusiveRange(100000000000000, 999999999999999));
      expect(AppConstants.defaultMobileApiImeiNumber, 0);
    });

    test(
      'maskIdentifier keeps only leading and trailing characters visible',
      () {
        final masked = DeviceIdentityService.maskIdentifier(
          'dev_1775656251325294_1efdc9c4',
        );

        expect(masked, 'dev_*********************c9c4');
      },
    );

    test('reuses the registered backend device number', () async {
      await SecureAuthStorage.instance.writeBackendDeviceNumber(456789012345678);

      expect(
        await DeviceIdentityService().getBackendDeviceNumber(),
        456789012345678,
      );
    });

    test('maskIdentifier fully masks short values', () {
      final masked = DeviceIdentityService.maskIdentifier('abcd1234');

      expect(masked, '********');
    });

    test('fingerprintIdentifier is deterministic and non-empty', () {
      final first = DeviceIdentityService.fingerprintIdentifier('device-id');
      final second = DeviceIdentityService.fingerprintIdentifier('device-id');

      expect(first, second);
      expect(first, hasLength(64));
      expect(first, isNot('device-id'));
    });

    test('backendDeviceNumber is stable and numeric', () {
      final first = DeviceIdentityService.backendDeviceNumber('installation');
      final second = DeviceIdentityService.backendDeviceNumber('installation');
      final otherInstallation = DeviceIdentityService.backendDeviceNumber(
        'another-installation',
      );

      expect(first, second);
      expect(first, inInclusiveRange(100000000000000, 999999999999999));
      expect(otherInstallation, isNot(first));
    });

    test('shortenFingerprint keeps only the start and end of long values', () {
      final shortened = DeviceIdentityService.shortenFingerprint(
        '0123456789abcdef0123456789abcdef',
      );

      expect(shortened, '01234567...abcdef');
    });

    test('resolveDeviceIdentifier prefers app installation ID', () {
      expect(
        DeviceIdentityService.resolveDeviceIdentifier({
          'android_id': 'android-123',
          'installation_id': 'dev_abc',
        }),
        'dev_abc',
      );

      expect(
        DeviceIdentityService.resolveDeviceIdentifier({
          'android_id': 'android-123',
        }),
        'android-123',
      );
    });
  });
}
