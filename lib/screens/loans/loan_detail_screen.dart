import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';
import '../../core/color_ext.dart';
import '../../core/layout/responsive.dart';
import 'loan_application_provider.dart';

String _fmtDate(DateTime d) {
  const m = [
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
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

class LoanDetailScreen extends ConsumerWidget {
  const LoanDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final loan = ref.watch(loanApplicationProvider);
    final loanAmount = loan?.amount ?? 1000.0;
    final outstanding = loan?.outstandingBalance ?? 0.0;
    final repaid = loan?.repaidAmount ?? 0.0;
    final nextInstallment = loan?.monthlyInstallment ?? outstanding;
    final progressFraction = loan?.progressFraction ?? 0.0;
    final progressPct = (progressFraction * 100).round();
    final dueDate = loan != null
        ? loan.submittedAt.add(Duration(days: loan.planMonths * 30))
        : DateTime(2026, 3, 30);
    final today = DateTime.now();
    final dueInDays = dueDate
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
    final dueStatusText = dueInDays < 0
        ? 'Overdue by ${dueInDays.abs()} days'
        : dueInDays <= 7
        ? 'Due soon'
        : 'On schedule';
    final dueStatusColor = dueInDays <= 7
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return AppScaffold(
      title: 'Loan Details',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= Responsive.medium;

          final heroCard = Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacitySafe(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacitySafe(0.2),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Loan Portfolio Snapshot',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Ref: ${loan?.referenceNumber ?? 'LN-PENDING'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Outstanding\nGH₵${outstanding.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Repaid\nGH₵${repaid.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );

          final dueStatusCard = AppCard(
            child: Row(
              children: [
                Icon(Icons.schedule_rounded, color: dueStatusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Due status: $dueStatusText',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: dueStatusColor,
                    ),
                  ),
                ),
              ],
            ),
          );

          final summaryCard = AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primaryContainer
                            .withOpacitySafe(0.3),
                      ),
                      child: Icon(
                        Icons.account_balance,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Loan Summary',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailItem(
                  theme: theme,
                  label: 'Loan Amount',
                  value: 'GH₵${loanAmount.toStringAsFixed(2)}',
                  icon: Icons.attach_money,
                ),
                const SizedBox(height: 12),
                _DetailItem(
                  theme: theme,
                  label: 'Outstanding Balance',
                  value: 'GH₵${outstanding.toStringAsFixed(2)}',
                  icon: Icons.warning_amber,
                  valueColor: theme.colorScheme.error,
                ),
                const SizedBox(height: 12),
                _DetailItem(
                  theme: theme,
                  label: 'Interest Rate',
                  value:
                      '${((loan?.effectiveRate ?? 0.12) * 100).toStringAsFixed(0)}% flat (${loan?.repaymentPlan ?? '12 months'})',
                  icon: Icons.percent,
                ),
                const SizedBox(height: 12),
                _DetailItem(
                  theme: theme,
                  label: 'Due Date',
                  value: _fmtDate(dueDate),
                  icon: Icons.calendar_today,
                ),
              ],
            ),
          );

          final progressCard = AppCard(
            backgroundColor: theme.colorScheme.primaryContainer.withOpacitySafe(
              0.1,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Progress',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacitySafe(0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '$progressPct% Repaid',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: 4,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progressFraction,
                            strokeWidth: 4,
                            backgroundColor: theme.colorScheme.outline
                                .withOpacitySafe(0.2),
                            valueColor: AlwaysStoppedAnimation(
                              theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            '$progressPct%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );

          final repaymentCard = AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.event_note_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Next Repayment Snapshot',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _DetailItem(
                  theme: theme,
                  label: 'Amount already repaid',
                  value: 'GH₵${repaid.toStringAsFixed(2)}',
                  icon: Icons.task_alt_rounded,
                  valueColor: theme.colorScheme.primary,
                ),
                const SizedBox(height: 10),
                _DetailItem(
                  theme: theme,
                  label: 'Suggested next installment',
                  value: 'GH₵${nextInstallment.toStringAsFixed(2)}',
                  icon: Icons.payments_outlined,
                ),
                const SizedBox(height: 10),
                _DetailItem(
                  theme: theme,
                  label: 'Time until due date',
                  value: dueInDays < 0
                      ? 'Past due by ${dueInDays.abs()} days'
                      : '$dueInDays day${dueInDays == 1 ? '' : 's'} left',
                  icon: Icons.schedule_rounded,
                  valueColor: dueStatusColor,
                ),
              ],
            ),
          );

          final repayButton = SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/repayment'),
              icon: const Icon(Icons.payment),
              label: const Text('Make Repayment'),
            ),
          );

          if (isTablet) {
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      heroCard,
                      const SizedBox(height: 14),
                      dueStatusCard,
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: summaryCard),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              children: [
                                progressCard,
                                const SizedBox(height: 14),
                                repaymentCard,
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      repayButton,
                    ],
                  ),
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                heroCard,
                const SizedBox(height: 14),
                dueStatusCard,
                const SizedBox(height: 14),
                summaryCard,
                const SizedBox(height: 14),
                progressCard,
                const SizedBox(height: 14),
                repaymentCard,
                const SizedBox(height: 20),
                repayButton,
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _DetailItem({
    required this.theme,
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.colorScheme.primary.withOpacitySafe(0.6),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacitySafe(0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 130),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
