import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';

class PaymentHomeScreen extends ConsumerWidget {
  const PaymentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider);

    final profile = profileAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const <String, dynamic>{},
    );

    final accountName = (profile['name'] ?? profile['account_name'] ?? 'Your account')
        .toString()
        .trim();
    final resolvedName = accountName.isNotEmpty ? accountName : 'Your account';

    final imageUrl = _resolveProfileImageUrl(profile);
    final initials = resolvedName
        .split(RegExp(r'\s+'))
        .where((segment) => segment.isNotEmpty)
        .take(2)
        .map((segment) => segment[0].toUpperCase())
        .join();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _TopHeader(
                accountName: resolvedName,
                initials: initials,
                imageUrl: imageUrl,
              ),
              const SizedBox(height: 18),
              _PortfolioSummaryCard(),
              const SizedBox(height: 26),
              Row(
                children: [
                  Text(
                    'Product Categories',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A2A22),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF5EE),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '4 items',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF0B8F57),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _CategoryTile(
                icon: Icons.savings_rounded,
                iconColor: const Color(0xFF0B8F57),
                tint: const Color(0xFFEAF4EE),
                title: 'Savings',
                subtitle: 'All your savings accounts\nand balances',
                amount: 'GH₵ 72,400.00',
                count: '3 accounts',
                amountColor: const Color(0xFF0B8F57),
                onTap: () => context.go('/savings'),
              ),
              const SizedBox(height: 10),
              _CategoryTile(
                icon: Icons.pie_chart_rounded,
                iconColor: const Color(0xFFD49A1F),
                tint: const Color(0xFFF8F0E1),
                title: 'Shares',
                subtitle: 'Your shareholding and\nshare value',
                amount: 'GH₵ 31,200.00',
                count: '1 account',
                amountColor: const Color(0xFFD49A1F),
                onTap: () => context.go('/shares'),
              ),
              const SizedBox(height: 10),
              _CategoryTile(
                icon: Icons.trending_up_rounded,
                iconColor: const Color(0xFF2E8B57),
                tint: const Color(0xFFEAF5EE),
                title: 'Investments',
                subtitle: 'Fixed deposits and other\ninvestments',
                amount: 'GH₵ 80,650.00',
                count: '2 investments',
                amountColor: const Color(0xFF0B8F57),
                onTap: () => context.go('/investments'),
              ),
              const SizedBox(height: 10),
              _CategoryTile(
                icon: Icons.description_outlined,
                iconColor: const Color(0xFF3E7DBF),
                tint: const Color(0xFFEAF3FF),
                title: 'Loans',
                subtitle: 'Your active loans and\nrepayment status',
                amount: 'GH₵ 45,000.00',
                count: '1 active loan',
                amountColor: const Color(0xFF3E7DBF),
                onTap: () => context.go('/loans'),
              ),
              const SizedBox(height: 26),
              _GrowCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  final String accountName;
  final String initials;
  final String? imageUrl;

  const _TopHeader({
    required this.accountName,
    required this.initials,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final avatar = imageUrl != null && imageUrl!.trim().isNotEmpty
        ? ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              imageUrl!,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _InitialsAvatar(
                initials: initials,
              ),
            ),
          )
        : _InitialsAvatar(initials: initials);

    return Row(
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
                color: const Color(0xFF0E5A3E).withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: avatar,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                accountName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF183326),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'All your financial products\nin one place',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF5F6E66),
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Row(
          children: [
            _HeaderButton(
              icon: Icons.search_rounded,
              onTap: () => context.go('/transactions'),
            ),
            const SizedBox(width: 8),
            _HeaderButton(
              icon: Icons.tune_rounded,
              onTap: () => context.push('/profile'),
            ),
          ],
        ),
      ],
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

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _HeaderButton({required this.icon, this.onTap});

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
          child: Icon(icon, color: const Color(0xFF1E312A), size: 22),
        ),
      ),
    );
  }
}

class _PortfolioSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0E5A3E).withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -22,
            top: -10,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(70),
              ),
            ),
          ),
          Positioned(
            left: -18,
            bottom: -28,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFF9FD6B8).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(60),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Portfolio Summary',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.visibility_off_rounded, color: Colors.white, size: 12),
                        const SizedBox(width: 5),
                        Text(
                          'Hide',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Total balance',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
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
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9FD6B8).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.trending_up_rounded, color: Color(0xFF9FD6B8), size: 13),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SummaryTile(
                      label: 'Total Savings',
                      value: 'GH₵ 72,400.00',
                      sub: '3 accounts',
                      icon: Icons.savings_rounded,
                      iconColor: const Color(0xFFEAF5EE),
                      accent: const Color(0xFF9FD6B8),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryTile(
                      label: 'Total Shares',
                      value: 'GH₵ 31,200.00',
                      sub: '1 account',
                      icon: Icons.pie_chart_rounded,
                      iconColor: const Color(0xFFFCE9BF),
                      accent: const Color(0xFFF2C75C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SummaryTile(
                      label: 'Investments',
                      value: 'GH₵ 80,650.00',
                      sub: '2 vehicles',
                      icon: Icons.trending_up_rounded,
                      iconColor: const Color(0xFFEAF5EE),
                      accent: const Color(0xFF6CD29D),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryTile(
                      label: 'Loans',
                      value: 'GH₵ 45,000.00',
                      sub: '1 active',
                      icon: Icons.description_outlined,
                      iconColor: const Color(0xFFE7F0FF),
                      accent: const Color(0xFF9ABCF7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color iconColor;
  final Color accent;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.iconColor,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  sub,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color tint;
  final String title;
  final String subtitle;
  final String amount;
  final String count;
  final Color amountColor;
  final VoidCallback? onTap;

  const _CategoryTile({
    required this.icon,
    required this.iconColor,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.count,
    required this.amountColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final card = Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.white,
            tint.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EDE8), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: iconColor.withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tint,
                  tint.withValues(alpha: 0.82),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.14),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1C3029),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF66756B),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                count,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF5E6C66),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F7F5),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF7B8A7F),
              size: 20,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        splashColor: iconColor.withValues(alpha: 0.08),
        highlightColor: iconColor.withValues(alpha: 0.04),
        child: card,
      ),
    );
  }
}

class _GrowCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFDCEFE3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grow with Adepa',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF183326),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Explore more savings, investment\nand loan opportunities tailored\nfor you.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF425A4E),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E5A3E),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'Explore Opportunities',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Positioned(
                  bottom: 8,
                  left: 18,
                  child: _CoinStack(count: 4),
                ),
                Positioned(
                  bottom: 0,
                  right: 16,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E5A3E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.eco_rounded, color: Colors.white, size: 28),
                  ),
                ),
                Positioned(
                  bottom: 56,
                  right: 26,
                  child: Transform.rotate(
                    angle: -0.25,
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB6D9A0),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
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

class _CoinStack extends StatelessWidget {
  final int count;

  const _CoinStack({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        return Transform.translate(
          offset: Offset(index * 4.0, 0),
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFFEAC05F),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFCF9F2A), width: 2),
            ),
          ),
        );
      }),
    );
  }
}
