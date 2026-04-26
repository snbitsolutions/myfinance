import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/services/notification_service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.isLoading) {
      return const _DashboardLoadingSkeleton();
    }

    if (!authState.isAuthenticated) {
      return const _DashboardContent(profile: _fallbackProfile);
    }

    final userProfileAsync = ref.watch(userProfileProvider);

    return userProfileAsync.when(
      loading: () => const _DashboardLoadingSkeleton(),
      error: (error, stack) =>
          const _DashboardContent(profile: _fallbackProfile),
      data: (profile) => _DashboardContent(profile: profile),
    );
  }
}

const Map<String, dynamic> _fallbackProfile = {
  'name': 'Steven Boadu',
  'branch': 'Accra Main',
  'account_number': '0123456789',
  'status': 'Active',
  'balance': 4500.50,
};

class _DashboardUi {
  static const cardStart = Color(0xFF2E8B57);
  static const cardEnd = Color(0xFF1A5C38);
  static const cardTextColor = Colors.white;

  static const contentHorizontalPadding = 16.0;
  static const topBackgroundOffset = 34.0;
  static const topBackgroundHeight = 250.0;
}

class _DashboardContent extends StatelessWidget {
  final Map<String, dynamic> profile;

  const _DashboardContent({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewData = _DashboardProfileViewData.fromProfile(profile);
    final firstName = viewData.accountName.trim().split(RegExp(r'\s+')).first;

    final quickActionsPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Quick Actions',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '4 services',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.45,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Tap a card to continue to a service',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 24 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.22),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const _QuickActions(),
            ),
          ),
        ),
      ],
    );

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 900;
          return Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: _DashboardUi.topBackgroundOffset,
                child: IgnorePointer(
                  child: SizedBox(
                    height: _DashboardUi.topBackgroundHeight,
                    child: CustomPaint(
                      painter: _ScaffoldCurvePainter(
                        color: theme.colorScheme.outline.withValues(
                          alpha: 0.45,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  _DashboardUi.contentHorizontalPadding,
                  12,
                  _DashboardUi.contentHorizontalPadding,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TopHeader(firstName: firstName),
                    const SizedBox(height: 16),
                    if (isTablet)
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: const Duration(milliseconds: 450),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, 16 * (1 - value)),
                                      child: child,
                                    ),
                                  );
                                },
                                child: _AccountInfoCard(viewData: viewData),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(flex: 5, child: quickActionsPanel),
                          ],
                        ),
                      )
                    else ...[
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 16 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: _AccountInfoCard(viewData: viewData),
                      ),
                      const SizedBox(height: 16),
                      Expanded(child: quickActionsPanel),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  final String firstName;

  const _TopHeader({required this.firstName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationService = NotificationService.instance;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, $firstName',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  'Your finances at a glance',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Secure',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => context.go('/notifications'),
          child: FutureBuilder<int>(
            future: notificationService.getUnreadCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;

              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.30),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      unreadCount > 0
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_none,
                      color: theme.colorScheme.onSurface,
                      size: 20,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Center(
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AccountInfoCard extends StatelessWidget {
  final _DashboardProfileViewData viewData;

  const _AccountInfoCard({required this.viewData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusKey = viewData.accountStatus.trim().toLowerCase();
    final statusLabel = viewData.accountStatus.trim().isEmpty
        ? 'Unknown'
        : '${viewData.accountStatus.trim()[0].toUpperCase()}${viewData.accountStatus.trim().substring(1).toLowerCase()}';
    final statusStyle = _AccountStatusStyle.fromStatusKey(statusKey);

    final initials = viewData.accountName
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .take(2)
        .map((e) => e.characters.first.toUpperCase())
        .join();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_DashboardUi.cardStart, _DashboardUi.cardEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Positioned(
              right: -20,
              top: -14,
              child: IgnorePointer(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
            ),
            Positioned(
              left: -28,
              bottom: -30,
              child: IgnorePointer(
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
            ),
            // Decorative curve arc
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _CardCurvePainter(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials.isEmpty ? 'U' : initials,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: _DashboardUi.cardTextColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              viewData.accountName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.1,
                                height: 1.05,
                                color: _DashboardUi.cardTextColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Account Holder',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.25,
                                color: _DashboardUi.cardTextColor.withValues(
                                  alpha: 0.78,
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Current Account · Gold Member',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: _DashboardUi.cardTextColor.withValues(
                                  alpha: 0.65,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _CardInfoTile(
                          icon: Icons.location_on_outlined,
                          label: 'Branch',
                          value: viewData.branchName,
                          textColor: _DashboardUi.cardTextColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CardInfoTile(
                          icon: Icons.credit_card_outlined,
                          label: 'Account',
                          value: _maskAccountNumber(viewData.accountNumber),
                          textColor: _DashboardUi.cardTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Transform.translate(
                      offset: const Offset(2, 3),
                      child: Wrap(
                        spacing: 8,
                        runAlignment: WrapAlignment.end,
                        alignment: WrapAlignment.end,
                        children: [
                          // Tier Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 13,
                                  color: Colors.amber.shade300,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Gold · 2% Cashback',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.amber.shade300,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Alert Badge (if needed)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: statusStyle.backgroundColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: statusStyle.borderColor,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  statusStyle.icon,
                                  size: 12,
                                  color: statusStyle.textColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  statusLabel,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: statusStyle.textColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color textColor;

  const _CardInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 14,
              color: textColor.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: textColor.withValues(alpha: 0.74),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor.withValues(alpha: 0.94),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardCurvePainter extends CustomPainter {
  final Color color;
  const _CardCurvePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Main sweeping arc across the card
    final path = Path()
      ..moveTo(0, size.height * 0.38)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.08,
        size.width * 0.68,
        size.height * 0.88,
        size.width,
        size.height * 0.55,
      );
    canvas.drawPath(path, paint);

    // Second arc near the top
    final paint2 = Paint()
      ..color = Colors.white.withValues(alpha: 0.13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path2 = Path()
      ..moveTo(size.width * 0.20, 0)
      ..cubicTo(
        size.width * 0.50,
        size.height * 0.25,
        size.width * 0.78,
        size.height * 0.04,
        size.width,
        size.height * 0.32,
      );
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant _CardCurvePainter old) => old.color != color;
}

class _ScaffoldCurvePainter extends CustomPainter {
  final Color color;

  const _ScaffoldCurvePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final path = Path()
      ..moveTo(size.width * 0.10, size.height * 0.02)
      ..lineTo(size.width * 0.10, size.height * 0.62)
      ..quadraticBezierTo(
        size.width * 0.10,
        size.height * 0.84,
        size.width * 0.30,
        size.height * 0.80,
      )
      ..lineTo(size.width * 0.98, size.height * 0.80);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ScaffoldCurvePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _DashboardProfileViewData {
  final String accountName;
  final String branchName;
  final String accountNumber;
  final String accountStatus;
  final double availableBalance;

  const _DashboardProfileViewData({
    required this.accountName,
    required this.branchName,
    required this.accountNumber,
    required this.accountStatus,
    required this.availableBalance,
  });

  factory _DashboardProfileViewData.fromProfile(Map<String, dynamic>? profile) {
    return _DashboardProfileViewData(
      accountName: _readProfileString(profile, 'name', 'John Doe'),
      branchName: _readProfileString(profile, 'branch', 'Accra Main'),
      accountNumber: _readProfileString(
        profile,
        'account_number',
        '0123456789',
      ),
      accountStatus: _readProfileString(profile, 'status', 'Active'),
      availableBalance: _readProfileDouble(profile, 'balance', 0),
    );
  }
}

class _AccountStatusStyle {
  final IconData icon;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;

  const _AccountStatusStyle({
    required this.icon,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  factory _AccountStatusStyle.fromStatusKey(String key) {
    if (key == 'active') {
      return _AccountStatusStyle(
        icon: Icons.check_circle,
        textColor: Colors.white,
        backgroundColor: Colors.white.withValues(alpha: 0.16),
        borderColor: Colors.white.withValues(alpha: 0.34),
      );
    }

    if (key == 'inactive' || key == 'disabled') {
      const accent = Color(0xFFFFB74D);
      return _AccountStatusStyle(
        icon: Icons.pause_circle,
        textColor: accent,
        backgroundColor: accent.withValues(alpha: 0.16),
        borderColor: accent.withValues(alpha: 0.52),
      );
    }

    if (key == 'pending') {
      const accent = Color(0xFFFFD54F);
      return _AccountStatusStyle(
        icon: Icons.schedule,
        textColor: accent,
        backgroundColor: accent.withValues(alpha: 0.16),
        borderColor: accent.withValues(alpha: 0.52),
      );
    }

    return _AccountStatusStyle(
      icon: Icons.info_outline,
      textColor: Colors.white.withValues(alpha: 0.90),
      backgroundColor: Colors.white.withValues(alpha: 0.12),
      borderColor: Colors.white.withValues(alpha: 0.28),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalGap = 12.0;
        const verticalGap = 12.0;
        final itemWidth = (constraints.maxWidth - horizontalGap) / 2;

        Widget buildTile(_QuickActionItem item) {
          return SizedBox(
            width: itemWidth,
            child: AspectRatio(
              aspectRatio: 1.28,
              child: _QuickAction(
                icon: item.icon,
                label: item.label,
                accentColor: item.resolveAccentColor(theme),
                onTap: () => context.go(item.route),
              ),
            ),
          );
        }

        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Wrap(
            spacing: horizontalGap,
            runSpacing: verticalGap,
            children: _quickActionItems.take(4).map(buildTile).toList(),
          ),
        );
      },
    );
  }
}

class _QuickActionItem {
  final IconData icon;
  final String label;
  final String route;
  final Color? accentColor;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.route,
    this.accentColor,
  });

  Color resolveAccentColor(ThemeData theme) {
    return accentColor ?? theme.colorScheme.primary;
  }
}

const List<_QuickActionItem> _quickActionItems = [
  _QuickActionItem(
    icon: Icons.savings_outlined,
    label: 'Savings',
    route: '/savings/types',
    accentColor: Color(0xFF2E8B57),
  ),
  _QuickActionItem(
    icon: Icons.pie_chart_outline,
    label: 'Shares',
    route: '/shares',
    accentColor: Color(0xFF0E8F87),
  ),
  _QuickActionItem(
    icon: Icons.trending_up,
    label: 'Investment',
    route: '/investment',
    accentColor: Color(0xFF1F7AE0),
  ),
  _QuickActionItem(
    icon: Icons.account_balance_outlined,
    label: 'Loans',
    route: '/loans',
    accentColor: Color(0xFFCC7A00),
  ),
];

String _readProfileString(
  Map<String, dynamic>? profile,
  String key,
  String fallback,
) {
  final value = profile?[key];
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return fallback;
}

double _readProfileDouble(
  Map<String, dynamic>? profile,
  String key,
  double fallback,
) {
  final value = profile?[key];
  if (value is num) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value.trim());
    if (parsed != null) return parsed;
  }
  return fallback;
}

String _maskAccountNumber(String accountNumber) {
  final trimmed = accountNumber.trim();
  if (trimmed.length <= 4) return trimmed;
  final visible = trimmed.substring(trimmed.length - 4);
  final hiddenCount = trimmed.length - 4;
  final masked = List.generate(hiddenCount, (_) => '•').join();
  return '$masked$visible';
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback? onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = onTap == null;
    final surfaceTint = theme.colorScheme.surface;
    return Opacity(
      opacity: disabled ? 0.38 : 1.0,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: surfaceTint,
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor.withValues(alpha: 0.10),
                  surfaceTint,
                  surfaceTint,
                ],
              ),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.18),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accentColor.withValues(alpha: 0.22),
                            accentColor.withValues(alpha: 0.10),
                          ],
                        ),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.18),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(icon, size: 24, color: accentColor),
                    ),
                    const Spacer(),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  label,
                  textAlign: TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardLoadingSkeleton extends StatelessWidget {
  const _DashboardLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SkeletonBox(height: 26, width: 170),
            const SizedBox(height: 8),
            _SkeletonBox(
              height: 14,
              width: 150,
              color: theme.colorScheme.outline.withValues(alpha: 0.18),
            ),
            const SizedBox(height: 18),
            const _SkeletonBox(height: 220, width: double.infinity),
            const SizedBox(height: 22),
            const _SkeletonBox(height: 18, width: 120),
            const SizedBox(height: 14),
            Expanded(
              child: Wrap(
                spacing: 14,
                runSpacing: 14,
                children: List.generate(
                  4,
                  (_) => const SizedBox(
                    width: 160,
                    child: AspectRatio(
                      aspectRatio: 1.12,
                      child: _SkeletonBox(
                        height: double.infinity,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double height;
  final double width;
  final Color? color;

  const _SkeletonBox({required this.height, required this.width, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.outline.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
