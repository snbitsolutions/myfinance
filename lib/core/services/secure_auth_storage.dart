import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../exceptions/app_exceptions.dart';

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
    await _storage.delete(
      key: AppConstants.secureStorageKeyDeviceVerifiedSession,
    );
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

  Future<void> storeDeviceVerifiedSession({
    required String deviceFingerprint,
  }) async {
    await initialize();
    await _storage.delete(key: AppConstants.secureStorageKeyUserToken);
    await _storage.delete(key: AppConstants.secureStorageKeyUserRefreshToken);
    await _storage.write(
      key: AppConstants.secureStorageKeySessionDeviceFingerprint,
      value: deviceFingerprint,
    );
    await _storage.write(
      key: AppConstants.secureStorageKeyDeviceVerifiedSession,
      value: 'true',
    );
  }

  Future<bool> hasDeviceVerifiedSessionBoundToFingerprint(
    String currentFingerprint,
  ) async {
    await initialize();
    final marker = await _storage.read(
      key: AppConstants.secureStorageKeyDeviceVerifiedSession,
    );
    final storedFingerprint = await readSessionDeviceFingerprint();
    return marker == 'true' &&
        storedFingerprint != null &&
        storedFingerprint.isNotEmpty &&
        storedFingerprint == currentFingerprint;
  }

  Future<bool> hasAuthenticatedSessionBoundToFingerprint(
    String currentFingerprint,
  ) async {
    final token = await readAuthToken();
    if (token != null && token.isNotEmpty) {
      return hasSessionBoundToFingerprint(currentFingerprint);
    }
    return hasDeviceVerifiedSessionBoundToFingerprint(currentFingerprint);
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

  Future<String?> readDeviceInstallationId() async {
    await initialize();
    return _storage.read(key: AppConstants.secureStorageKeyDeviceInstallId);
  }

  Future<void> writeDeviceInstallationId(String installationId) async {
    await initialize();
    await _storage.write(
      key: AppConstants.secureStorageKeyDeviceInstallId,
      value: installationId,
    );
  }

  Future<void> storePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.sharedPrefKeyUserPin);
    try {
      await initialize();
      await _storage.write(
        key: AppConstants.secureStorageKeyUserPin,
        value: pin,
      );
    } catch (error) {
      throw CacheException(
        message: 'Your PIN could not be stored securely. Please try again.',
        originalException: error,
      );
    }
  }

  Future<String?> readPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.sharedPrefKeyUserPin);
    try {
      await initialize();
      final securePin = await _storage.read(
        key: AppConstants.secureStorageKeyUserPin,
      );
      if (securePin != null && securePin.isNotEmpty) {
        return securePin;
      }
    } catch (error) {
      throw CacheException(
        message: 'Your PIN could not be read securely. Please try again.',
        originalException: error,
      );
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
      return false;
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
    await _storage.delete(
      key: AppConstants.secureStorageKeyDeviceVerifiedSession,
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
    await prefs.remove(AppConstants.sharedPrefKeyUserPin);
  }
}
