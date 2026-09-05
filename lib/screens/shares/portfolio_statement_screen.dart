import 'package:flutter/material.dart';

import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';

class PortfolioStatementScreen extends StatefulWidget {
  const PortfolioStatementScreen({super.key});

  @override
  State<PortfolioStatementScreen> createState() => _PortfolioStatementScreenState();
}

class _PortfolioStatementScreenState extends State<PortfolioStatementScreen> {
  late List<Map<String, dynamic>> transactions;

  @override
  void initState() {
    super.initState();
    // Mock transaction data
    transactions = [
      {
        'date': '15 Aug 2024',
        'type': 'dividend',
        'company': 'AdePa Fintech Ltd',
        'amount': 375.00,
        'shares': 500,
        'per_share': 0.75,
      },
      {
        'date': '10 Jan 2025',
        'type': 'purchase',
        'company': 'AdePa Fintech Ltd',
        'amount': 6250.00,
        'shares': 500,
        'per_share': 12.50,
      },
      {
        'date': '10 Aug 2024',
        'type': 'dividend',
        'company': 'Tech Solutions Ghana',
        'amount': 150.00,
        'shares': 300,
        'per_share': 0.50,
      },
      {
        'date': '05 Mar 2024',
        'type': 'purchase',
        'company': 'Tech Solutions Ghana',
        'amount': 5625.00,
        'shares': 300,
        'per_share': 18.75,
      },
      {
        'date': '12 Aug 2024',
        'type': 'dividend',
        'company': 'Green Energy Corp',
        'amount': 212.50,
        'shares': 250,
        'per_share': 0.85,
      },
      {
        'date': '20 Jun 2024',
        'type': 'purchase',
        'company': 'Green Energy Corp',
        'amount': 5500.00,
        'shares': 250,
        'per_share': 22.00,
      },
    ];
  }

  String _getTransactionLabel(String type) {
    return type == 'dividend' ? 'Dividend Received' : 'Share Purchase';
  }

  IconData _getTransactionIcon(String type) {
    return type == 'dividend' ? Icons.trending_up : Icons.shopping_basket;
  }

  Color _getTransactionColor(String type, ThemeData theme) {
    return type == 'dividend' ? Colors.green : theme.colorScheme.primary;
  }

  double get _totalInvested {
    return transactions
        .where((t) => t['type'] == 'purchase')
        .fold<double>(0, (sum, t) => sum + (t['amount'] as double));
  }

  double get _totalDividends {
    return transactions
        .where((t) => t['type'] == 'dividend')
        .fold<double>(0, (sum, t) => sum + (t['amount'] as double));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return AppScaffold(
      title: 'Portfolio Statement',
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Invested',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 11,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'GH₵ ${_totalInvested.toStringAsFixed(2)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Dividends',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 11,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'GH₵ ${_totalDividends.toStringAsFixed(2)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Info Box
              AppCard(
                backgroundColor: primary.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This statement shows all investment and dividend transactions for your portfolio.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Statement Period
              Text(
                'Statement Period',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Jan 1, 2024 - Dec 31, 2024',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Transaction History
              Text(
                'Transaction History',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...transactions.map((transaction) {
                final icon = _getTransactionIcon(transaction['type'] as String);
                final color = _getTransactionColor(transaction['type'] as String, theme);
                final label = _getTransactionLabel(transaction['type'] as String);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              icon,
                              color: color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${transaction['company']} • ${transaction['date']}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${transaction['shares']} shares @ GH₵ ${(transaction['per_share'] as double).toStringAsFixed(2)}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 9,
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
                                'GH₵ ${(transaction['amount'] as double).toStringAsFixed(2)}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                transaction['type'] == 'dividend' ? '+' : '-',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: transaction['type'] == 'dividend' ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),

              // Download Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Portfolio statement downloaded'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.download),
                      const SizedBox(width: 8),
                      const Text('Download PDF Statement'),
                    ],
                  ),
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
