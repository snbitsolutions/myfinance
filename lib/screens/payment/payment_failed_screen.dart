import 'package:flutter/material.dart';
import '../../core/color_ext.dart';
import '../../core/app_card.dart';
import 'package:go_router/go_router.dart';

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

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Dark green header at the very top
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 16,
              20,
              24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF075D21), Color(0xFF08752B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  isDeposit ? 'Deposit Failed' : 'Payment Failed',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Scrollable content
          Expanded(
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
                              color: theme.colorScheme.error.withOpacitySafe(
                                0.3,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 56,
                          color: Colors.white,
                        ),
                      ),
                      // Broken piggy bank below the X
                      Positioned(top: 70, child: _BrokenPiggyBank()),
                    ],
                  ),
                  const SizedBox(height: 100),
                  // Title
                  Text(
                    isDeposit
                        ? 'We couldn\'t complete your deposit'
                        : 'Payment Failed',
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
                        : 'We were unable to process this payment. Please try again.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Error Reason Card
                  AppCard(
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: theme.colorScheme.error,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reason',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacitySafe(0.6),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                reason ??
                                    'Network error. Please check your connection.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Transaction Details
                  if (amount != null)
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TransactionDetailRow(
                            'Amount',
                            'GH₵${amount!.toStringAsFixed(2)}',
                            theme,
                          ),
                          _TransactionDetailRow(
                            'Date',
                            _formatDateTime(DateTime.now()),
                            theme,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: () => context.go(retryRoute),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Try Again'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => context.go('/home'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Back Home'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final months = [
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
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final meridiem = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day} ${months[date.month - 1]} ${date.year} • $hour:${date.minute.toString().padLeft(2, '0')} $meridiem';
  }
}

class _BrokenPiggyBank extends StatelessWidget {
  const _BrokenPiggyBank();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.pink[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Piggy bank emoji
          const Text('🐷', style: TextStyle(fontSize: 48)),
          // Crack line (diagonal)
          Positioned(
            child: Transform.rotate(
              angle: -0.5,
              child: Container(width: 60, height: 2, color: Colors.red[400]),
            ),
          ),
          // Error badge
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _TransactionDetailRow(this.label, this.value, this.theme);

  @override
  Widget build(BuildContext context) {
    final iconMap = {
      'Amount': Icons.money_rounded,
      'Date': Icons.calendar_today_rounded,
      'Method': Icons.payment_rounded,
      'Reference': Icons.receipt_rounded,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(
            iconMap[label] ?? Icons.check_rounded,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
