import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/action_triple_row.dart';
import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';
import '../../core/balance_card_shell.dart';
import '../../core/color_ext.dart';
import '../../core/layout/responsive.dart';
import '../../core/providers/app_providers.dart';
import 'loan_application_provider.dart';
import 'dart:math' as math;

String _loanDateLabel(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

class LoansScreen extends ConsumerWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final apiLoansAsync = ref.watch(loansProvider);

    // Build mock loans for hub view demo if API data is empty/loading
    final mockLoans = [
      {
        'loan_id': 'LN-826471',
        'loan_type': 'Instant Loan',
        'description': 'Short term financing',
        'amount': 5000.0,
        'outstanding_balance': 4083.60,
        'status': 'Active',
        'next_payment_due': '26 Jun 2026',
        'days_until_due': 31,
        'disbursement_date': '26 Feb 2026',
        'next_payment_amount': 280.0,
      },
      {
        'loan_id': 'LN-752819',
        'loan_type': 'Personal Loan',
        'description': 'General purpose loan',
        'amount': 7000.0,
        'outstanding_balance': 5000.00,
        'status': 'Active',
        'next_payment_due': '10 Jun 2026',
        'days_until_due': 15,
        'disbursement_date': '15 Sep 2025',
        'next_payment_amount': 450.0,
      },
    ];

    return AppScaffold(
      title: 'Loans',
      backRoute: '/home',
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
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
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= Responsive.medium;

          // Determine which loans to display - use mock data on error or loading
          late final List<Map<String, dynamic>> loansToDisplay;
          if (apiLoansAsync.hasValue && apiLoansAsync.value!.isNotEmpty) {
            loansToDisplay = apiLoansAsync.value!;
          } else {
            loansToDisplay = mockLoans;
          }

          final content = SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // API loans summary banner - handles loading and error states
                _ApiLoansSummary(apiLoansAsync: apiLoansAsync, theme: theme),
                // Always show hub view with either API data or mock data
                _LoansHubView(theme: theme, apiLoans: loansToDisplay),
              ],
            ),
          );

          if (!isTablet) return content;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: content,
            ),
          );
        },
      ),
    );
  }
}

