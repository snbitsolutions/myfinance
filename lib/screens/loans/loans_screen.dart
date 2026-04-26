import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/action_triple_row.dart';
import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';
import '../../core/balance_card_shell.dart';
import '../../core/color_ext.dart';
import '../../core/layout/responsive.dart';
import 'loan_application_provider.dart';

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
    final loan = ref.watch(loanApplicationProvider);

    return AppScaffold(
      title: 'Loans',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= Responsive.medium;
          final content = SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: loan == null
                ? _EmptyLoansView(theme: theme)
                : _ActiveLoanView(theme: theme, loan: loan),
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
            color: const Color(0xFFB86A14),
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
            color: const Color(0xFF1F7AE0),
            onTap: () => context.go('/loan-detail'),
          ),
          extra: ActionItem(
            label: 'View Application Status',
            icon: Icons.timelapse_rounded,
            color: const Color(0xFF5C6BC0),
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
          Icon(
            Icons.arrow_forward_rounded,
            color: color,
            size: 18,
          ),
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
