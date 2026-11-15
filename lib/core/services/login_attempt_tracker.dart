import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class LoginAttemptTracker {
  static const _keyPrefix = 'failedLoginAttempts_';

  final Future<SharedPreferences> Function() _preferencesProvider;

  LoginAttemptTracker({
    Future<SharedPreferences> Function()? preferencesProvider,
  }) : _preferencesProvider =
           preferencesProvider ?? SharedPreferences.getInstance;

  Future<int> getFailedAttempts(String phoneNumber) async {
    final preferences = await _preferencesProvider();
    return preferences.getInt(_keyFor(phoneNumber)) ?? 0;
  }

  Future<int> recordFailedAttempt(String phoneNumber) async {
    final preferences = await _preferencesProvider();
    final key = _keyFor(phoneNumber);
    final attempts = preferences.getInt(key) ?? 0;
    final updatedAttempts = attempts < AppConstants.maxFailedLoginAttempts
        ? attempts + 1
        : AppConstants.maxFailedLoginAttempts;
    final saved = await preferences.setInt(key, updatedAttempts);
    if (!saved) {
      throw StateError('Failed to save the login attempt count.');
    }
    return updatedAttempts;
  }

  Future<void> resetFailedAttempts(String phoneNumber) async {
    final preferences = await _preferencesProvider();
    final key = _keyFor(phoneNumber);
    final removed = await preferences.remove(key);
    if (!removed && preferences.containsKey(key)) {
      throw StateError('Failed to clear the login attempt count.');
    }
  }

  String _keyFor(String phoneNumber) {
    final normalizedPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (normalizedPhone.isEmpty) {
      throw ArgumentError.value(
        phoneNumber,
        'phoneNumber',
        'Must not be empty',
      );
    }

    final phoneHash = sha256.convert(utf8.encode(normalizedPhone));
    return '$_keyPrefix$phoneHash';
  }
}
