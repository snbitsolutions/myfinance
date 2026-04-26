import '../models/notification_models.dart';

abstract class NotificationRepository {
  Future<NotificationPreferences> getPreferences();

  Future<NotificationPreferencesResponse> getPreferencesResponse();

  Future<void> savePreferences(NotificationPreferences preferences);

  Future<List<AppNotification>> getNotifications();

  Future<NotificationListResponse> getNotificationListResponse();

  Future<int> getUnreadCount();

  Future<NotificationUnreadCountResponse> getUnreadCountResponse();

  Future<void> markAsRead(String id);

  Future<void> markAsReadRequest(MarkNotificationReadRequest request);

  Future<void> markAllAsRead();

  Future<void> markAllAsReadRequest(MarkAllNotificationsReadRequest request);
}
