import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/balance_card_shell.dart';
import '../../core/providers/app_providers.dart';

String _timeBasedGreeting(DateTime time) {
  if (time.hour < 12) return 'Good morning';
  if (time.hour < 17) return 'Good afternoon';
  return 'Good evening';
}

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider);
    final savingsAsync = ref.watch(savingsProvider);
    final sharesAsync = ref.watch(sharesProvider);
    final investmentsAsync = ref.watch(investmentsApiProvider);
    final loansAsync = ref.watch(loansProvider);
    final profile = profileAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const <String, dynamic>{},
    );
    const savingsBalanceKeys = ['balance', 'current_balance', 'amount'];
    const sharesBalanceKeys = [
      'total_value',
      'market_value',
      'current_value',
      'value',
      'shares_value',
      'balance',
    ];
    const investmentBalanceKeys = [
      'balance',
      'current_balance',
      'amount',
      'current_value',
      'value',
    ];
    final savingsBalance = _sumBalances(
      savingsAsync.valueOrNull,
      savingsBalanceKeys,
    );
    final sharesBalance = _sumBalances(
      sharesAsync.valueOrNull,
      sharesBalanceKeys,
    );
    final investmentsBalance = _sumBalances(
      investmentsAsync.valueOrNull,
      investmentBalanceKeys,
    );
    final loanBalance = _sumLoanBalances(loansAsync.valueOrNull);
    final portfolioOverviewAmount =
        _hasPortfolioBalances(savingsAsync, savingsBalanceKeys) &&
            _hasPortfolioBalances(sharesAsync, sharesBalanceKeys) &&
            _hasPortfolioBalances(investmentsAsync, investmentBalanceKeys)
        ? _money(savingsBalance + sharesBalance + investmentsBalance)
        : 'GH₵ —';

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
        amount: _portfolioAmount(
          savingsAsync,
          savingsBalance,
          savingsBalanceKeys,
        ),
        icon: Icons.savings_rounded,
        accent: const Color(0xFF0C8B5A),
        tint: const Color(0xFFEAF5EE),
        onTap: () => context.go('/savings'),
      ),
      _ProductCard(
        title: 'Shares',
        subtitle: 'Your equity portfolio',
        amount: _portfolioAmount(sharesAsync, sharesBalance, sharesBalanceKeys),
        icon: Icons.pie_chart_rounded,
        accent: const Color(0xFFE7A817),
        tint: const Color(0xFFFFF4DC),
        onTap: () => context.go('/shares'),
      ),
      _ProductCard(
        title: 'Investments',
        subtitle: 'Fixed deposits and more',
        amount: investmentsAsync.hasError
            ? 'Unavailable'
            : _portfolioAmount(
                investmentsAsync,
                investmentsBalance,
                investmentBalanceKeys,
              ),
        icon: Icons.trending_up_rounded,
        accent: const Color(0xFF0C8B5A),
        tint: const Color(0xFFEAF5EE),
        onTap: () => context.go('/investments'),
      ),
      _ProductCard(
        title: 'Loans',
        subtitle: 'Active loans and repayments',
        amount: _portfolioAmount(loansAsync, loanBalance, const [
          'outstanding_balance',
          'outstanding',
          'balance',
        ]),
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
                          _timeBasedGreeting(DateTime.now()),
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
                          portfolioOverviewAmount,
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Products',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1B2A24),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Your finances at a glance',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF718078),
                          ),
                        ),
                      ],
                    ),
                  ),
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
              for (var index = 0; index < products.length; index++) ...[
                products[index],
                if (index < products.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '') ?? '') ?? 0;
  }

  static double _sumBalances(
    List<Map<String, dynamic>>? accounts,
    List<String> keys,
  ) {
    return (accounts ?? const <Map<String, dynamic>>[]).fold<double>(0, (
      sum,
      account,
    ) {
      for (final key in keys) {
        final value = account[key];
        if (value != null) return sum + _toDouble(value);
      }
      return sum;
    });
  }

  static bool _hasPortfolioBalances(
    AsyncValue<List<Map<String, dynamic>>> value,
    List<String> keys,
  ) {
    if (value.isLoading || value.hasError) return false;
    final accounts = value.valueOrNull;
    return accounts != null &&
        accounts.every((account) => keys.any((key) => account[key] != null));
  }

  static double _sumLoanBalances(List<Map<String, dynamic>>? loans) {
    return (loans ?? const <Map<String, dynamic>>[]).fold<double>(
      0,
      (sum, loan) =>
          sum +
          _toDouble(
            loan['outstanding_balance'] ??
                loan['outstanding'] ??
                loan['balance'],
          ),
    );
  }

  static String _money(double value) => 'GH₵ ${value.toStringAsFixed(2)}';

  static String _portfolioAmount(
    AsyncValue<List<Map<String, dynamic>>> value,
    double amount,
    List<String> keys,
  ) {
    if (value.isLoading) return 'Loading...';
    if (value.hasError) return 'Unavailable';
    final items = value.valueOrNull ?? const <Map<String, dynamic>>[];
    if (items.any((item) => !keys.any((key) => item[key] != null))) {
      return 'Unavailable';
    }
    return _money(amount);
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
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5EAE6)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF163326).withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final trailingWidth = (constraints.maxWidth * 0.45).clamp(
                  100.0,
                  170.0,
                );
                final iconWidget = Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: tint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accent, size: 26),
                );
                final titleAndSubtitle = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          title,
                          maxLines: 1,
                          softWrap: false,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1B2A24),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6A7A72),
                      ),
                    ),
                  ],
                );
                final amountText = Text(
                  amount,
                  maxLines: 1,
                  softWrap: false,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                );
                final arrowWidget = Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: tint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.chevron_right_rounded, color: accent),
                );

                return Row(
                  children: [
                    iconWidget,
                    const SizedBox(width: 14),
                    Expanded(child: titleAndSubtitle),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: trailingWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: amountText,
                            ),
                          ),
                          const SizedBox(height: 6),
                          arrowWidget,
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Positioned(
            left: 0,
            top: 12,
            bottom: 12,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
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
