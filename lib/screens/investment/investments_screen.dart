import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';
import '../../core/balance_card_shell.dart';
import '../../core/providers/app_providers.dart';

class InvestmentsScreen extends ConsumerStatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  ConsumerState<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends ConsumerState<InvestmentsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final investmentsAsync = ref.watch(investmentsApiProvider);
    final apiInvestments = investmentsAsync.valueOrNull ?? const [];
    final displayedInvestments = apiInvestments.map(_mapApiInvestment).toList();

    final totalBalance = displayedInvestments.fold<double>(
      0,
      (sum, inv) => sum + _asDouble(inv['current_value']),
    );
    final totalInvested = displayedInvestments.fold<double>(
      0,
      (sum, inv) => sum + _asDouble(inv['principal']),
    );

    final totalEarnings = displayedInvestments.fold<double>(
      0,
      (sum, inv) => sum + _asDouble(inv['total_interest']),
    );
    final balancesAvailable = displayedInvestments.every(
      (item) => item['current_value'] != null,
    );
    final principalAvailable = displayedInvestments.every(
      (item) => item['principal'] != null,
    );
    final earningsAvailable = displayedInvestments.every(
      (item) => item['total_interest'] != null,
    );

    return AppScaffold(
      title: 'Investments',
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero balance card to match the investment detail screen
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primary,
                      Color.lerp(primary, Colors.teal, 0.3) ?? primary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    const Positioned(
                      top: -14,
                      right: -10,
                      child: AdepaLogoBadge(size: 140, opacity: 0.32),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.account_balance,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Portfolio Value',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 46),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          investmentsAsync.hasError ||
                                  investmentsAsync.isLoading
                              ? 'GH₵ —'
                              : balancesAvailable
                                  ? 'GH₵ ${totalBalance.toStringAsFixed(2).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}'
                                  : 'Unavailable',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          investmentsAsync.hasError
                              ? 'Investment data unavailable'
                              : 'Performance history unavailable',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _PortfolioMetric(
                                label: 'YTD Return',
                                value: investmentsAsync.hasError ||
                                        investmentsAsync.isLoading
                                    ? '—'
                                    : earningsAvailable
                                        ? 'GH₵ ${totalEarnings.toStringAsFixed(2)}'
                                        : 'Unavailable',
                                accent: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _PortfolioMetric(
                                label: 'Active Plans',
                                value: investmentsAsync.hasError ||
                                        investmentsAsync.isLoading
                                    ? '—'
                                    : '${displayedInvestments.length}',
                                accent: Colors.white,
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

              AppCard(
                child: Text(
                  'Investment actions will be available when the investment service is connected.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 16),

              // My Investments Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Investments',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (investmentsAsync.isLoading)
                const AppCard(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (investmentsAsync.hasError)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Investments are unavailable',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'The investment service is unavailable, so account data cannot be shown.',
                        style: theme.textTheme.bodySmall,
                      ),
                      TextButton.icon(
                        onPressed: () => ref.invalidate(investmentsApiProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else if (displayedInvestments.isEmpty)
                AppCard(
                  child: Text(
                    'You do not have any investment accounts yet.',
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              else
                ...displayedInvestments.map(
                  (investment) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _InvestmentCard(
                      investment: investment,
                      theme: theme,
                      onTap: () => context.go(
                        '/investments/${investment['id'] ?? 'unknown'}',
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Investment Overview Section
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Investment Overview',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
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
                            value: investmentsAsync.hasError ||
                                    investmentsAsync.isLoading
                                ? '—'
                                : principalAvailable
                                    ? 'GH₵ ${totalInvested.toStringAsFixed(2)}'
                                    : 'Unavailable',
                            theme: theme,
                          ),
                        ),
                        Expanded(
                          child: _OverviewItem(
                            icon: Icons.trending_up,
                            label: 'Total Earnings',
                            value: investmentsAsync.hasError ||
                                    investmentsAsync.isLoading
                                ? '—'
                                : earningsAvailable
                                    ? 'GH₵ ${totalEarnings.toStringAsFixed(2)}'
                                    : 'Unavailable',
                            theme: theme,
                          ),
                        ),
                        Expanded(
                          child: _OverviewItem(
                            icon: Icons.percent,
                            label: 'Average Return',
                            value: displayedInvestments.isEmpty
                                ? '—'
                                : 'Not provided',
                            theme: theme,
                          ),
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

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '') ?? '') ?? 0;
  }

  Map<String, dynamic> _mapApiInvestment(Map<String, dynamic> item) {
    final principal = _numberOrNull(item['principal'] ?? item['amount']);
    final current = _numberOrNull(
      item['current_value'] ?? item['current_balance'] ?? item['value'],
    );
    final interest = _numberOrNull(
      item['total_interest'] ?? item['interest_earned'] ?? item['earnings'],
    );
    return {
      ...item,
      'id': item['id'] ?? item['investment_id'] ?? item['account_id'] ?? '',
      'type': item['type'] ?? item['investment_type'] ?? 'Investment',
      'plan': item['plan'] ?? item['plan_name'] ?? 'Investment Plan',
      'status': item['status'] ?? 'Unavailable',
      'principal': principal,
      'current_value': current,
      'total_interest': interest,
      'monthly_value': _asDouble(
        item['monthly_value'] ?? item['maturity_value'],
      ),
      'interest_rate': _numberOrNull(item['interest_rate'] ?? item['rate']),
      'days_to_maturity': item['days_to_maturity'],
      'tenure_months': item['tenure_months'] ?? item['term_months'],
      'interest_payment': item['interest_payment'] ?? 'Unavailable',
      'auto_renewal': item['auto_renewal'] ?? false,
      'opening_date': item['opening_date'] ?? item['start_date'] ?? '—',
      'maturity_date': item['maturity_date'] ?? item['end_date'] ?? '—',
      'icon': Icons.account_balance,
    };
  }

  double? _numberOrNull(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '') ?? '');
  }
}

class _PortfolioMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _PortfolioMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvestmentCard extends StatelessWidget {
  final Map<String, dynamic> investment;
  final ThemeData theme;
  final VoidCallback onTap;

  const _InvestmentCard({
    required this.investment,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  investment['icon'] as IconData,
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
                      investment['type'] as String,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      investment['plan'] as String,
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
                    investment['current_value'] == null
                        ? 'Unavailable'
                        : 'GH₵ ${(investment['current_value'] as num).toStringAsFixed(2)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    investment['maturity_date'] as String,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
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

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.1),
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
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
