import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';
import '../../core/providers/app_providers.dart';

class LoanDetailScreen extends ConsumerWidget {
  final String? loanId;

  const LoanDetailScreen({this.loanId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final loansAsync = ref.watch(loansProvider);
    final loans = loansAsync.valueOrNull ?? const <Map<String, dynamic>>[];
    Map<String, dynamic>? loanData;
    for (final loan in loans) {
      if (loan['loan_id']?.toString() == loanId) {
        loanData = loan;
        break;
      }
    }

    if (loansAsync.isLoading) {
      return const AppScaffold(
        title: 'Loan Details',
        backRoute: '/loans',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (loansAsync.hasError || loanData == null) {
      return AppScaffold(
        title: 'Loan Details',
        backRoute: '/loans',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              loansAsync.hasError
                  ? 'Unable to load this loan from the server.'
                  : 'This loan is no longer available in the account data.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    final displayedLoanId = loanData['loan_id'];

    return AppScaffold(
      title: 'Loan Details',
      backRoute: '/loans',
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              tooltip: 'Notifications',
              onPressed: () => context.go('/notifications'),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.more_vert_rounded),
          tooltip: 'Menu',
          onPressed: () {},
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Card with Loan Summary
            _LoanHeroCard(loanData: loanData, theme: theme),
            const SizedBox(height: 24),

            // Action Buttons
            _ActionButtons(theme: theme),
            const SizedBox(height: 24),

            // Loan Summary
            _LoanSummary(loanData: loanData, theme: theme),
            const SizedBox(height: 24),

            // Repayment Progress
            _RepaymentProgress(loanData: loanData, theme: theme),
            const SizedBox(height: 24),

            // Loan Details
            _LoanDetailsSection(loanData: loanData, theme: theme),
            const SizedBox(height: 24),

            // Payment History
            _PaymentHistory(
              paymentHistory: const [],
              theme: theme,
              onViewAll: () =>
                  context.go('/loan-payment-history/$displayedLoanId'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _LoanHeroCard extends StatelessWidget {
  final Map<String, dynamic> loanData;
  final ThemeData theme;

  const _LoanHeroCard({required this.loanData, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF2E8B57), const Color(0xFF1E5A3F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Loan Type and Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.wallet,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loanData['loan_type'] ?? 'Loan',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                loanData['description'] ?? '',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  loanData['status'] ?? 'Unavailable',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Balance and Due Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Outstanding Balance',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'GH₵ ${(loanData['outstanding_balance'] ?? 0).toStringAsFixed(2)}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Next Payment Due',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loanData['next_payment_due'] ?? '',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${loanData['days_until_due'] ?? 0} days',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Loan ID and Disbursement Date
          Text(
            'Loan ID: ${loanData['loan_id']} • Disbursed: ${loanData['disbursement_date']}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final ThemeData theme;

  const _ActionButtons({required this.theme});

  @override
  Widget build(BuildContext context) {
    final actions = [
      ('Make Repayment', Icons.wallet_outlined),
      ('Repayment Schedule', Icons.calendar_today_outlined),
      ('Loan Statement', Icons.description_outlined),
      ('Download Agreement', Icons.download_outlined),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: actions[0].$2,
                label: actions[0].$1,
                theme: theme,
                onTap: () => context.go('/repayment'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: actions[1].$2,
                label: actions[1].$1,
                theme: theme,
                onTap: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: actions[2].$2,
                label: actions[2].$1,
                theme: theme,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: actions[3].$2,
                label: actions[3].$1,
                theme: theme,
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeData theme;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoanSummary extends StatelessWidget {
  final Map<String, dynamic> loanData;
  final ThemeData theme;

  const _LoanSummary({required this.loanData, required this.theme});

  @override
  Widget build(BuildContext context) {
    final summaryItems = [
      (
        'Loan Amount',
        'GH₵ ${(loanData['loan_amount'] ?? 0).toStringAsFixed(2)}',
        Icons.money_outlined,
      ),
      (
        'Total Interest',
        'GH₵ ${(loanData['total_interest'] ?? 0).toStringAsFixed(2)}',
        Icons.percent_outlined,
      ),
      (
        'Interest Rate (Reducing)',
        '${loanData['interest_rate'] ?? '0%'}',
        Icons.trending_up_outlined,
      ),
      (
        'Total Payable',
        'GH₵ ${(loanData['total_payable'] ?? 0).toStringAsFixed(2)}',
        Icons.account_balance_wallet_outlined,
      ),
      (
        'Loan Tenure',
        '${loanData['loan_tenure'] ?? '0 months'}',
        Icons.calendar_month_outlined,
      ),
      (
        'Amount Disbursed',
        'GH₵ ${(loanData['amount_disbursed'] ?? 0).toStringAsFixed(2)}',
        Icons.payment_outlined,
      ),
      (
        'Disbursed On',
        loanData['disbursement_date'] ?? '',
        Icons.today_outlined,
      ),
      (
        'Maturity Date',
        loanData['maturity_date'] ?? '',
        Icons.event_note_outlined,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Loan Summary',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: summaryItems.map((item) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(item.$3, color: theme.colorScheme.primary, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    item.$1,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.$2,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _RepaymentProgress extends StatelessWidget {
  final Map<String, dynamic> loanData;
  final ThemeData theme;

  const _RepaymentProgress({required this.loanData, required this.theme});

  @override
  Widget build(BuildContext context) {
    final percentage = (loanData['progress_percentage'] ?? 0).toDouble();
    final totalPaid = loanData['total_paid'] ?? 0.0;
    final outstanding = loanData['outstanding_balance'] ?? 0.0;
    final totalPayable = loanData['total_payable'] ?? 0.0;
    final paymentsMade = loanData['payments_made'] ?? 0;
    final totalPayments = loanData['total_payments'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Repayment Progress',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Circular Progress
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: percentage / 100,
                            strokeWidth: 8,
                            backgroundColor: theme.colorScheme.onSurface
                                .withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${percentage.toStringAsFixed(0)}%',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Paid',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Stats
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StatRow(
                          label: 'Total Paid',
                          value: 'GH₵ ${totalPaid.toStringAsFixed(2)}',
                          theme: theme,
                        ),
                        const SizedBox(height: 12),
                        _StatRow(
                          label: 'Outstanding',
                          value: 'GH₵ ${outstanding.toStringAsFixed(2)}',
                          theme: theme,
                          valueColor: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 12),
                        _StatRow(
                          label: 'Total Payable',
                          value: 'GH₵ ${totalPayable.toStringAsFixed(2)}',
                          theme: theme,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  minHeight: 12,
                  backgroundColor: theme.colorScheme.onSurface.withValues(
                    alpha: 0.1,
                  ),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Payment Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$paymentsMade of $totalPayments payments made',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    '${totalPayments - paymentsMade} payments remaining',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final Color? valueColor;

  const _StatRow({
    required this.label,
    required this.value,
    required this.theme,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _LoanDetailsSection extends StatelessWidget {
  final Map<String, dynamic> loanData;
  final ThemeData theme;

  const _LoanDetailsSection({required this.loanData, required this.theme});

  @override
  Widget build(BuildContext context) {
    final detailItems = [
      ('Interest Type', loanData['interest_type'] ?? ''),
      ('Repayment Method', loanData['repayment_method'] ?? ''),
      ('Repayment Day', loanData['repayment_day'] ?? ''),
      ('Collateral', loanData['collateral'] ?? ''),
      ('Guarantor', loanData['guarantor'] ?? ''),
      ('Purpose', loanData['purpose'] ?? ''),
      ('Loan Officer', loanData['loan_officer'] ?? ''),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Loan Details',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            children: List.generate(detailItems.length, (index) {
              final item = detailItems[index];
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.$1,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      Text(
                        item.$2,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (index < detailItems.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                        height: 1,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.1,
                        ),
                      ),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _PaymentHistory extends StatelessWidget {
  final List<Map<String, dynamic>> paymentHistory;
  final ThemeData theme;
  final VoidCallback onViewAll;

  const _PaymentHistory({
    required this.paymentHistory,
    required this.theme,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Payment History (Recent)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              child: Text(
                'View All',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            children: List.generate(paymentHistory.length, (index) {
              final payment = paymentHistory[index];
              return Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {},
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.check_circle,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    payment['payment_number'] ?? '',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    payment['date'] ?? '',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'GH₵ ${(payment['amount'] ?? 0).toStringAsFixed(2)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  payment['type'] ?? '',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (index < paymentHistory.length - 1)
                    Divider(
                      height: 1,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}
