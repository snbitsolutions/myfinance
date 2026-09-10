import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_scaffold.dart';
import '../../core/balance_card_shell.dart';

class SharesScreen extends StatefulWidget {
  const SharesScreen({super.key});

  @override
  State<SharesScreen> createState() => _SharesScreenState();
}

class _SharesScreenState extends State<SharesScreen> {
  // Mock in-house shares data
  final List<Map<String, dynamic>> myShares = [
    {
      'id': 'SH-001',
      'company': 'AdePa Fintech Ltd',
      'shares_owned': 500,
      'current_price': 12.50,
      'total_value': 6250.00,
      'purchase_date': '10 Jan 2025',
      'dividend_per_share': 0.75,
      'last_dividend': '15 Aug 2024',
      'next_ex_dividend': '15 Feb 2026',
      'dividend_yield': 6.00,
      'change_24h': 2.5,
      'change_color': true,
      'icon': Icons.business,
    },
    {
      'id': 'SH-002',
      'company': 'Tech Solutions Ghana',
      'shares_owned': 300,
      'current_price': 18.75,
      'total_value': 5625.00,
      'purchase_date': '05 Mar 2024',
      'dividend_per_share': 0.50,
      'last_dividend': '10 Aug 2024',
      'next_ex_dividend': '10 Feb 2026',
      'dividend_yield': 2.67,
      'change_24h': -1.2,
      'change_color': false,
      'icon': Icons.computer,
    },
    {
      'id': 'SH-003',
      'company': 'Green Energy Corp',
      'shares_owned': 250,
      'current_price': 22.00,
      'total_value': 5500.00,
      'purchase_date': '20 Jun 2024',
      'dividend_per_share': 0.85,
      'last_dividend': '12 Aug 2024',
      'next_ex_dividend': '12 Feb 2026',
      'dividend_yield': 3.86,
      'change_24h': 0.8,
      'change_color': true,
      'icon': Icons.eco,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final totalPortfolioValue = myShares.fold<double>(
      0,
      (sum, share) => sum + (share['total_value'] as double),
    );

    final totalShares = myShares.fold<int>(
      0,
      (sum, share) => sum + (share['shares_owned'] as int),
    );

    final totalDividends = myShares.fold<double>(
      0,
      (sum, share) =>
          sum + ((share['shares_owned'] as int) * (share['dividend_per_share'] as double)),
    );

    return AppScaffold(
      title: 'Shares',
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {},
        ),
      ],
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primary,
                      primary.withValues(alpha: 0.9),
                      const Color(0xFF0C4A34),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.22),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -18,
                      right: -12,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(70),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Total Portfolio Value',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.82),
                                fontSize: 12,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.visibility,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'GH₵ ${totalPortfolioValue.toStringAsFixed(2).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.trending_up,
                                    color: Color(0xFF7EF7B5),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '+ 5.2% vs last month',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: const Color(0xFFDFFFEA),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _StatPill(
                      label: 'Total Shares',
                      value: '$totalShares',
                      accent: const Color(0xFF2E8B57),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatPill(
                      label: 'Dividends',
                      value: 'GH₵ ${totalDividends.toStringAsFixed(2)}',
                      accent: const Color(0xFF0E8F87),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.add,
                      label: 'Buy\nShares',
                      onTap: () => context.go('/shares/buy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.arrow_forward,
                      label: 'Sell\nShares',
                      onTap: () => context.go('/shares/sell'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.description,
                      label: 'Statement',
                      onTap: () => context.go('/shares/statement'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.payments,
                      label: 'Dividends',
                      onTap: () => context.go('/shares/dividends'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // My Shares Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Shares',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      'Watchlist →',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...myShares.map((share) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ShareCard(
                      share: share,
                      theme: theme,
                      onTap: () => context.go(
                        '/shares/${share['id'] ?? 'unknown'}',
                      ),
                    ),
                  )),
              const SizedBox(height: 16),

              // Portfolio Overview Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    const Positioned(
                      top: -8,
                      right: -4,
                      child: AdepaLogoBadge(size: 108),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Portfolio Overview',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: Text(
                            'View Analytics →',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _OverviewItem(
                            icon: Icons.account_balance_wallet,
                            label: 'Total Invested',
                            value: 'GH₵ 17,375.00',
                            theme: theme,
                          ),
                        ),
                        Expanded(
                          child: _OverviewItem(
                            icon: Icons.trending_up,
                            label: 'Total Gain',
                            value: 'GH₵ 968.00',
                            theme: theme,
                          ),
                        ),
                        Expanded(
                          child: _OverviewItem(
                            icon: Icons.percent,
                            label: 'Overall Return',
                            value: '5.6%',
                            theme: theme,
                          ),
                        ),
                      ],
                    ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.18),
                      theme.colorScheme.primary.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _StatPill({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: accent,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ShareCard extends StatelessWidget {
  final Map<String, dynamic> share;
  final ThemeData theme;
  final VoidCallback onTap;

  const _ShareCard({
    required this.share,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;
    final changeColor = (share['change_color'] as bool) ? Colors.green : Colors.red;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primary.withValues(alpha: 0.18),
                      primary.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  share['icon'] as IconData,
                  color: primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      share['company'] as String,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${share['shares_owned']} shares @ GH₵ ${(share['current_price'] as double).toStringAsFixed(2)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'GH₵ ${(share['total_value'] as double).toStringAsFixed(2)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: changeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${share['change_24h'] > 0 ? '+' : ''}${(share['change_24h'] as double).toStringAsFixed(1)}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: changeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: theme.textTheme.bodySmall?.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  const _OverviewItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primary, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
