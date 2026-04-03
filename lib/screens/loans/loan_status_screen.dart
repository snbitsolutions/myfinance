import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/color_ext.dart';
import '../../core/app_card.dart';
import 'package:go_router/go_router.dart';

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

    return AppScaffold(
      title: 'Application Status',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            AppCard(
              margin: EdgeInsets.zero,
              child: Row(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ref: ${loan?.referenceNumber ?? 'LN-PENDING'}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Requested: GH₵${loan?.amount.toStringAsFixed(0) ?? '—'} • ${loan != null ? _timeAgo(loan.submittedAt) : 'just now'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacitySafe(
                              0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacitySafe(0.2),
                    theme.colorScheme.secondary.withOpacitySafe(0.1),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacitySafe(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.hourglass_top,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Application Under Review',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your loan application is being processed. This usually takes 1-2 business days.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              margin: EdgeInsets.zero,
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
                      color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            AppCard(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  _StatusItem(
                    icon: Icons.check_circle,
                    title: 'Application Submitted',
                    subtitle: '5 minutes ago',
                    isCompleted: true,
                    theme: theme,
                  ),
                  const Divider(height: 20),
                  _StatusItem(
                    icon: Icons.description,
                    title: 'Under Review',
                    subtitle: 'In progress',
                    isCompleted: false,
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
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isCompleted;
  final ThemeData theme;

  const _StatusItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
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
                : theme.colorScheme.outline.withOpacitySafe(0.1),
          ),
          child: Icon(
            icon,
            color: isCompleted
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
