import 'package:adepa_teachers/core/constants/app_constants.dart';
import 'package:adepa_teachers/core/services/device_identity_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeviceIdentityService', () {
    test('uses the configured stable backend device number', () async {
      expect(
        await DeviceIdentityService().getBackendDeviceNumber(),
        AppConstants.defaultMobileApiImeiNumber,
      );
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
