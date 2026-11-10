import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import 'secure_auth_storage.dart';
import '../utils/logger.dart';

class DeviceIdentityService {
  DeviceIdentityService({DeviceInfoPlugin? plugin})
    : _deviceInfoPlugin = plugin ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _deviceInfoPlugin;

  Future<void> primeInstallationId() async {
    await _getOrCreateInstallationId();
  }

  Future<String> getInstallationId() => _getOrCreateInstallationId();

  Future<int> getBackendDeviceNumber() async {
    final installationId = await _getOrCreateInstallationId();
    return backendDeviceNumber(installationId);
  }

  Future<String> getBackendDeviceMake() async {
    final identity = await collectIdentity();
    final manufacturer = identity['manufacturer']?.toString().trim() ?? '';
    final model = identity['device_model']?.toString().trim() ?? '';

    if (manufacturer.isEmpty || manufacturer.toLowerCase() == 'unknown') {
      return model.isEmpty ? 'Unknown device' : model;
    }
    if (model.isEmpty || model.toLowerCase() == 'unknown') {
      return manufacturer;
    }
    if (model.toLowerCase().startsWith(manufacturer.toLowerCase())) {
      return model;
    }
    return '$manufacturer $model';
  }

  @visibleForTesting
  static int backendDeviceNumber(String installationId) {
    const minimum = 100000000000000;
    const range = 900000000000000;
    final digest = sha256.convert(utf8.encode(installationId)).toString();
    final value = BigInt.parse(digest.substring(0, 13), radix: 16);
    return minimum + (value % BigInt.from(range)).toInt();
  }

  Future<Map<String, dynamic>> getSecurityPayload({
    required String action,
  }) async {
    final deviceData = await collectIdentity();
    return {
      'device': deviceData,
      'security': {
        'action': action,
        'captured_at': DateTime.now().toUtc().toIso8601String(),
        'session_binding_fingerprint': deviceData['installation_fingerprint'],
      },
    };
  }

  Future<String> getInstallationFingerprint() async {
    final installationId = await _getOrCreateInstallationId();
    return fingerprintIdentifier('$installationId|$_platformName');
  }

  Future<String> getMaskedInstallationId() async {
    final installationId = await _getOrCreateInstallationId();
    return maskIdentifier(installationId);
  }

