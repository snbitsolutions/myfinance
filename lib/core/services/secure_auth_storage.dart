import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class SecureAuthStorage {
  SecureAuthStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static final SecureAuthStorage instance = SecureAuthStorage();

  final FlutterSecureStorage _storage;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await _migrateLegacyTokens();
    _initialized = true;
  }

  Future<void> storeSession({
    required String authToken,
    required String deviceFingerprint,
    String? refreshToken,
  }) async {
    await initialize();
    await _storage.write(
      key: AppConstants.secureStorageKeyUserToken,
      value: authToken,
    );
    await _storage.write(
      key: AppConstants.secureStorageKeySessionDeviceFingerprint,
      value: deviceFingerprint,
    );

    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(
        key: AppConstants.secureStorageKeyUserRefreshToken,
        value: refreshToken,
      );
    }
  }

  Future<String?> readAuthToken() async {
    await initialize();
    return _storage.read(key: AppConstants.secureStorageKeyUserToken);
  }

  Future<String?> readRefreshToken() async {
    await initialize();
    return _storage.read(key: AppConstants.secureStorageKeyUserRefreshToken);
  }

  Future<String?> readSessionDeviceFingerprint() async {
    await initialize();
    return _storage.read(
      key: AppConstants.secureStorageKeySessionDeviceFingerprint,
    );
  }

  Future<void> writeAuthToken(String token) async {
    await initialize();
    await _storage.write(
      key: AppConstants.secureStorageKeyUserToken,
      value: token,
    );
  }

  Future<void> writeRefreshToken(String token) async {
    await initialize();
    await _storage.write(
      key: AppConstants.secureStorageKeyUserRefreshToken,
      value: token,
    );
  }

  Future<void> writeSessionDeviceFingerprint(String fingerprint) async {
    await initialize();
    await _storage.write(
      key: AppConstants.secureStorageKeySessionDeviceFingerprint,
      value: fingerprint,
    );
  }

  Future<void> storePin(String pin) async {
    await initialize();
    try {
      await _storage.write(
        key: AppConstants.secureStorageKeyUserPin,
        value: pin,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.sharedPrefKeyUserPin);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.sharedPrefKeyUserPin, pin);
    }
  }

  Future<String?> readPin() async {
    await initialize();
    try {
      final securePin = await _storage.read(
        key: AppConstants.secureStorageKeyUserPin,
      );
      if (securePin != null && securePin.isNotEmpty) {
        return securePin;
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final fallbackPin = prefs.getString(AppConstants.sharedPrefKeyUserPin);
    if (fallbackPin != null && fallbackPin.isNotEmpty) {
      return fallbackPin;
    }

    return null;
  }

  Future<void> clearPin() async {
    await initialize();
    try {
      await _storage.delete(key: AppConstants.secureStorageKeyUserPin);
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.sharedPrefKeyUserPin);
  }

  Future<bool> hasSessionBoundToFingerprint(String currentFingerprint) async {
    await initialize();
    final token = await readAuthToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    final storedFingerprint = await readSessionDeviceFingerprint();
    if (storedFingerprint == null || storedFingerprint.isEmpty) {
      await writeSessionDeviceFingerprint(currentFingerprint);
      return true;
    }

    return storedFingerprint == currentFingerprint;
  }

  Future<void> clearAuthSecrets() async {
    await initialize();
    await _storage.delete(key: AppConstants.secureStorageKeyUserToken);
    await _storage.delete(key: AppConstants.secureStorageKeyUserRefreshToken);
    await _storage.delete(
      key: AppConstants.secureStorageKeySessionDeviceFingerprint,
    );
    try {
      await _storage.delete(key: AppConstants.secureStorageKeyUserPin);
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.sharedPrefKeyUserPin);
  }

  Future<void> _migrateLegacyTokens() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = await _storage.read(
      key: AppConstants.secureStorageKeyUserToken,
    );
    final storedRefreshToken = await _storage.read(
      key: AppConstants.secureStorageKeyUserRefreshToken,
    );

    final legacyToken = prefs.getString(AppConstants.sharedPrefKeyUserToken);
    if ((storedToken == null || storedToken.isEmpty) &&
        legacyToken != null &&
        legacyToken.isNotEmpty) {
      await _storage.write(
        key: AppConstants.secureStorageKeyUserToken,
        value: legacyToken,
      );
    }

    final legacyRefreshToken = prefs.getString(
      AppConstants.sharedPrefKeyUserRefreshToken,
    );
    if ((storedRefreshToken == null || storedRefreshToken.isEmpty) &&
        legacyRefreshToken != null &&
        legacyRefreshToken.isNotEmpty) {
      await _storage.write(
        key: AppConstants.secureStorageKeyUserRefreshToken,
        value: legacyRefreshToken,
      );
    }

    await prefs.remove(AppConstants.sharedPrefKeyUserToken);
    await prefs.remove(AppConstants.sharedPrefKeyUserRefreshToken);
  }
}
