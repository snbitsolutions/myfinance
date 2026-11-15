import 'package:adepa_teachers/core/constants/app_constants.dart';
import 'package:adepa_teachers/core/services/login_attempt_tracker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LoginAttemptTracker', () {
    late LoginAttemptTracker tracker;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      tracker = LoginAttemptTracker();
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
      await tracker.resetFailedAttempts('233501234567');

      expect(await tracker.getFailedAttempts('233501234567'), 0);
    });
  });
}
