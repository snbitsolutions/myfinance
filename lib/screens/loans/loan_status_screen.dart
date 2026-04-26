import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/color_ext.dart';
import '../../core/app_card.dart';
import 'package:go_router/go_router.dart';
import '../../core/layout/responsive.dart';

import '../../core/app_scaffold.dart';
import 'loan_application_provider.dart';

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

class LoanStatusScreen extends ConsumerWidget {
  const LoanStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final loan = ref.watch(loanApplicationProvider);
    final amountLabel = loan != null
        ? 'GH₵${loan.amount.toStringAsFixed(0)}'
        : 'GH₵—';
    final installmentLabel = loan != null
        ? 'GH₵${loan.monthlyInstallment.toStringAsFixed(2)}'
        : 'GH₵—';
    final submittedAgo = loan != null ? _timeAgo(loan.submittedAt) : 'just now';

    return AppScaffold(
      title: 'Application Status',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= Responsive.medium;

          final content = SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
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
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ref: ${loan?.referenceNumber ?? 'LN-PENDING'}',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Requested: $amountLabel • $submittedAgo',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                AppCard(
                  child: Column(
                    children: [
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withOpacitySafe(0.25),
                              theme.colorScheme.primary.withOpacitySafe(0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacitySafe(
                                0.12,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.hourglass_top,
                          size: 40,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Application Under Review',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Your loan application is being processed. This usually takes 1-2 business days.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacitySafe(
                            0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                AppCard(
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final compact = box.maxWidth < 420;
                      if (compact) {
                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            SizedBox(
                              width: (box.maxWidth - 10) / 2,
                              child: _StatusFact(
                                theme: theme,
                                label: 'Amount',
                                value: amountLabel,
                                icon: Icons.payments_outlined,
                              ),
                            ),
                            SizedBox(
                              width: (box.maxWidth - 10) / 2,
                              child: _StatusFact(
                                theme: theme,
                                label: 'Plan',
                                value: loan?.repaymentPlan ?? 'Pending',
                                icon: Icons.date_range_rounded,
                              ),
                            ),
                            SizedBox(
                              width: box.maxWidth,
                              child: _StatusFact(
                                theme: theme,
                                label: 'Monthly',
                                value: installmentLabel,
                                icon: Icons.calendar_month_rounded,
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: _StatusFact(
                              theme: theme,
                              label: 'Amount',
                              value: amountLabel,
                              icon: Icons.payments_outlined,
                            ),
                          ),
                          Expanded(
                            child: _StatusFact(
                              theme: theme,
                              label: 'Plan',
                              value: loan?.repaymentPlan ?? 'Pending',
                              icon: Icons.date_range_rounded,
                            ),
                          ),
                          Expanded(
                            child: _StatusFact(
                              theme: theme,
                              label: 'Monthly',
                              value: installmentLabel,
                              icon: Icons.calendar_month_rounded,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Review progress',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Step 2 of 3',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: 0.66,
                          minHeight: 8,
                          color: theme.colorScheme.primary,
                          backgroundColor: theme.colorScheme.outline
                              .withOpacitySafe(0.2),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Estimated decision: within 24-48 hours',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacitySafe(
                            0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AppCard(
                  child: Column(
                    children: [
                      _StatusItem(
                        icon: Icons.check_circle,
                        title: 'Application Submitted',
                        subtitle: submittedAgo,
                        isCompleted: true,
                        theme: theme,
                      ),
                      const Divider(height: 20),
                      _StatusItem(
                        icon: Icons.description,
                        title: 'Under Review',
                        subtitle: 'In progress',
                        isCompleted: false,
                        isActive: true,
                        theme: theme,
                      ),
                      const Divider(height: 20),
                      _StatusItem(
                        icon: Icons.account_balance,
                        title: 'Funding',
                        subtitle: 'Pending',
                        isCompleted: false,
                        theme: theme,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/home'),
                        icon: const Icon(Icons.home_outlined),
                        label: const Text('Go Home'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => context.go('/loan-detail'),
                          child: const Text('View Loan Details'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Status refreshed. No new updates yet.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh Status'),
                ),
              ],
            ),
          );

          if (!isTablet) return content;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: content,
            ),
          );
        },
      ),
    );
  }
}

class _StatusFact extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final String value;
  final IconData icon;

  const _StatusFact({
    required this.theme,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isActive;
  final ThemeData theme;

  const _StatusItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    this.isActive = false,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? theme.colorScheme.primary.withOpacitySafe(0.2)
                : isActive
                ? theme.colorScheme.primary.withOpacitySafe(0.12)
                : theme.colorScheme.outline.withOpacitySafe(0.1),
          ),
          child: Icon(
            icon,
            color: isCompleted
                ? theme.colorScheme.primary
                : isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isCompleted
                      ? theme.colorScheme.onSurface
                      : isActive
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withOpacitySafe(0.6),
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacitySafe(0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
