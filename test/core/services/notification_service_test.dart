import 'package:flutter_test/flutter_test.dart';
import 'package:adepa_teachers/core/constants/app_constants.dart';
import 'package:adepa_teachers/core/models/notification_models.dart';
import 'package:adepa_teachers/core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });

  test(
    'returns no notifications when master notifications are disabled',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        AppConstants.sharedPrefKeyNotificationsEnabled,
        false,
      );

      final response = await NotificationService.instance
          .getNotificationListResponse();

      expect(response.notifications, isEmpty);
      expect(response.unreadCount, 0);
    },
  );

  test('persists and returns newly created notifications', () async {
    await NotificationService.instance.addNotification(
      AppNotification(
        id: 'custom_test',
        title: 'Custom update',
        message: 'A new action created a notification.',
        timestamp: DateTime.now(),
        type: AppNotificationType.transaction,
        read: false,
      ),
    );

    final response = await NotificationService.instance
        .getNotificationListResponse();

    expect(
      response.notifications.any((item) => item.id == 'custom_test'),
      isTrue,
    );
  });

  test('filters notifications by category preferences', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.sharedPrefKeyNotificationsEnabled, true);
    await prefs.setBool(AppConstants.sharedPrefKeyTransactionAlerts, false);
    await prefs.setBool(AppConstants.sharedPrefKeyLoanUpdates, true);
    await prefs.setBool(AppConstants.sharedPrefKeySavingsReminders, true);
    await prefs.setBool(AppConstants.sharedPrefKeyMarketingUpdates, false);

    final response = await NotificationService.instance
        .getNotificationListResponse();

    expect(
      response.notifications.any(
        (item) => item.type == AppNotificationType.transaction,
      ),
      isFalse,
    );
    expect(
      response.notifications.any(
        (item) => item.type == AppNotificationType.promo,
      ),
      isFalse,
    );
    expect(
      response.notifications.any(
        (item) => item.type == AppNotificationType.loan,
      ),
      isTrue,
    );
  });
}
