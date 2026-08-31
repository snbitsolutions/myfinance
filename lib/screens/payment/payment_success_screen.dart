import 'package:flutter/material.dart';
import '../../core/color_ext.dart';
import '../../core/app_card.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_scaffold.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final double? amount;
  final DateTime? processedAt;
  final String? reference;
  final String? title;
  final String? message;
  final String? primaryActionLabel;
  final String? primaryActionRoute;
  final String? secondaryActionLabel;
  final String? secondaryActionRoute;
  final String? account;
  final String? paymentMethod;
  final double? newBalance;

  const PaymentSuccessScreen({
    super.key,
    this.amount,
    this.processedAt,
    this.reference,
    this.title,
    this.message,
    this.primaryActionLabel,
    this.primaryActionRoute,
    this.secondaryActionLabel,
    this.secondaryActionRoute,
    this.account,
    this.paymentMethod,
    this.newBalance,
  });

  String _formatAmount() {
    final value = amount ?? 1000;
    return 'GH₵${value.toStringAsFixed(2)}';
  }

  String _formatReference() {
    if (reference != null && reference!.trim().isNotEmpty) {
      return reference!.trim();
    }
    return 'ADEPA-${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedTitle =
        (title != null && title!.trim().isNotEmpty) ? title! : 'Deposit Successful!';
    final resolvedMessage =
        (message != null && message!.trim().isNotEmpty)
            ? message!
            : 'Your deposit has been credited to your account.';
    final resolvedAccount = account ?? 'Member Savings';
    final resolvedPaymentMethod = paymentMethod ?? 'Mobile Money';
    final resolvedNewBalance = newBalance ?? 46000;

    return AppScaffold(
      title: resolvedTitle,
      showBack: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Success Icon with decorative dots
            Stack(
              alignment: Alignment.center,
              children: [
                // Decorative dots scattered around
                ..._generateDecorativeDots(),
                // Center checkmark icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacitySafe(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, size: 56, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              resolvedTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            // Message
            Text(
              resolvedMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacitySafe(0.7),
              ),
            ),
            const SizedBox(height: 24),
            // Amount Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Amount Deposited',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatAmount(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Account Card
            AppCard(
              child: Row(
                children: [
                  Icon(Icons.savings_rounded, color: theme.colorScheme.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resolvedAccount,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '•••• 4839',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Balance Card (light green background)
            AppCard(
              backgroundColor: const Color(0xFFF0F8EF),
              child: Row(
                children: [
                  Icon(Icons.trending_up_rounded, color: theme.colorScheme.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Available Balance',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'GH₵${resolvedNewBalance.toStringAsFixed(2)}',
                          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Transaction Details
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Transaction Details',
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
            _TransactionDetailRow(
              icon: Icons.receipt_rounded,
              label: 'Amount',
              value: _formatAmount(),
              theme: theme,
            ),
            _TransactionDetailRow(
              icon: Icons.money_off_rounded,
              label: 'Transaction Fee',
              value: 'GH₵ 0.00',
              theme: theme,
            ),
            _TransactionDetailRow(
              icon: Icons.calendar_today_rounded,
              label: 'Date',
              value: '26 Aug 2026',
              theme: theme,
            ),
            _TransactionDetailRow(
              icon: Icons.access_time_rounded,
              label: 'Time',
              value: '10:42 AM',
              theme: theme,
            ),
            _TransactionDetailRow(
              icon: Icons.tag_rounded,
              label: 'Reference',
              value: _formatReference(),
              theme: theme,
            ),
            _TransactionDetailRow(
              icon: Icons.credit_card_rounded,
              label: 'Payment Method',
              value: resolvedPaymentMethod,
              theme: theme,
            ),
            const SizedBox(height: 24),
            // Buttons
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.push(
                    Uri(
                      path: '/payment-receipt',
                      queryParameters: {
                        'amount': amount?.toString() ?? '1000',
                        'reference': _formatReference(),
                        'account': resolvedAccount,
                        'paymentMethod': resolvedPaymentMethod,
                        'newBalance': newBalance?.toString() ?? '46000',
                      },
                    ).toString(),
                  );
                },
                icon: const Icon(Icons.receipt_long_rounded),
                label: const Text('View Receipt'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () => context.go('/savings'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: theme.colorScheme.primary,
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _generateDecorativeDots() {
    final colors = [
      const Color(0xFFB8E6C0),
      const Color(0xFFC8F0D0),
      const Color(0xFFF4D89F),
    ];
    final positions = [
      const Offset(-40, -30),
      const Offset(50, -25),
      const Offset(-35, 35),
      const Offset(45, 40),
      const Offset(-15, -50),
      const Offset(25, -45),
    ];

    return List.generate(
      positions.length,
      (index) => Positioned(
        left: positions[index].dx,
        top: positions[index].dy,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: colors[index % colors.length],
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _TransactionDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  const _TransactionDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacitySafe(0.7),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
