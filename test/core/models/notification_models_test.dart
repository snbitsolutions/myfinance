import 'package:adepa_teachers/core/models/notification_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationPreferences', () {
    test('serializes and deserializes consistently', () {
      const preferences = NotificationPreferences(
        enabled: true,
        transactionAlerts: true,
        loanUpdates: false,
        savingsReminders: true,
        marketingUpdates: false,
      );

      final json = preferences.toJson();
      final parsed = NotificationPreferences.fromJson(json);

      expect(parsed.enabled, isTrue);
      expect(parsed.transactionAlerts, isTrue);
      expect(parsed.loanUpdates, isFalse);
      expect(parsed.savingsReminders, isTrue);
      expect(parsed.marketingUpdates, isFalse);
    });
  });

  group('AppNotification', () {
    test('serializes and deserializes consistently', () {
      final notification = AppNotification(
        id: 'loan_123',
        title: 'Loan approved',
        message: 'Your loan has been approved.',
        timestamp: DateTime(2026, 4, 25, 11, 30),
        type: AppNotificationType.loan,
        read: false,
        referenceId: 'LN-123',
        route: '/loan-detail',
        metadata: const {'priority': 'high'},
      );

      final json = notification.toJson();
      final parsed = AppNotification.fromJson(json);

      expect(parsed.id, notification.id);
      expect(parsed.type, AppNotificationType.loan);
      expect(parsed.referenceId, 'LN-123');
      expect(parsed.route, '/loan-detail');
      expect(parsed.metadata['priority'], 'high');
    });
  });

  group('NotificationListResponse', () {
    test('round-trips notification collections', () {
      final response = NotificationListResponse(
        notifications: [
          AppNotification(
            id: 'txn_1',
            title: 'Deposit received',
            message: 'GHS 150.00 has been credited.',
            timestamp: DateTime(2026, 4, 25, 8, 0),
            type: AppNotificationType.transaction,
            read: false,
          ),
        ],
        unreadCount: 1,
        nextCursor: 'cursor_2',
      );

      final parsed = NotificationListResponse.fromJson(response.toJson());

      expect(parsed.unreadCount, 1);
      expect(parsed.notifications, hasLength(1));
      expect(parsed.notifications.first.type, AppNotificationType.transaction);
      expect(parsed.nextCursor, 'cursor_2');
    });
  });

  group('Notification contract requests', () {
    test('mark read request serializes notification id', () {
      const request = MarkNotificationReadRequest(notificationId: 'notif_7');

      expect(request.toJson(), {'notificationId': 'notif_7'});
    });

    test('preferences request nests preferences payload', () {
      const request = UpdateNotificationPreferencesRequest(
        preferences: NotificationPreferences(
          enabled: false,
          transactionAlerts: true,
          loanUpdates: true,
          savingsReminders: false,
          marketingUpdates: false,
        ),
      );

      expect(request.toJson()['preferences'], isA<Map<String, dynamic>>());
      expect(
        (request.toJson()['preferences'] as Map<String, dynamic>)['enabled'],
        isFalse,
      );
    });
  });
}
