import 'package:adepa_teachers/core/constants/app_constants.dart';
import 'package:adepa_teachers/core/services/login_attempt_tracker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LoginAttemptTracker', () {
    late LoginAttemptTracker tracker;
    late DateTime now;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      now = DateTime(2026, 11, 11, 11);
      tracker = LoginAttemptTracker(now: () => now);
    });

    test(
      'locks after three failed attempts and caps further increments',
      () async {
        expect(await tracker.getFailedAttempts('233501234567'), 0);

        expect(await tracker.recordFailedAttempt('233501234567'), 1);
        expect(await tracker.recordFailedAttempt('233501234567'), 2);
        expect(await tracker.recordFailedAttempt('233501234567'), 3);
        expect(
          await tracker.recordFailedAttempt('233501234567'),
          AppConstants.maxFailedLoginAttempts,
        );
        expect(
          await tracker.getLockoutRemaining('233501234567'),
          LoginAttemptTracker.lockoutDuration,
        );
      },
    );

    test('expires the temporary lock after two minutes', () async {
      await tracker.recordFailedAttempt('233501234567');
      await tracker.recordFailedAttempt('233501234567');
      await tracker.recordFailedAttempt('233501234567');

      now = now.add(const Duration(minutes: 2));

      expect(await tracker.getFailedAttempts('233501234567'), 0);
      expect(await tracker.getLockoutRemaining('233501234567'), isNull);
      expect(await tracker.isPermanentlyLocked('233501234567'), isFalse);
    });

    test(
      'starts a two-minute cooldown for an existing locked account',
      () async {
        await tracker.recordFailedAttempt('233501234567');
        await tracker.recordFailedAttempt('233501234567');
        await tracker.recordFailedAttempt('233501234567');

        final preferences = await SharedPreferences.getInstance();
        final lockoutKey = preferences.getKeys().singleWhere(
          (key) => key.startsWith('loginAttemptLockoutUntil_'),
        );
        await preferences.remove(lockoutKey);

        expect(await tracker.getFailedAttempts('233501234567'), 3);
        expect(
          await tracker.getLockoutRemaining('233501234567'),
          LoginAttemptTracker.lockoutDuration,
        );

        now = now.add(const Duration(minutes: 2));
        expect(await tracker.getFailedAttempts('233501234567'), 0);
      },
    );

    test(
      'permanently locks after the first wrong attempt post-cooldown',
      () async {
        await tracker.recordFailedAttempt('233501234567');
        await tracker.recordFailedAttempt('233501234567');
        await tracker.recordFailedAttempt('233501234567');
        now = now.add(const Duration(minutes: 2));

        expect(await tracker.recordFailedAttempt('233501234567'), 3);
        expect(await tracker.isPermanentlyLocked('233501234567'), isTrue);
        expect(await tracker.getLockoutRemaining('233501234567'), isNull);
        expect(await tracker.recordFailedAttempt('233501234567'), 3);
      },
    );

    test('tracks attempts separately for each phone number', () async {
      await tracker.recordFailedAttempt('233501234567');

      expect(await tracker.getFailedAttempts('233501234567'), 1);
      expect(await tracker.getFailedAttempts('233501234568'), 0);
    });

    test('normalizes phone punctuation before tracking', () async {
      await tracker.recordFailedAttempt('+233 50 123 4567');

      expect(await tracker.getFailedAttempts('233501234567'), 1);
    });

    test('clears the stored attempts for the phone number', () async {
      await tracker.recordFailedAttempt('233501234567');
      await tracker.recordFailedAttempt('233501234567');
      await tracker.recordFailedAttempt('233501234567');
      now = now.add(const Duration(minutes: 2));
      await tracker.recordFailedAttempt('233501234567');
      await tracker.resetFailedAttempts('233501234567');

      expect(await tracker.getFailedAttempts('233501234567'), 0);
      expect(await tracker.getLockoutRemaining('233501234567'), isNull);
      expect(await tracker.isPermanentlyLocked('233501234567'), isFalse);
    });
  });
}
