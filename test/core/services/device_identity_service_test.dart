import 'package:adepa_teachers/core/services/device_identity_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeviceIdentityService', () {
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

    test('shortenFingerprint keeps only the start and end of long values', () {
      final shortened = DeviceIdentityService.shortenFingerprint(
        '0123456789abcdef0123456789abcdef',
      );

      expect(shortened, '01234567...abcdef');
    });

    test('resolveDeviceIdentifier prefers IMEI-like values first', () {
      expect(
        DeviceIdentityService.resolveDeviceIdentifier({
          'imei_number': '355123456789012',
          'android_id': 'android-123',
          'installation_id': 'dev_abc',
        }),
        '355123456789012',
      );

      expect(
        DeviceIdentityService.resolveDeviceIdentifier({
          'android_id': 'android-123',
          'installation_id': 'dev_abc',
        }),
        'android-123',
      );
    });
  });
}
