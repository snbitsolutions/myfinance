import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../utils/logger.dart';

class DeviceIdentityService {
  DeviceIdentityService({DeviceInfoPlugin? plugin})
    : _deviceInfoPlugin = plugin ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _deviceInfoPlugin;

  Future<void> primeInstallationId() async {
    await _getOrCreateInstallationId();
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
      },
    };
  }

  Future<Map<String, dynamic>> collectIdentity() async {
    final installationId = await _getOrCreateInstallationId();

    final base = <String, dynamic>{
      'installation_id': installationId,
      'platform': _platformName,
      'is_physical_device': true,
    };

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

  Future<String> _getOrCreateInstallationId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(AppConstants.sharedPrefKeyDeviceInstallId);

    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final random = Random.secure();
    final value =
        'dev_${DateTime.now().microsecondsSinceEpoch}_${random.nextInt(1 << 32).toRadixString(16)}';

    await prefs.setString(AppConstants.sharedPrefKeyDeviceInstallId, value);
    return value;
  }

  String get _platformName {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }
}
