import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/balance_card_shell.dart';
import '../../core/providers/app_providers.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const <String, dynamic>{},
    );

    final accountName =
        (profile['name'] ??
                profile['account_name'] ??
                profile['first_name'] ??
                'Your account')
            .toString()
            .trim();
    final resolvedName = accountName.isNotEmpty ? accountName : 'Your account';
    final imageUrl = _resolveProfileImageUrl(profile)?.trim();
    final initials = resolvedName
        .split(RegExp(r'\s+'))
        .where((segment) => segment.isNotEmpty)
        .take(2)
        .map((segment) => segment[0].toUpperCase())
        .join();

    final products = [
      _ProductCard(
        title: 'Savings',
        subtitle: 'All your savings accounts',
        amount: 'GH₵ 72,400.00',
        icon: Icons.savings_rounded,
        accent: const Color(0xFF0C8B5A),
        tint: const Color(0xFFEAF5EE),
        onTap: () => context.go('/savings'),
      ),
      _ProductCard(
        title: 'Shares',
        subtitle: 'Your equity portfolio',
        amount: 'GH₵ 28,350.00',
        icon: Icons.pie_chart_rounded,
        accent: const Color(0xFF0E8F87),
        tint: const Color(0xFFE8F9F7),
        onTap: () => context.go('/shares'),
      ),
      _ProductCard(
        title: 'Investments',
        subtitle: 'Fixed deposits and more',
        amount: 'GH₵ 80,650.00',
        icon: Icons.trending_up_rounded,
        accent: const Color(0xFF0C8B5A),
        tint: const Color(0xFFEAF5EE),
        onTap: () => context.go('/investments'),
      ),
      _ProductCard(
        title: 'Loans',
        subtitle: 'Active loans and repayments',
        amount: 'GH₵ 45,000.00',
        icon: Icons.receipt_long_rounded,
        accent: const Color(0xFF2F7DEB),
        tint: const Color(0xFFEAF3FF),
        onTap: () => context.go('/loans'),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E5A3E),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF0E5A3E,
                          ).withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              imageUrl,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _InitialsAvatar(initials: initials),
                            ),
                          )
                        : _InitialsAvatar(initials: initials),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good morning',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: const Color(0xFF5F6E66),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          resolvedName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1B2A24),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _NotificationButton(
                        count: 3,
                        onTap: () => context.go('/notifications'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0E5A3E),
                      Color(0xFF123D2D),
                      Color(0xFF0E5A3E),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0E5A3E).withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    const Positioned(
                      top: -8,
                      right: -4,
                      child: AdepaLogoBadge(size: 112),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Portfolio Overview',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 58),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Total balance',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'GH₵ 229,250.00',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF9FD6B8,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.trending_up_rounded,
                                    color: Color(0xFF9FD6B8),
                                    size: 13,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '+ 12.4%',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: const Color(0xFF9FD6B8),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'vs last month',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    'Products',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1B2A24),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF5EE),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${products.length} items',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF0B8F57),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...products,
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const _NotificationButton({required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDBE2DD)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF1E312A),
                size: 22,
              ),
              if (count > 0)
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0E5A3E),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
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
}

class _InitialsAvatar extends StatelessWidget {
  final String initials;

  const _InitialsAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        initials.isEmpty ? 'A' : initials,
        style: theme.textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final IconData icon;
  final Color accent;
  final Color tint;
  final VoidCallback onTap;

  const _ProductCard({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    required this.accent,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5EAE6)),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              top: 8,
              right: 8,
              bottom: 8,
              child: IgnorePointer(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AdepaLogoBadge(size: 92, color: accent, opacity: 0.24),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: accent, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1B2A24),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6A7A72),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amount,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF1B2A24),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String? _resolveProfileImageUrl(Map<String, dynamic> profile) {
  const keys = [
    'avatar',
    'avatar_url',
    'profile_image',
    'profile_image_url',
    'image_url',
    'photo_url',
    'picture',
    'photo',
    'profile_picture',
    'profilePicture',
  ];

  for (final key in keys) {
    final value = profile[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }

  return null;
}
