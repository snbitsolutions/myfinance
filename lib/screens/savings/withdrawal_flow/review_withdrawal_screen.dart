import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
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
                    'GH₵ ${(data.availableBalance ?? 0).toStringAsFixed(2)}',
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
                      color: theme.colorScheme.error,
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
                  _SummaryRow(
                    'Amount requested',
                    'GH₵ ${data.amount.toStringAsFixed(2)}',
                    theme,
                    isBold: true,
                    valueColor: theme.colorScheme.error,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _ReviewCard(
              child: Text(
                'At least GH₵${AppConstants.minimumSavingsBalanceAfterWithdrawal.toStringAsFixed(2)} will remain in your account after this withdrawal.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacitySafe(0.7),
                ),
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
  final Color? valueColor;

  const _SummaryRow(
    this.label,
    this.value,
    this.theme, {
    this.isBold = false,
    this.valueColor,
  });

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
            color: valueColor,
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
