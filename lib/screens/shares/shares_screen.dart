import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';
import '../../core/layout/responsive.dart';

class SharesScreen extends StatelessWidget {
  const SharesScreen({super.key});

  static const _shareItems = <_ShareItem>[
    _ShareItem(
      symbol: 'MTN',
      company: 'MTN Ghana',
      price: 'GH₵1.92',
      change: '+2.4%',
      isPositive: true,
    ),
    _ShareItem(
      symbol: 'GCB',
      company: 'GCB Bank PLC',
      price: 'GH₵6.35',
      change: '+1.2%',
      isPositive: true,
    ),
    _ShareItem(
      symbol: 'GOIL',
      company: 'GOIL PLC',
      price: 'GH₵1.48',
      change: '-0.8%',
      isPositive: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Shares',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const SizedBox(height: 12),
          Text(
            'Buy shares directly from your existing account.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.account_balance_rounded,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Source account',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '**** 0123 4567 89',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.72,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your active account will fund share purchases.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.58,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.check_circle, color: theme.colorScheme.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Track and grow your portfolio',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth >= Responsive.medium;
              Widget buildShareCard(_ShareItem item) => AppCard(
                onTap: () => context.go('/payment?source=existing_account'),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: theme.colorScheme.primary.withValues(
                        alpha: 0.12,
                      ),
                      child: Text(
                        item.symbol,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.company,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Price: ${item.price}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          item.price,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.change,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: item.isPositive
                                ? theme.colorScheme.primary
                                : theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );

              if (isTablet) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _shareItems.map((item) => SizedBox(
                    width: (constraints.maxWidth - 12) / 2,
                    child: buildShareCard(item),
                  )).toList(),
                );
              }
              return Column(
                children: _shareItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: buildShareCard(item),
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 4),
          ElevatedButton.icon(
            onPressed: () => context.go('/payment?source=existing_account'),
            icon: const Icon(Icons.show_chart),
            label: const Text('Buy Shares from Account'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.go('/transactions'),
            icon: const Icon(Icons.history),
            label: const Text('View Share Activity'),
          ),
        ],
      ),
    );
  }
}

class _ShareItem {
  final String symbol;
  final String company;
  final String price;
  final String change;
  final bool isPositive;

  const _ShareItem({
    required this.symbol,
    required this.company,
    required this.price,
    required this.change,
    required this.isPositive,
  });
}
