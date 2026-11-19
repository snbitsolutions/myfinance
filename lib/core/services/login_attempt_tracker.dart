import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class LoginAttemptTracker {
  static const Duration lockoutDuration = Duration(minutes: 2);
  static const _keyPrefix = 'failedLoginAttempts_';
  static const _lockoutKeyPrefix = 'loginAttemptLockoutUntil_';
  static const _permanentLockKeyPrefix = 'loginAttemptPermanentlyLocked_';

  final Future<SharedPreferences> Function() _preferencesProvider;
  final DateTime Function() _now;

  LoginAttemptTracker({
    Future<SharedPreferences> Function()? preferencesProvider,
    DateTime Function()? now,
  }) : _preferencesProvider =
           preferencesProvider ?? SharedPreferences.getInstance,
       _now = now ?? DateTime.now;

  Future<int> getFailedAttempts(String phoneNumber) async {
    final preferences = await _preferencesProvider();
    final key = _keyFor(phoneNumber);
    if (preferences.getBool(_permanentLockKeyFor(phoneNumber)) ?? false) {
      return AppConstants.maxFailedLoginAttempts;
    }

    final attempts = preferences.getInt(key) ?? 0;
    if (attempts < AppConstants.maxFailedLoginAttempts) return attempts;

    final lockoutKey = _lockoutKeyFor(phoneNumber);
    var lockoutUntil = preferences.getInt(lockoutKey);
    if (lockoutUntil == null) {
      lockoutUntil = _now().add(lockoutDuration).millisecondsSinceEpoch;
      final saved = await preferences.setInt(lockoutKey, lockoutUntil);
      if (!saved) {
        throw StateError('Failed to save the login lockout expiry.');
      }
    }

    if (lockoutUntil <= _now().millisecondsSinceEpoch) {
      return 0;
    }

    return AppConstants.maxFailedLoginAttempts;
  }

  Future<bool> isPermanentlyLocked(String phoneNumber) async {
    final preferences = await _preferencesProvider();
    return preferences.getBool(_permanentLockKeyFor(phoneNumber)) ?? false;
  }

  Future<Duration?> getLockoutRemaining(String phoneNumber) async {
    final attempts = await getFailedAttempts(phoneNumber);
    if (attempts < AppConstants.maxFailedLoginAttempts) return null;
    if (await isPermanentlyLocked(phoneNumber)) return null;

    final preferences = await _preferencesProvider();
    final lockoutUntil = preferences.getInt(_lockoutKeyFor(phoneNumber));
    if (lockoutUntil == null) return null;

    final remaining = DateTime.fromMillisecondsSinceEpoch(
      lockoutUntil,
    ).difference(_now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Future<int> recordFailedAttempt(String phoneNumber) async {
    if (await isPermanentlyLocked(phoneNumber)) {
      return AppConstants.maxFailedLoginAttempts;
    }

    final preferences = await _preferencesProvider();
    final key = _keyFor(phoneNumber);
    final attempts = preferences.getInt(key) ?? 0;
    if (attempts >= AppConstants.maxFailedLoginAttempts) {
      final lockoutUntil = preferences.getInt(_lockoutKeyFor(phoneNumber));
      if (lockoutUntil == null) {
        final saved = await preferences.setInt(
          _lockoutKeyFor(phoneNumber),
          _now().add(lockoutDuration).millisecondsSinceEpoch,
        );
        if (!saved) {
          throw StateError('Failed to save the login lockout expiry.');
        }
        return AppConstants.maxFailedLoginAttempts;
      }
      if (lockoutUntil > _now().millisecondsSinceEpoch) {
        return AppConstants.maxFailedLoginAttempts;
      }

      final locked = await preferences.setBool(
        _permanentLockKeyFor(phoneNumber),
        true,
      );
      if (!locked) {
        throw StateError('Failed to save the permanent login lock.');
      }
      return AppConstants.maxFailedLoginAttempts;
    }

    final updatedAttempts = attempts + 1;
    final saved = await preferences.setInt(key, updatedAttempts);
    if (!saved) {
      throw StateError('Failed to save the login attempt count.');
    }
    if (updatedAttempts >= AppConstants.maxFailedLoginAttempts) {
      final lockoutSaved = await preferences.setInt(
        _lockoutKeyFor(phoneNumber),
        _now().add(lockoutDuration).millisecondsSinceEpoch,
      );
      if (!lockoutSaved) {
        await preferences.remove(key);
        throw StateError('Failed to save the login lockout expiry.');
      }
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
    final lockoutKey = _lockoutKeyFor(phoneNumber);
    final lockoutRemoved = await preferences.remove(lockoutKey);
    if (!lockoutRemoved && preferences.containsKey(lockoutKey)) {
      throw StateError('Failed to clear the login lockout expiry.');
    }
    final permanentLockKey = _permanentLockKeyFor(phoneNumber);
    final permanentLockRemoved = await preferences.remove(permanentLockKey);
    if (!permanentLockRemoved && preferences.containsKey(permanentLockKey)) {
      throw StateError('Failed to clear the permanent login lock.');
    }
  }

  String _keyFor(String phoneNumber) {
    return '$_keyPrefix${_phoneHash(phoneNumber)}';
  }

  String _lockoutKeyFor(String phoneNumber) {
    return '$_lockoutKeyPrefix${_phoneHash(phoneNumber)}';
  }

  String _permanentLockKeyFor(String phoneNumber) {
    return '$_permanentLockKeyPrefix${_phoneHash(phoneNumber)}';
  }

  String _phoneHash(String phoneNumber) {
    final normalizedPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (normalizedPhone.isEmpty) {
      throw ArgumentError.value(
        phoneNumber,
        'phoneNumber',
        'Must not be empty',
      );
    }

    return sha256.convert(utf8.encode(normalizedPhone)).toString();
  }
}
