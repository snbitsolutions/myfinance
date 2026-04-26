import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';
import '../../core/balance_card_shell.dart';
import '../../core/layout/responsive.dart';
import 'investment_state_provider.dart';

class InvestmentScreen extends ConsumerWidget {
  const InvestmentScreen({super.key});

  static const _plans = <_InvestmentPlan>[
    _InvestmentPlan(
      name: 'Starter Plan',
      roi: '8% yearly',
      minimum: 'GH₵100',
      minimumAmount: 100,
      icon: Icons.auto_graph,
    ),
    _InvestmentPlan(
      name: 'Growth Plan',
      roi: '12% yearly',
      minimum: 'GH₵500',
      minimumAmount: 500,
      icon: Icons.trending_up,
    ),
    _InvestmentPlan(
      name: 'Premium Plan',
      roi: '15% yearly',
      minimum: 'GH₵2,000',
      minimumAmount: 2000,
      icon: Icons.workspace_premium,
    ),
  ];

  static const _highlights = <String>[
    'Flexible plans that fit short and long-term goals',
    'Projected returns visible before you commit',
    'Withdrawals and history tracked in one place',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final investment = ref.watch(investmentProvider);
    final primary = theme.colorScheme.primary;
    final gradientEnd =
        Color.lerp(primary, theme.colorScheme.secondary, 0.35) ??
        theme.colorScheme.secondary;

    void startPlan(_InvestmentPlan plan) {
      ref
          .read(investmentProvider.notifier)
          .recordStart(planName: plan.name, amount: plan.minimumAmount);
      context.go('/payment?source=investment');
    }

    return AppScaffold(
      title: 'Investment',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Portfolio Hero Card
          BalanceCardShell(
            gradientColors: [primary, gradientEnd],
            shadowColor: primary.withValues(alpha: 0.22),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Invested',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${investment.activePlans} active plans',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.68),
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'GH₵${investment.totalInvested.toStringAsFixed(2)}',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.workspace_premium,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.trending_up,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '+8.4% returns YTD',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textScaler: const TextScaler.linear(1.0),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Why invest here',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ..._highlights.map(
                  (highlight) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Icon(
                            Icons.check_circle,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            highlight,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.78,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a plan to continue',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth >= Responsive.medium;
              if (isTablet) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _plans.map((plan) {
                    final isSelected = investment.selectedPlanName == plan.name;
                    return SizedBox(
                      width: (constraints.maxWidth - 12) / 2,
                      child: AppCard(
                        onTap: () => startPlan(plan),
                        child: Row(
                          children: [
                            Container(
                              height: 44,
                              width: 44,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: isSelected ? 0.22 : 0.12,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                plan.icon,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    plan.name,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'ROI: ${plan.roi}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.75),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Min: ${plan.minimum}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.arrow_forward_ios,
                              size: 16,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              }
              return Column(
                children: _plans.map((plan) {
                  final isSelected = investment.selectedPlanName == plan.name;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      onTap: () => startPlan(plan),
                      child: Row(
                        children: [
                          Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: isSelected ? 0.22 : 0.12,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              plan.icon,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plan.name,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'ROI: ${plan.roi} • Min: ${plan.minimum}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.75),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.arrow_forward_ios,
                            size: 16,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 4),
          ElevatedButton.icon(
            onPressed: () {
              final selectedName = investment.selectedPlanName;
              final selectedPlan = _plans.firstWhere(
                (plan) => plan.name == selectedName,
                orElse: () => _plans.first,
              );
              startPlan(selectedPlan);
            },
            icon: const Icon(Icons.trending_up),
            label: const Text('Start Investment'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.go('/investment/activity'),
            icon: const Icon(Icons.analytics_outlined),
            label: const Text('View Investment Activity'),
          ),
        ],
      ),
    );
  }
}

class _InvestmentPlan {
  final String name;
  final String roi;
  final String minimum;
  final double minimumAmount;
  final IconData icon;

  const _InvestmentPlan({
    required this.name,
    required this.roi,
    required this.minimum,
    required this.minimumAmount,
    required this.icon,
  });
}