class _ApiLoansSummary extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> apiLoansAsync;
  final ThemeData theme;

  const _ApiLoansSummary({required this.apiLoansAsync, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (apiLoansAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    if (apiLoansAsync.hasError) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 16,
                color: theme.colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Could not load loans from server',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final loans = apiLoansAsync.value ?? const [];
    if (loans.isEmpty) return const SizedBox.shrink();

    final totalOutstanding = loans.fold<double>(0.0, (sum, l) {
      final v = l['outstanding_balance'] ?? l['balance'] ?? l['amount'] ?? 0;
      return sum + (v is num ? v.toDouble() : 0.0);
    });

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFB86A14).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.account_balance_rounded,
                color: Color(0xFFB86A14),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${loans.length} active loan${loans.length == 1 ? '' : 's'} on file',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Total outstanding: GH₵${totalOutstanding.toStringAsFixed(2)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.65,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyLoansView extends StatelessWidget {
  final ThemeData theme;

  const _EmptyLoansView({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BalanceCardShell(
          gradientColors: const [Color(0xFFB86A14), Color(0xFFD98D1F)],
          shadowColor: const Color(0x33B86A14),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Need funding for a goal?',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Apply, track approval, and pay back from one place.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => context.go('/apply-loan'),
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('Apply for a Loan'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF9D5A10),
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
              Text(
                'What you can do',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              _LoanFeatureTile(
                icon: Icons.flash_on_rounded,
                title: 'Apply quickly',
                description:
                    'Choose an amount, set a purpose, and pick a repayment plan in minutes.',
                color: const Color(0xFFB86A14),
                onTap: () => context.go('/apply-loan'),
              ),
              const SizedBox(height: 12),
              _LoanFeatureTile(
                icon: Icons.payments_outlined,
                title: 'Pay loans easily',
                description:
                    'Make partial repayments or clear the full balance from the same flow.',
                color: const Color(0xFF2E8B57),
                onTap: () => context.go('/repayment'),
              ),
              const SizedBox(height: 12),
              _LoanFeatureTile(
                icon: Icons.receipt_long_rounded,
                title: 'Track your progress',
                description:
                    'See what you borrowed, what you have repaid, and what is still due.',
                color: const Color(0xFF1F7AE0),
                onTap: () => context.go('/loan-detail'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActiveLoanView extends StatelessWidget {
  final ThemeData theme;
  final LoanApplicationState loan;

  const _ActiveLoanView({required this.theme, required this.loan});

  @override
  Widget build(BuildContext context) {
    final outstanding = loan.outstandingBalance;
    final repaid = loan.repaidAmount;
    final total = loan.totalWithInterest;
    final progress = loan.progressFraction.clamp(0.0, 1.0);
    final dueDate = loan.dueDate;
    final dueInDays = dueDate
        .difference(
          DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          ),
        )
        .inDays;
    final dueStatus = dueInDays < 0
        ? 'Overdue by ${dueInDays.abs()} day${dueInDays.abs() == 1 ? '' : 's'}'
        : dueInDays <= 7
        ? 'Due soon'
        : 'On track';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BalanceCardShell(
          gradientColors: const [Color(0xFFB86A14), Color(0xFFD98D1F)],
          shadowColor: const Color(0x33B86A14),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Outstanding balance',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'GH₵${outstanding.toStringAsFixed(2)}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ref: ${loan.referenceNumber}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Plan: ${loan.repaymentPlan}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      'Due: ${_loanDateLabel(dueDate)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ActionTripleRow(
          deposit: ActionItem(
            label: 'Apply',
            icon: Icons.add_circle_outline_rounded,
            color: theme.colorScheme.primary,
            onTap: () => context.go('/apply-loan'),
          ),
          withdraw: ActionItem(
            label: 'Pay Loan',
            icon: Icons.payments_rounded,
            color: theme.colorScheme.primary,
            onTap: () => context.go('/repayment'),
          ),
          transfer: ActionItem(
            label: 'Details',
            icon: Icons.receipt_long_rounded,
            color: theme.colorScheme.primary,
            onTap: () => context.go('/loan-detail'),
          ),
          extra: ActionItem(
            label: 'View Application Status',
            icon: Icons.timelapse_rounded,
            color: theme.colorScheme.primary,
            onTap: () => context.go('/loan-status'),
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Loan Overview',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _LoanStatCard(
                      theme: theme,
                      label: 'Borrowed',
                      value: 'GH₵${loan.amount.toStringAsFixed(2)}',
                      icon: Icons.call_received_rounded,
                      color: const Color(0xFFB86A14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _LoanStatCard(
                      theme: theme,
                      label: 'Repaid',
                      value: 'GH₵${repaid.toStringAsFixed(2)}',
                      icon: Icons.task_alt_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _LoanStatCard(
                      theme: theme,
                      label: 'Monthly',
                      value: 'GH₵${loan.monthlyInstallment.toStringAsFixed(2)}',
                      icon: Icons.calendar_month_rounded,
                      color: const Color(0xFF5C6BC0),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _LoanStatCard(
                      theme: theme,
                      label: 'Status',
                      value: dueStatus,
                      icon: Icons.schedule_rounded,
                      color: dueInDays <= 7
                          ? theme.colorScheme.error
                          : const Color(0xFF2E8B57),
                    ),
                  ),
                ],
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
                    Icons.show_chart_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Repayment Progress',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  color: theme.colorScheme.primary,
                  backgroundColor: theme.colorScheme.outline.withOpacitySafe(
                    0.18,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${(progress * 100).toStringAsFixed(1)}% of GH₵${total.toStringAsFixed(2)} repaid',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                loan.purpose,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacitySafe(0.64),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoanFeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback? onTap;

  const _LoanFeatureTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacitySafe(0.64),
                ),
              ),
            ],
          ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_rounded, color: color, size: 18),
        ],
      ],
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: content,
        ),
      ),
    );
  }
}

class _LoanStatCard extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _LoanStatCard({
    required this.theme,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 10),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacitySafe(0.64),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoansHubView extends StatefulWidget {
  final ThemeData theme;
  final List<Map<String, dynamic>> apiLoans;

  const _LoansHubView({required this.theme, required this.apiLoans});

  @override
  State<_LoansHubView> createState() => _LoansHubViewState();
}

class _LoansHubViewState extends State<_LoansHubView> {
  int _selectedQuickAction = 0;

  @override
  Widget build(BuildContext context) {
    final loans = widget.apiLoans;
    final theme = widget.theme;

    // Calculate totals
    final totalOutstanding = loans.fold<double>(0.0, (sum, l) {
      final v = l['outstanding_balance'] ?? l['balance'] ?? l['amount'] ?? 0;
      return sum + (v is num ? v.toDouble() : 0.0);
    });

    final upcomingPayments = loans
        .where((l) => (l['next_payment_due'] as String?).toString().isNotEmpty)
        .toList();

    return Column(
      children: [
        const SizedBox(height: 12),
        // Total Outstanding Summary Card
        BalanceCardShell(
          gradientColors: const [Color(0xFF2E8B57), Color(0xFF3DA66B)],
          shadowColor: const Color(0x332E8B57),
          contentPadding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Total Outstanding',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.visibility_outlined,
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'GH₵${totalOutstanding.toStringAsFixed(2)}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Across ${loans.length} active loan${loans.length == 1 ? '' : 's'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => context.go('/apply-loan'),
                    icon: const Icon(Icons.add),
                    label: const Text('Apply for\nNew Loan'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2E8B57),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Quick Action Tabs
        AppCard(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      _QuickActionTab(
                        icon: Icons.pie_chart_rounded,
                        label: 'Loan Overview',
                        isSelected: _selectedQuickAction == 0,
                        onTap: () => setState(() => _selectedQuickAction = 0),
                      ),
                      const SizedBox(width: 8),
                      _QuickActionTab(
                        icon: Icons.calendar_month_outlined,
                        label: 'Repayment Schedule',
                        isSelected: _selectedQuickAction == 1,
                        onTap: () => setState(() => _selectedQuickAction = 1),
                      ),
                      const SizedBox(width: 8),
                      _QuickActionTab(
                        icon: Icons.receipt_outlined,
                        label: 'Loan Statement',
                        isSelected: _selectedQuickAction == 2,
                        onTap: () => setState(() => _selectedQuickAction = 2),
                      ),
                      const SizedBox(width: 8),
                      _QuickActionTab(
                        icon: Icons.calculate_outlined,
                        label: 'Loan Calculator',
                        isSelected: _selectedQuickAction == 3,
                        onTap: () => setState(() => _selectedQuickAction = 3),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // My Active Loans Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Active Loans (${loans.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Row(
                children: [
                  Text(
                    'View Closed Loans',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...loans.map(
          (loan) => _LoanCard(
            loan: loan,
            theme: theme,
            onViewDetails: () =>
                context.go('/loans/${loan['loan_id'] ?? 'unknown'}'),
          ),
        ),
        const SizedBox(height: 16),

        // Loan Overview Chart
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Loan Overview',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: _LoanDonutChart(loans: loans, theme: theme),
              ),
              const SizedBox(height: 16),
              ..._buildLoanLegend(loans, theme),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Upcoming Payments Section
        if (upcomingPayments.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Payments',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Row(
                  children: [
                    Text(
                      'View Schedule',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...upcomingPayments
              .take(2)
              .map(
                (payment) =>
                    _UpcomingPaymentCard(payment: payment, theme: theme),
              ),
          const SizedBox(height: 16),
        ],

        // Information Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.16),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Keep up with your repayments to avoid penalties and improve your credit score.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildLoanLegend(
    List<Map<String, dynamic>> loans,
    ThemeData theme,
  ) {
    final colors = [
      const Color(0xFF2E8B57),
      const Color(0xFF7CB342),
      const Color(0xFF9CCC65),
      const Color(0xFFFDD835),
    ];

    return loans.asMap().entries.map((entry) {
      final index = entry.key;
      final loan = entry.value;
      final loanName = loan['loan_type'] ?? 'Loan ${index + 1}';
      final amount = loan['outstanding_balance'] ?? loan['balance'] ?? 0;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: colors[index % colors.length],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                loanName,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              'GH₵${(amount is num ? amount.toDouble() : 0.0).toStringAsFixed(2)}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _QuickActionTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickActionTab({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final Map<String, dynamic> loan;
  final ThemeData theme;
  final VoidCallback onViewDetails;

  const _LoanCard({
    required this.loan,
    required this.theme,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final loanName = loan['loan_type'] ?? 'Personal Loan';
    final description = loan['description'] ?? 'Short term financing';
    final outstanding = loan['outstanding_balance'] ?? loan['balance'] ?? 0;
    final nextDue = loan['next_payment_due'] ?? 'No due date';
    final daysUntilDue = loan['days_until_due'] ?? 0;
    final loanId = loan['loan_id'] ?? 'LN-000000';
    final disburseDate = loan['disbursement_date'] ?? '01 Jan 2026';
    final status = loan['status']?.toString().toUpperCase() ?? 'ACTIVE';

    final statusColor = status == 'ACTIVE'
        ? const Color(0xFF4CAF50)
        : status == 'PENDING'
        ? const Color(0xFFFFA500)
        : const Color(0xFFD32F2F);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.wallet_rounded,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loanName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Outstanding Balance',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'GH₵${(outstanding is num ? outstanding.toDouble() : 0.0).toStringAsFixed(2)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next Payment Due',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nextDue,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$daysUntilDue days',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Loan ID: $loanId',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Disbursed: $disburseDate',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: onViewDetails,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.primary),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'View Details',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoanDonutChart extends StatelessWidget {
  final List<Map<String, dynamic>> loans;
  final ThemeData theme;

  const _LoanDonutChart({required this.loans, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (loans.isEmpty) {
      return Center(
        child: Text('No loans to display', style: theme.textTheme.bodySmall),
      );
    }

    final total = loans.fold<double>(0.0, (sum, l) {
      final v = l['outstanding_balance'] ?? l['balance'] ?? 0;
      return sum + (v is num ? v.toDouble() : 0.0);
    });

    if (total == 0) {
      return Center(
        child: Text('No outstanding balance', style: theme.textTheme.bodySmall),
      );
    }

    final colors = [
      const Color(0xFF2E8B57),
      const Color(0xFF7CB342),
      const Color(0xFF9CCC65),
      const Color(0xFFFDD835),
    ];

    return CustomPaint(
      painter: _DonutChartPainter(loans: loans, colors: colors, total: total),
      size: Size.infinite,
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> loans;
  final List<Color> colors;
  final double total;

  _DonutChartPainter({
    required this.loans,
    required this.colors,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    var startAngle = -math.pi / 2;

    for (var i = 0; i < loans.length; i++) {
      final loan = loans[i];
      final value = loan['outstanding_balance'] ?? loan['balance'] ?? 0;
      final doubleValue = value is num ? value.toDouble() : 0.0;
      final sweepAngle = (doubleValue / total) * 2 * math.pi;

      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(_DonutChartPainter oldDelegate) => false;
}

class _UpcomingPaymentCard extends StatelessWidget {
  final Map<String, dynamic> payment;
  final ThemeData theme;

  const _UpcomingPaymentCard({required this.payment, required this.theme});

  @override
  Widget build(BuildContext context) {
    final loanName = payment['loan_type'] ?? 'Loan Payment';
    final dueDate = payment['next_payment_due'] ?? 'N/A';
    final amount = payment['next_payment_amount'] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        margin: EdgeInsets.zero,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loanName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dueDate,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'GH₵${(amount is num ? amount.toDouble() : 0.0).toStringAsFixed(2)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
