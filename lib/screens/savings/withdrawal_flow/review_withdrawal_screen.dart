import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_scaffold.dart';
import '../../../core/color_ext.dart';
import 'withdrawal_model.dart';

class ReviewWithdrawalScreen extends StatelessWidget {
  final WithdrawalData data;

  const ReviewWithdrawalScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Review Withdrawal',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacitySafe(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacitySafe(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Continuing will submit a withdrawal request to your savings provider. The provider has not supplied a fee estimate, so any additional charge is not shown here. A pending result means the provider has not confirmed completion.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // From Account
            _ReviewCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'From Account',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.fromAccount,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    data.availableBalance == null
                        ? 'Balance unavailable'
                        : 'GH₵ ${data.availableBalance!.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // To Account
            _ReviewCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        data.method.startsWith('Mobile Money')
                            ? Icons.phone_rounded
                            : Icons.account_balance_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.method,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacitySafe(0.6),
                              ),
                            ),
                            Text(
                              data.phoneNumber,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
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
            const SizedBox(height: 12),
            // Withdrawal Amount
            _ReviewCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Withdrawal Amount',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'GH₵ ${data.amount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Summary
            _ReviewCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryRow('Provider fee', 'Not provided', theme),
                  const Divider(height: 16),
                  _SummaryRow(
                    'Amount requested',
                    'GH₵ ${data.amount.toStringAsFixed(2)}',
                    theme,
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Limits
            _ReviewCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data.dailyLimit != null) ...[
                    _SummaryRow(
                      'Daily Limit',
                      'GH₵ ${data.dailyLimit!.toStringAsFixed(2)}',
                      theme,
                    ),
                    Text(
                      'Used: GH₵ ${data.usedDailyLimit.toStringAsFixed(2)} | Remaining: GH₵ ${(data.dailyLimit! - data.usedDailyLimit).toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
                      ),
                    ),
                  ],
                  if (data.dailyLimit != null && data.monthlyLimit != null)
                    const SizedBox(height: 12),
                  if (data.monthlyLimit != null) ...[
                    _SummaryRow(
                      'Monthly Limit',
                      'GH₵ ${data.monthlyLimit!.toStringAsFixed(2)}',
                      theme,
                    ),
                    Text(
                      'Used: GH₵ ${data.usedMonthlyLimit.toStringAsFixed(2)} | Remaining: GH₵ ${(data.monthlyLimit! - data.usedMonthlyLimit).toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
                      ),
                    ),
                  ],
                  if (data.dailyLimit == null && data.monthlyLimit == null)
                    Text(
                      'Withdrawal limits are not available for this account.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Buttons
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () =>
                    context.push('/withdrawal/authenticate', extra: data),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Authorize Withdrawal'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Edit Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final bool isBold;

  const _SummaryRow(this.label, this.value, this.theme, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isBold
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withOpacitySafe(0.7),
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Widget child;

  const _ReviewCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacitySafe(0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacitySafe(0.12),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: theme.colorScheme.primary.withOpacitySafe(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
