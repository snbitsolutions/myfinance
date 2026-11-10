import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import 'user_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userProfileAsync = ref.watch(userProfileProvider);
    final isLoading = userProfileAsync.isLoading;
    final hasError = userProfileAsync.hasError;
    final profile = userProfileAsync.valueOrNull;
    final user = AppUser(
      name: _readProfileName(profile),
      email: _readProfileString(profile, 'email', ''),
      phone: _readProfileString(profile, 'phone', ''),
      accountNumber: _readProfileString(profile, 'account_number', ''),
      kycStatus: _parseKycStatus(profile?['kyc_status']),
    );

    Future<void> handleLogout() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Sign Out'),
          content: const Text(
            'Are you sure you want to sign out of your account?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              child: const Text('Sign Out'),
            ),
          ],
        ),
      );

      if (confirmed != true || !context.mounted) return;

      try {
        await ref.read(authProvider.notifier).logout();
        if (!context.mounted) return;
        context.go('/login');
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign out failed. Please try again.')),
        );
      }
    }

    void showSupportDialog() {
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Help & Support'),
          content: const Text(
            'Call support: ${AppConstants.supportPhoneNumber}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }

    void showAboutDialog() {
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('About Adepa Teachers'),
          content: const Text(
            'Version 1.0.0\n\nSecure personal finance management for everyday money decisions.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.colorScheme.primary, const Color(0xFFF6F8F7)],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Error banner
              if (hasError)
                Material(
                  color: theme.colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cloud_off_rounded,
                          size: 16,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Could not load profile data',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: theme.colorScheme.onErrorContainer,
                          ),
                          onPressed: () => ref.invalidate(userProfileProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              // Header with gradient background
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'More',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Account & preferences',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => context.go('/settings'),
                          icon: const Icon(
                            Icons.settings_outlined,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Profile Avatar Card
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          theme.colorScheme.primary,
                                          theme.colorScheme.secondary,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.colorScheme.primary
                                              .withValues(alpha: 0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: isLoading
                                          ? const SizedBox(
                                              width: 32,
                                              height: 32,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              _initialsFor(user.name),
                                              style: theme
                                                  .textTheme
                                                  .headlineMedium
                                                  ?.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                user.name.isEmpty
                                    ? 'Name unavailable'
                                    : user.name,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.phone.isEmpty
                                    ? 'Phone unavailable'
                                    : user.phone,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (user.accountNumber.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Acc: ${user.accountNumber}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade500,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => context.go('/profile/edit'),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Profile Details'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: theme.colorScheme.primary,
                                    side: BorderSide(
                                      color: theme.colorScheme.primary,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.wallet_outlined,
                            label: 'Wallet',
                            value: '—',
                            accent: theme.colorScheme.primary,
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.shield_outlined,
                            label: 'Security',
                            value: 'Protected',
                            accent: const Color(0xFF0F8E5D),
                            onTap: () => context.go('/set-pin?mode=change'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isTablet = constraints.maxWidth >= 900;

                    final accountSection = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _KYCStatusCard(user: user),
                        const SizedBox(height: 16),
                        _MenuCard(
                          items: [
                            _MenuItem(
                              icon: Icons.person_outline,
                              title: 'Profile Details',
                              subtitle: 'View your account information',
                              onTap: () => context.go('/profile/edit'),
                            ),
                            _MenuItem(
                              icon: Icons.badge_outlined,
                              title: 'KYC Verification',
                              subtitle: 'Complete your verification',
                              onTap: () => context.go('/kyc'),
                            ),
                          ],
                        ),
                      ],
                    );

                    final securitySection = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Security',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _MenuCard(
                          items: [
                            _MenuItem(
                              icon: Icons.lock_outline,
                              title: 'Security & PIN',
                              subtitle: 'Manage your security settings',
                              onTap: () => context.go('/set-pin?mode=change'),
                            ),
                            _MenuItem(
                              icon: Icons.notifications_outlined,
                              title: 'Notifications',
                              subtitle: 'Manage your alerts',
                              onTap: () => context.go('/notifications'),
                            ),
                          ],
                        ),
                      ],
                    );

                    final supportSection = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Support',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _MenuCard(
                          items: [
                            _MenuItem(
                              icon: Icons.help_outline,
                              title: 'Help & Support',
                              subtitle: 'Get help when you need it',
                              onTap: showSupportDialog,
                            ),
                            _MenuItem(
                              icon: Icons.info_outline,
                              title: 'About',
                              subtitle: 'Version 1.0.0',
                              onTap: showAboutDialog,
                            ),
                            _MenuItem(
                              icon: Icons.logout,
                              title: 'Logout',
                              subtitle: 'Sign out of your account',
                              onTap: handleLogout,
                              isDestructive: true,
                            ),
                          ],
                        ),
                      ],
                    );

                    final moreSections = isTablet
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 4, child: accountSection),
                              const SizedBox(width: 16),
                              Expanded(flex: 3, child: securitySection),
                              const SizedBox(width: 16),
                              Expanded(flex: 3, child: supportSection),
                            ],
                          )
                        : Column(
                            children: [
                              accountSection,
                              const SizedBox(height: 22),
                              securitySection,
                              const SizedBox(height: 22),
                              supportSection,
                              const SizedBox(height: 24),
                            ],
                          );

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: moreSections,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _initialsFor(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'U';
  return parts.take(2).map((part) => part.substring(0, 1)).join().toUpperCase();
}

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

String _readProfileName(Map<String, dynamic>? profile) {
  final firstName = _readProfileString(profile, 'first_name', '');
  final lastName = _readProfileString(profile, 'last_name', '');
  final combined = [
    firstName,
    lastName,
  ].where((value) => value.isNotEmpty).join(' ').trim();
  if (combined.isNotEmpty) return combined;

  for (final key in const [
    'name',
    'full_name',
    'fullName',
    'account_name',
    'accountName',
    'member_name',
    'memberName',
    'customer_name',
    'customerName',
    'display_name',
    'displayName',
  ]) {
    final value = _readProfileString(profile, key, '');
    if (value.isNotEmpty) return value;
  }
  return '';
}

KycStatus _parseKycStatus(Object? value) {
  final status = value?.toString().toLowerCase().trim();
  switch (status) {
    case 'verified':
      return KycStatus.verified;
    case 'pending':
    case 'in_review':
    case 'review':
      return KycStatus.pending;
    case 'not_started':
    case 'not-started':
    case 'unverified':
      return KycStatus.notStarted;
    default:
      return KycStatus.unavailable;
  }
}

// Helper Widgets
class _KYCStatusCard extends StatelessWidget {
  final AppUser user;

  const _KYCStatusCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVerified = user.kycStatus == KycStatus.verified;
    final statusColor = isVerified
        ? theme.colorScheme.primary
        : user.kycStatus == KycStatus.unavailable
        ? theme.colorScheme.outline
        : theme.colorScheme.error;
    final statusLabel = switch (user.kycStatus) {
      KycStatus.verified => 'Verified',
      KycStatus.pending => 'Pending',
      KycStatus.notStarted => 'Not started',
      KycStatus.unavailable => 'Unavailable',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isVerified ? Icons.verified_user : Icons.info_outline,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KYC Status',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          if (!isVerified)
            ElevatedButton(
              onPressed: () => context.go('/kyc'),
              style: ElevatedButton.styleFrom(
                backgroundColor: statusColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text('Verify'),
            ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
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

class _MenuCard extends StatelessWidget {
  final List<_MenuItem> items;

  const _MenuCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1)
              Divider(
                height: 1,
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.1),
              ),
          ],
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDestructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: color.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: color.withValues(alpha: 0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
