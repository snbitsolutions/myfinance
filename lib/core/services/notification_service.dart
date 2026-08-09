import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../models/notification_models.dart';
import '../repositories/notification_repository.dart';

class NotificationService implements NotificationRepository {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  @override
  Future<NotificationPreferences> getPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationPreferences(
      enabled:
          prefs.getBool(AppConstants.sharedPrefKeyNotificationsEnabled) ?? true,
      transactionAlerts:
          prefs.getBool(AppConstants.sharedPrefKeyTransactionAlerts) ?? true,
      loanUpdates: prefs.getBool(AppConstants.sharedPrefKeyLoanUpdates) ?? true,
      savingsReminders:
          prefs.getBool(AppConstants.sharedPrefKeySavingsReminders) ?? true,
      marketingUpdates:
          prefs.getBool(AppConstants.sharedPrefKeyMarketingUpdates) ?? false,
    );
  }

  @override
  Future<void> savePreferences(NotificationPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      AppConstants.sharedPrefKeyNotificationsEnabled,
      preferences.enabled,
    );
    await prefs.setBool(
      AppConstants.sharedPrefKeyTransactionAlerts,
      preferences.transactionAlerts,
    );
    await prefs.setBool(
      AppConstants.sharedPrefKeyLoanUpdates,
      preferences.loanUpdates,
    );
    await prefs.setBool(
      AppConstants.sharedPrefKeySavingsReminders,
      preferences.savingsReminders,
    );
    await prefs.setBool(
      AppConstants.sharedPrefKeyMarketingUpdates,
      preferences.marketingUpdates,
    );
  }

  @override
  Future<NotificationPreferencesResponse> getPreferencesResponse() async {
    return NotificationPreferencesResponse(preferences: await getPreferences());
  }

  @override
  Future<List<AppNotification>> getNotifications() async {
    final response = await getNotificationListResponse();
    return response.notifications;
  }

  @override
  Future<void> addNotification(AppNotification notification) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await _getStoredNotifications();
    final updated = [...existing, notification];
    await prefs.setString(
      AppConstants.sharedPrefKeyCustomNotifications,
      jsonEncode(updated.map((item) => item.toJson()).toList()),
    );
  }

  Future<List<AppNotification>> _getStoredNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(
      AppConstants.sharedPrefKeyCustomNotifications,
    );
    if (encoded == null || encoded.isEmpty) return const [];

    final decoded = jsonDecode(encoded);
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map>()
        .map(
          (item) => AppNotification.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  @override
  Future<NotificationListResponse> getNotificationListResponse() async {
    final prefs = await SharedPreferences.getInstance();
    final readIds =
        prefs.getStringList(AppConstants.sharedPrefKeyReadNotificationIds) ??
        const <String>[];
    final preferences = await getPreferences();

    final storedNotifications = await _getStoredNotifications();

    final notifications =
        [..._seedNotifications, ...storedNotifications]
            .where((notification) {
              if (!preferences.enabled) return false;
              switch (notification.type) {
                case AppNotificationType.transaction:
                  return preferences.transactionAlerts;
                case AppNotificationType.loan:
                  return preferences.loanUpdates;
                case AppNotificationType.savings:
                  return preferences.savingsReminders;
                case AppNotificationType.security:
                  return preferences.enabled;
                case AppNotificationType.promo:
                  return preferences.marketingUpdates;
              }
            })
            .map(
              (notification) => notification.copyWith(
                read: readIds.contains(notification.id),
              ),
            )
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return NotificationListResponse(
      notifications: notifications,
      unreadCount: notifications
          .where((notification) => !notification.read)
          .length,
    );
  }

  @override
  Future<int> getUnreadCount() async {
    final response = await getUnreadCountResponse();
    return response.unreadCount;
  }

  @override
  Future<NotificationUnreadCountResponse> getUnreadCountResponse() async {
    final response = await getNotificationListResponse();
    return NotificationUnreadCountResponse(unreadCount: response.unreadCount);
  }

  @override
  Future<void> markAsRead(String id) async {
    await markAsReadRequest(MarkNotificationReadRequest(notificationId: id));
  }

  @override
  Future<void> markAsReadRequest(MarkNotificationReadRequest request) async {
    final prefs = await SharedPreferences.getInstance();
    final readIds =
        prefs.getStringList(AppConstants.sharedPrefKeyReadNotificationIds) ??
        <String>[];
    if (!readIds.contains(request.notificationId)) {
      readIds.add(request.notificationId);
      await prefs.setStringList(
        AppConstants.sharedPrefKeyReadNotificationIds,
        readIds,
      );
    }
  }

  @override
  Future<void> markAllAsRead() async {
    await markAllAsReadRequest(const MarkAllNotificationsReadRequest());
  }

  @override
  Future<void> markAllAsReadRequest(
    MarkAllNotificationsReadRequest request,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final storedNotifications = await _getStoredNotifications();
    final allIds = [
      ..._seedNotifications,
      ...storedNotifications,
    ].map((notification) => notification.id).toList();
    await prefs.setStringList(
      AppConstants.sharedPrefKeyReadNotificationIds,
      allIds,
    );
  }

  IconData iconForType(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.transaction:
        return Icons.receipt_long_outlined;
      case AppNotificationType.loan:
        return Icons.account_balance_wallet_outlined;
      case AppNotificationType.savings:
        return Icons.savings_outlined;
      case AppNotificationType.security:
        return Icons.shield_outlined;
      case AppNotificationType.promo:
        return Icons.local_offer_outlined;
    }
  }

  Color colorForType(ThemeData theme, AppNotificationType type) {
    switch (type) {
      case AppNotificationType.transaction:
        return theme.colorScheme.primary;
      case AppNotificationType.loan:
        return theme.colorScheme.secondary;
      case AppNotificationType.savings:
        return const Color(0xFF1D7A46);
      case AppNotificationType.security:
        return const Color(0xFFB25E09);
      case AppNotificationType.promo:
        return const Color(0xFF0E7490);
    }
  }

  static final List<AppNotification> _seedNotifications = [
    AppNotification(
      id: 'txn_salary',
      title: 'Salary deposit confirmed',
      message: 'Your salary deposit of GHS 4,500.00 has been credited.',
      timestamp: DateTime(2026, 4, 25, 8, 45),
      type: AppNotificationType.transaction,
      read: false,
    ),
    AppNotification(
      id: 'loan_offer',
      title: 'Loan review update',
      message: 'Your latest loan request is being reviewed by our credit team.',
      timestamp: DateTime(2026, 4, 24, 17, 20),
      type: AppNotificationType.loan,
      read: false,
    ),
    AppNotification(
      id: 'savings_goal',
      title: 'Savings goal milestone',
      message: 'You have reached 72% of your Back-to-School savings target.',
      timestamp: DateTime(2026, 4, 24, 9, 15),
      type: AppNotificationType.savings,
      read: false,
    ),
    AppNotification(
      id: 'security_login',
      title: 'New sign-in detected',
      message: 'A secured sign-in was confirmed on your current device.',
      timestamp: DateTime(2026, 4, 23, 20, 5),
      type: AppNotificationType.security,
      read: true,
    ),
    AppNotification(
      id: 'promo_referral',
      title: 'Referral rewards available',
      message: 'Invite a colleague this week and earn bonus savings rewards.',
      timestamp: DateTime(2026, 4, 22, 12, 0),
      type: AppNotificationType.promo,
      read: true,
    ),
  ];
}
