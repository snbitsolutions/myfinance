class NotificationPreferences {
  const NotificationPreferences({
    required this.enabled,
    required this.transactionAlerts,
    required this.loanUpdates,
    required this.savingsReminders,
    required this.marketingUpdates,
  });

  final bool enabled;
  final bool transactionAlerts;
  final bool loanUpdates;
  final bool savingsReminders;
  final bool marketingUpdates;

  NotificationPreferences copyWith({
    bool? enabled,
    bool? transactionAlerts,
    bool? loanUpdates,
    bool? savingsReminders,
    bool? marketingUpdates,
  }) {
    return NotificationPreferences(
      enabled: enabled ?? this.enabled,
      transactionAlerts: transactionAlerts ?? this.transactionAlerts,
      loanUpdates: loanUpdates ?? this.loanUpdates,
      savingsReminders: savingsReminders ?? this.savingsReminders,
      marketingUpdates: marketingUpdates ?? this.marketingUpdates,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'transactionAlerts': transactionAlerts,
      'loanUpdates': loanUpdates,
      'savingsReminders': savingsReminders,
      'marketingUpdates': marketingUpdates,
    };
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      enabled: json['enabled'] as bool? ?? true,
      transactionAlerts: json['transactionAlerts'] as bool? ?? true,
      loanUpdates: json['loanUpdates'] as bool? ?? true,
      savingsReminders: json['savingsReminders'] as bool? ?? true,
      marketingUpdates: json['marketingUpdates'] as bool? ?? false,
    );
  }
}

enum AppNotificationType { transaction, loan, savings, security, promo }

extension AppNotificationTypeX on AppNotificationType {
  String get apiValue {
    switch (this) {
      case AppNotificationType.transaction:
        return 'transaction';
      case AppNotificationType.loan:
        return 'loan';
      case AppNotificationType.savings:
        return 'savings';
      case AppNotificationType.security:
        return 'security';
      case AppNotificationType.promo:
        return 'promo';
    }
  }

  static AppNotificationType fromApiValue(String? value) {
    return AppNotificationType.values.firstWhere(
      (type) => type.apiValue == value,
      orElse: () => AppNotificationType.security,
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    required this.read,
    this.referenceId,
    this.route,
    this.metadata = const {},
  });

  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final AppNotificationType type;
  final bool read;
  final String? referenceId;
  final String? route;
  final Map<String, dynamic> metadata;

  AppNotification copyWith({
    bool? read,
    String? referenceId,
    String? route,
    Map<String, dynamic>? metadata,
  }) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      timestamp: timestamp,
      type: type,
      read: read ?? this.read,
      referenceId: referenceId ?? this.referenceId,
      route: route ?? this.route,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type.apiValue,
      'read': read,
      'referenceId': referenceId,
      'route': route,
      'metadata': metadata,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      type: AppNotificationTypeX.fromApiValue(json['type'] as String?),
      read: json['read'] as bool? ?? false,
      referenceId: json['referenceId'] as String?,
      route: json['route'] as String?,
      metadata:
          (json['metadata'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value),
          ) ??
          const {},
    );
  }
}

class NotificationListResponse {
  const NotificationListResponse({
    required this.notifications,
    required this.unreadCount,
    this.nextCursor,
  });

  final List<AppNotification> notifications;
  final int unreadCount;
  final String? nextCursor;

  Map<String, dynamic> toJson() {
    return {
      'notifications': notifications.map((item) => item.toJson()).toList(),
      'unreadCount': unreadCount,
      'nextCursor': nextCursor,
    };
  }

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    return NotificationListResponse(
      notifications: (json['notifications'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => AppNotification.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      nextCursor: json['nextCursor'] as String?,
    );
  }
}

class NotificationUnreadCountResponse {
  const NotificationUnreadCountResponse({required this.unreadCount});

  final int unreadCount;

  Map<String, dynamic> toJson() {
    return {'unreadCount': unreadCount};
  }

  factory NotificationUnreadCountResponse.fromJson(Map<String, dynamic> json) {
    return NotificationUnreadCountResponse(
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class MarkNotificationReadRequest {
  const MarkNotificationReadRequest({required this.notificationId});

  final String notificationId;

  Map<String, dynamic> toJson() {
    return {'notificationId': notificationId};
  }
}

class MarkAllNotificationsReadRequest {
  const MarkAllNotificationsReadRequest();

  Map<String, dynamic> toJson() {
    return const {};
  }
}

class UpdateNotificationPreferencesRequest {
  const UpdateNotificationPreferencesRequest({required this.preferences});

  final NotificationPreferences preferences;

  Map<String, dynamic> toJson() {
    return {'preferences': preferences.toJson()};
  }
}

class NotificationPreferencesResponse {
  const NotificationPreferencesResponse({required this.preferences});

  final NotificationPreferences preferences;

  Map<String, dynamic> toJson() {
    return {'preferences': preferences.toJson()};
  }

  factory NotificationPreferencesResponse.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesResponse(
      preferences: NotificationPreferences.fromJson(
        Map<String, dynamic>.from(
          json['preferences'] as Map? ?? const <String, dynamic>{},
        ),
      ),
    );
  }
}