  Future<Map<String, dynamic>> collectIdentity() async {
    final installationId = await _getOrCreateInstallationId();
    final maskedInstallationId = maskIdentifier(installationId);
    final installationFingerprint = fingerprintIdentifier(
      '$installationId|$_platformName',
    );

    final base = <String, dynamic>{
      'installation_id_masked': maskedInstallationId,
      'installation_fingerprint': installationFingerprint,
      'identifier_source': 'app_installation_id',
      'platform': _platformName,
      'is_physical_device': true,
    };

    final resolvedDeviceIdentifier = await _resolveDeviceIdentifier();
    if (resolvedDeviceIdentifier != null &&
        resolvedDeviceIdentifier.isNotEmpty) {
      base['device_identifier'] = resolvedDeviceIdentifier;
      base['device_identifier_masked'] = maskIdentifier(
        resolvedDeviceIdentifier,
      );
    }

    try {
      if (kIsWeb) {
        final webInfo = await _deviceInfoPlugin.webBrowserInfo;
        return {
          ...base,
          'device_model': webInfo.browserName.name,
          'os_version': webInfo.userAgent ?? 'web',
          'manufacturer': 'web',
          'is_physical_device': false,
        };
      }

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final info = await _deviceInfoPlugin.androidInfo;
          return {
            ...base,
            'device_model': '${info.brand} ${info.model}',
            'os_version': 'Android ${info.version.release}',
            'manufacturer': info.manufacturer,
            'device_sdk_int': info.version.sdkInt,
            'is_physical_device': info.isPhysicalDevice,
            'android_id': info.id,
          };
        case TargetPlatform.iOS:
          final info = await _deviceInfoPlugin.iosInfo;
          return {
            ...base,
            'device_model': info.utsname.machine,
            'os_version': 'iOS ${info.systemVersion}',
            'manufacturer': 'Apple',
            'is_physical_device': info.isPhysicalDevice,
          };
        case TargetPlatform.windows:
          final info = await _deviceInfoPlugin.windowsInfo;
          return {
            ...base,
            'device_model': info.productName,
            'os_version':
                '${info.majorVersion}.${info.minorVersion}.${info.buildNumber}',
            'manufacturer': 'Microsoft',
          };
        case TargetPlatform.macOS:
          final info = await _deviceInfoPlugin.macOsInfo;
          return {
            ...base,
            'device_model': info.model,
            'os_version':
                '${info.majorVersion}.${info.minorVersion}.${info.patchVersion}',
            'manufacturer': 'Apple',
          };
        case TargetPlatform.linux:
          final info = await _deviceInfoPlugin.linuxInfo;
          return {
            ...base,
            'device_model': info.prettyName,
            'os_version': info.version ?? info.versionId ?? 'Linux',
            'manufacturer': info.name,
          };
        case TargetPlatform.fuchsia:
          return {
            ...base,
            'device_model': 'Fuchsia device',
            'os_version': 'Fuchsia',
            'manufacturer': 'unknown',
          };
      }
    } catch (e, st) {
      AppLogger.warning(
        'Device identity collection failed. Using fallback.',
        e,
        st,
      );
      return {
        ...base,
        'device_model': 'unknown',
        'os_version': 'unknown',
        'manufacturer': 'unknown',
      };
    }
  }

  Future<String?> _resolveDeviceIdentifier() async {
    try {
      if (kIsWeb) {
        return null;
      }

      if (defaultTargetPlatform == TargetPlatform.android) {
        final info = await _deviceInfoPlugin.androidInfo;
        return resolveDeviceIdentifier({
          'android_id': info.id,
          'installation_id': await _getOrCreateInstallationId(),
        });
      }

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final info = await _deviceInfoPlugin.iosInfo;
        return resolveDeviceIdentifier({
          'device_identifier': info.identifierForVendor,
          'installation_id': await _getOrCreateInstallationId(),
        });
      }
    } catch (e, st) {
      AppLogger.warning('Unable to resolve device identifier', e, st);
    }

    return null;
  }

  @visibleForTesting
  static String? resolveDeviceIdentifier(Map<String, dynamic> values) {
    for (final key in [
      'installation_id',
      'installationId',
      'android_id',
      'device_identifier',
    ]) {
      final value = values[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }

  Future<String> _getOrCreateInstallationId() async {
    final secureStorage = SecureAuthStorage.instance;
    final existing = await secureStorage.readDeviceInstallationId();

    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.sharedPrefKeyDeviceInstallId);

    final random = kIsWeb ? Random() : Random.secure();
    const max32BitExclusive = 0x100000000; // 2^32
    final value =
        'dev_${DateTime.now().microsecondsSinceEpoch}_${random.nextInt(max32BitExclusive).toRadixString(16)}';

    await secureStorage.writeDeviceInstallationId(value);
    return value;
  }

  @visibleForTesting
  static String maskIdentifier(
    String value, {
    int leading = 4,
    int trailing = 4,
  }) {
    if (value.isEmpty) return value;

    final visibleCharacters = leading + trailing;
    if (value.length <= visibleCharacters) {
      return List.filled(value.length, '*').join();
    }

    final start = value.substring(0, leading);
    final end = value.substring(value.length - trailing);
    final middle = List.filled(value.length - visibleCharacters, '*').join();
    return '$start$middle$end';
  }

  @visibleForTesting
  static String fingerprintIdentifier(String value) {
    return sha256.convert(utf8.encode(value)).toString();
  }

  static String shortenFingerprint(
    String value, {
    int leading = 8,
    int trailing = 6,
  }) {
    if (value.isEmpty) return value;

    final visibleCharacters = leading + trailing;
    if (value.length <= visibleCharacters) {
      return value;
    }

    final start = value.substring(0, leading);
    final end = value.substring(value.length - trailing);
    return '$start...$end';
  }

  String get _platformName {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }
}
