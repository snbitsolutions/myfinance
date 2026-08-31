import 'package:flutter/material.dart';
import '../../core/color_ext.dart';
import '../../core/app_card.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_scaffold.dart';

class PaymentFailedScreen extends StatelessWidget {
  final String returnRoute;
  final bool isDeposit;
  final double? amount;
  final String? reason;

  const PaymentFailedScreen({
    super.key,
    this.returnRoute = '/home',
    this.isDeposit = false,
    this.amount,
    this.reason,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final retryRoute = isDeposit
        ? returnRoute.startsWith('/savings')
            ? returnRoute
            : '/savings'
        : returnRoute.startsWith('/savings')
        ? returnRoute
        : '/home';

    return AppScaffold(
      title: isDeposit ? 'Deposit Failed' : 'Payment Failed',
      showBack: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Error Icon with broken piggy bank
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.error.withOpacitySafe(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close_rounded, size: 56, color: Colors.white),
                ),
                // Broken piggy bank below the X
                Positioned(
                  top: 70,
                  child: _BrokenPiggyBank(),
                ),
              ],
            ),
            const SizedBox(height: 100),
            // Title
            Text(
              isDeposit ? 'We couldn\'t complete your deposit' : 'Payment Failed',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Message
            Text(
              isDeposit
                  ? 'Unfortunately, we were unable to process your deposit. Please try again.'
                  : 'We could not complete this transaction at the moment. Please try again.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacitySafe(0.7),
              ),
            ),
            const SizedBox(height: 24),
            // Error Reason Card
            AppCard(
              backgroundColor: theme.colorScheme.error.withOpacitySafe(0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reason',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.folder_rounded, color: theme.colorScheme.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reason ??
                              (isDeposit
                                  ? 'Mobile Money authorization was unsuccessful.'
                                  : 'Possible causes: insufficient funds or network timeout.'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Transaction Details (if amount provided)
            if (amount != null) ...[
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
                value: 'GH₵${amount!.toStringAsFixed(2)}',
                theme: theme,
              ),
              _TransactionDetailRow(
                icon: Icons.calendar_today_rounded,
                label: 'Date',
                value: '26 Aug 2026',
                theme: theme,
              ),
              _TransactionDetailRow(
                icon: Icons.tag_rounded,
                label: 'Reference',
                value: 'ADEPA-${DateTime.now().millisecondsSinceEpoch}',
                theme: theme,
              ),
              const SizedBox(height: 24),
            ],
            // Buttons
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: () => context.go(
                  Uri(
                    path: '/payment',
                    queryParameters: {
                      'sourceLabel': isDeposit ? 'Deposit' : 'Payment',
                      'returnRoute': retryRoute,
                    },
                  ).toString(),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(isDeposit ? 'Try Again' : 'Retry Payment'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Navigate to payment method selection
                },
                icon: const Icon(Icons.credit_card_rounded),
                label: const Text('Change Payment Method'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Open support contact
                },
                icon: const Icon(Icons.help_outline_rounded),
                label: const Text('Contact Support'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrokenPiggyBank extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Piggy bank body (light pink)
        Container(
          width: 80,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFFFCDD2),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Center(
            child: Text(
              '🐷',
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ),
        ),
        // Crack visual - diagonal line
        Positioned(
          child: Transform.rotate(
            angle: 0.3,
            child: Container(
              width: 50,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFFF48482),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        // Error badge notification
        Positioned(
          top: -5,
          right: -5,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFE53935),
              shape: BoxShape.circle,
            ),
            child: const Text(
              '!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
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
