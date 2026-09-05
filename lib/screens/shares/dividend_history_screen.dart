import 'package:flutter/material.dart';

import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';

class DividendHistoryScreen extends StatefulWidget {
  const DividendHistoryScreen({super.key});

  @override
  State<DividendHistoryScreen> createState() => _DividendHistoryScreenState();
}

class _DividendHistoryScreenState extends State<DividendHistoryScreen> {
  late List<Map<String, dynamic>> dividends;
  String _selectedFilter = 'all'; // all, received, pending

  @override
  void initState() {
    super.initState();
    // Mock dividend data
    dividends = [
      {
        'id': 'DIV-001',
        'company': 'AdePa Fintech Ltd',
        'date': '15 Aug 2024',
        'status': 'received',
        'amount': 375.00,
        'shares': 500,
        'per_share': 0.75,
        'ex_date': '01 Aug 2024',
        'record_date': '05 Aug 2024',
        'payment_date': '15 Aug 2024',
      },
      {
        'id': 'DIV-002',
        'company': 'Tech Solutions Ghana',
        'date': '10 Aug 2024',
        'status': 'received',
        'amount': 150.00,
        'shares': 300,
        'per_share': 0.50,
        'ex_date': '25 Jul 2024',
        'record_date': '30 Jul 2024',
        'payment_date': '10 Aug 2024',
      },
      {
        'id': 'DIV-003',
        'company': 'Green Energy Corp',
        'date': '12 Aug 2024',
        'status': 'received',
        'amount': 212.50,
        'shares': 250,
        'per_share': 0.85,
        'ex_date': '28 Jul 2024',
        'record_date': '02 Aug 2024',
        'payment_date': '12 Aug 2024',
      },
      {
        'id': 'DIV-004',
        'company': 'AdePa Fintech Ltd',
        'date': '15 Feb 2026',
        'status': 'pending',
        'amount': 375.00,
        'shares': 500,
        'per_share': 0.75,
        'ex_date': '01 Feb 2026',
        'record_date': '05 Feb 2026',
        'payment_date': '15 Feb 2026',
      },
      {
        'id': 'DIV-005',
        'company': 'Tech Solutions Ghana',
        'date': '10 Feb 2026',
        'status': 'pending',
        'amount': 150.00,
        'shares': 300,
        'per_share': 0.50,
        'ex_date': '25 Jan 2026',
        'record_date': '30 Jan 2026',
        'payment_date': '10 Feb 2026',
      },
      {
        'id': 'DIV-006',
        'company': 'Green Energy Corp',
        'date': '12 Feb 2026',
        'status': 'pending',
        'amount': 212.50,
        'shares': 250,
        'per_share': 0.85,
        'ex_date': '28 Jan 2026',
        'record_date': '02 Feb 2026',
        'payment_date': '12 Feb 2026',
      },
    ];
  }

  List<Map<String, dynamic>> get _filteredDividends {
    if (_selectedFilter == 'received') {
      return dividends.where((d) => d['status'] == 'received').toList();
    } else if (_selectedFilter == 'pending') {
      return dividends.where((d) => d['status'] == 'pending').toList();
    }
    return dividends;
  }

  double get _totalReceived {
    return dividends
        .where((d) => d['status'] == 'received')
        .fold<double>(0, (sum, d) => sum + (d['amount'] as double));
  }

  double get _totalPending {
    return dividends
        .where((d) => d['status'] == 'pending')
        .fold<double>(0, (sum, d) => sum + (d['amount'] as double));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return AppScaffold(
      title: 'Dividend History',
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
                              'Received',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 11,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'GH₵ ${_totalReceived.toStringAsFixed(2)}',
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
                              'Pending',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 11,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'GH₵ ${_totalPending.toStringAsFixed(2)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: primary,
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

              // Filter Tabs
              Row(
                children: [
                  _FilterButton(
                    label: 'All',
                    isSelected: _selectedFilter == 'all',
                    onTap: () => setState(() => _selectedFilter = 'all'),
                    theme: theme,
                  ),
                  const SizedBox(width: 8),
                  _FilterButton(
                    label: 'Received',
                    isSelected: _selectedFilter == 'received',
                    onTap: () => setState(() => _selectedFilter = 'received'),
                    theme: theme,
                  ),
                  const SizedBox(width: 8),
                  _FilterButton(
                    label: 'Pending',
                    isSelected: _selectedFilter == 'pending',
                    onTap: () => setState(() => _selectedFilter = 'pending'),
                    theme: theme,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Dividend List
              if (_filteredDividends.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.history,
                          size: 48,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No dividends found',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...List.generate(
                  _filteredDividends.length,
                  (index) {
                    final dividend = _filteredDividends[index];
                    final isReceived = dividend['status'] == 'received';
                    final statusColor = isReceived ? Colors.green : primary;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.trending_up,
                                      color: statusColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              dividend['company'] as String,
                                              style: theme.textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: statusColor.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                isReceived ? 'Received' : 'Pending',
                                                style: theme.textTheme.labelSmall?.copyWith(
                                                  fontSize: 10,
                                                  color: statusColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${dividend['shares']} shares @ GH₵ ${(dividend['per_share'] as double).toStringAsFixed(2)}',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            fontSize: 10,
                                            color: theme.textTheme.bodySmall?.color,
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
                                        'GH₵ ${(dividend['amount'] as double).toStringAsFixed(2)}',
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: statusColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Divider(height: 1, color: theme.dividerColor),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _DividendDateInfo(
                                    label: 'Payment Date',
                                    date: dividend['payment_date'] as String,
                                    theme: theme,
                                  ),
                                  _DividendDateInfo(
                                    label: 'Record Date',
                                    date: dividend['record_date'] as String,
                                    theme: theme,
                                  ),
                                  _DividendDateInfo(
                                    label: 'Ex-Dividend Date',
                                    date: dividend['ex_date'] as String,
                                    theme: theme,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;

  const _FilterButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.dividerColor,
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isSelected ? theme.colorScheme.primary : null,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _DividendDateInfo extends StatelessWidget {
  final String label;
  final String date;
  final ThemeData theme;

  const _DividendDateInfo({
    required this.label,
    required this.date,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 9,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          date,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
