import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';
import '../../core/color_ext.dart';
import '../../core/models/notification_models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/notification_service.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _isLoading = true;
  NotificationPreferences _preferences = const NotificationPreferences(
    enabled: true,
    transactionAlerts: true,
    loanUpdates: true,
    savingsReminders: true,
    marketingUpdates: false,
  );
  List<AppNotification> _notifications = const [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  NotificationService get _notificationService => NotificationService.instance;

  Future<void> _loadData() async {
    final repository = ref.read(notificationRepositoryProvider);
    final preferences = await repository.getPreferences();
    final notifications = await repository.getNotifications();
    if (!mounted) return;
    setState(() {
      _preferences = preferences;
      _notifications = notifications;
      _isLoading = false;
    });
  }

  Future<void> _updatePreferences(NotificationPreferences preferences) async {
    final repository = ref.read(notificationRepositoryProvider);
    await repository.savePreferences(preferences);
    if (!mounted) return;
    setState(() => _preferences = preferences);
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.read) return;
    final repository = ref.read(notificationRepositoryProvider);
    await repository.markAsRead(notification.id);
    await _loadData();
  }

  Future<void> _markAllAsRead() async {
    final repository = ref.read(notificationRepositoryProvider);
    await repository.markAllAsRead();
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unreadCount = _notifications.where((item) => !item.read).length;

    return AppScaffold(
      title: 'Notifications',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppCard(
                    margin: EdgeInsets.zero,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withOpacitySafe(0.10),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _preferences.enabled
                                      ? Icons.notifications_active_rounded
                                      : Icons.notifications_off_outlined,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _preferences.enabled
                                          ? 'Alerts are active'
                                          : 'Alerts are paused',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      unreadCount == 0
                                          ? 'You are all caught up.'
                                          : '$unreadCount unread updates are waiting for you.',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withOpacitySafe(0.65),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              if (unreadCount > 0)
                                TextButton(
                                  onPressed: _markAllAsRead,
                                  child: const Text('Mark all read'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _StatusChip(
                                label: _preferences.enabled
                                    ? 'Enabled'
                                    : 'Paused',
                                color: _preferences.enabled
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.error,
                              ),
                              _StatusChip(
                                label: '${_notifications.length} total updates',
                                color: theme.colorScheme.secondary,
                              ),
                              _StatusChip(
                                label: '$unreadCount unread',
                                color: const Color(0xFF1D7A46),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Delivery Preferences',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  AppCard(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _PreferenceSwitchTile(
                          icon: Icons.notifications_active_outlined,
                          title: 'All notifications',
                          subtitle: 'Master switch for alerts and reminders',
                          value: _preferences.enabled,
                          onChanged: (value) => _updatePreferences(
                            _preferences.copyWith(enabled: value),
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: theme.colorScheme.outline.withOpacitySafe(
                            0.18,
                          ),
                        ),
                        _PreferenceSwitchTile(
                          icon: Icons.receipt_long_outlined,
                          title: 'Transaction alerts',
                          subtitle: 'Payments, deposits, and withdrawals',
                          value: _preferences.transactionAlerts,
                          onChanged: _preferences.enabled
                              ? (value) => _updatePreferences(
                                  _preferences.copyWith(
                                    transactionAlerts: value,
                                  ),
                                )
                              : null,
                        ),
                        Divider(
                          height: 1,
                          color: theme.colorScheme.outline.withOpacitySafe(
                            0.18,
                          ),
                        ),
                        _PreferenceSwitchTile(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'Loan updates',
                          subtitle: 'Approval progress and repayment reminders',
                          value: _preferences.loanUpdates,
                          onChanged: _preferences.enabled
                              ? (value) => _updatePreferences(
                                  _preferences.copyWith(loanUpdates: value),
                                )
                              : null,
                        ),
                        Divider(
                          height: 1,
                          color: theme.colorScheme.outline.withOpacitySafe(
                            0.18,
                          ),
                        ),
                        _PreferenceSwitchTile(
                          icon: Icons.savings_outlined,
                          title: 'Savings reminders',
                          subtitle: 'Goal progress and auto-save nudges',
                          value: _preferences.savingsReminders,
                          onChanged: _preferences.enabled
                              ? (value) => _updatePreferences(
                                  _preferences.copyWith(
                                    savingsReminders: value,
                                  ),
                                )
                              : null,
                        ),
                        Divider(
                          height: 1,
                          color: theme.colorScheme.outline.withOpacitySafe(
                            0.18,
                          ),
                        ),
                        _PreferenceSwitchTile(
                          icon: Icons.local_offer_outlined,
                          title: 'Offers and campaigns',
                          subtitle: 'Referral rewards and limited-time offers',
                          value: _preferences.marketingUpdates,
                          onChanged: _preferences.enabled
                              ? (value) => _updatePreferences(
                                  _preferences.copyWith(
                                    marketingUpdates: value,
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        'Recent Updates',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Tap an item to mark it as read',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacitySafe(
                            0.55,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_notifications.isEmpty)
                    AppCard(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'No notifications yet. New account activity will show up here.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else
                    ..._notifications.map(
                      (notification) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _NotificationTile(
                          notification: notification,
                          icon: _notificationService.iconForType(
                            notification.type,
                          ),
                          accentColor: _notificationService.colorForType(
                            theme,
                            notification.type,
                          ),
                          onTap: () => _markAsRead(notification),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _PreferenceSwitchTile extends StatelessWidget {
  const _PreferenceSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: onChanged == null
                ? theme.colorScheme.onSurface.withOpacitySafe(0.35)
                : theme.colorScheme.primary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  final AppNotification notification;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = notification.read
        ? theme.colorScheme.outline.withOpacitySafe(0.14)
        : accentColor.withOpacitySafe(0.32);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AppCard(
          margin: EdgeInsets.zero,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacitySafe(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accentColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: notification.read
                                      ? FontWeight.w600
                                      : FontWeight.w700,
                                ),
                              ),
                            ),
                            if (!notification.read)
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notification.message,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacitySafe(
                              0.7,
                            ),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _relativeTimeLabel(notification.timestamp),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacitySafe(
                              0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _relativeTimeLabel(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacitySafe(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
