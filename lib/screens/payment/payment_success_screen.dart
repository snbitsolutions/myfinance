import 'package:flutter/material.dart';
import '../../core/color_ext.dart';
import '../../core/app_card.dart';
import 'package:go_router/go_router.dart';

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
  final bool isPending;

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
    this.isPending = false,
  });

  String _formatAmount() {
    final value = amount;
    return value == null ? 'Unavailable' : 'GH₵${value.toStringAsFixed(2)}';
  }

  String _formatReference() {
    if (reference != null && reference!.trim().isNotEmpty) {
      return reference!.trim();
    }
    return 'Unavailable';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedTitle = (title != null && title!.trim().isNotEmpty)
        ? title!
        : (isPending ? 'Deposit Pending' : 'Deposit Status');
    final resolvedMessage = (message != null && message!.trim().isNotEmpty)
        ? message!
        : (isPending
              ? 'Your request is awaiting provider confirmation.'
              : 'The provider reported that the request completed.');
    final resolvedAccount = account ?? 'Member Savings';
    final resolvedPaymentMethod = paymentMethod ?? 'Mobile Money';
    final resolvedNewBalance = newBalance;

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
                const Text(
                  'Deposit Status',
                  style: TextStyle(
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
                              color: theme.colorScheme.primary.withOpacitySafe(
                                0.3,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          isPending
                              ? Icons.hourglass_top_rounded
                              : Icons.check_rounded,
                          size: 56,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    resolvedTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Message
                  Text(
                    resolvedMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Amount section (plain background)
                  Text(
                    _formatAmount(),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Amount entered',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Transaction Details Card
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TransactionDetailRow(
                          'Account',
                          resolvedAccount,
                          theme,
                        ),
                        _TransactionDetailRow(
                          'Method',
                          resolvedPaymentMethod,
                          theme,
                        ),
                        _TransactionDetailRow(
                          'Reference',
                          _formatReference(),
                          theme,
                        ),
                        _TransactionDetailRow('Date', _formatDateTime(), theme),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Balance Card
                  AppCard(
                    backgroundColor: const Color(0xFFF0F8EF),
                    child: Row(
                      children: [
                        Icon(
                          Icons.trending_up_rounded,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isPending
                                    ? 'Balance will update after confirmation'
                                    : 'Balance',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacitySafe(0.6),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isPending || resolvedNewBalance == null
                                    ? 'Balance unavailable'
                                    : 'GH₵${resolvedNewBalance.toStringAsFixed(2)}',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
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
                      onPressed: () {
                        if (primaryActionRoute != null &&
                            primaryActionRoute!.trim().isNotEmpty) {
                          context.go(primaryActionRoute!);
                        } else {
                          context.go('/savings');
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(primaryActionLabel ?? 'Done'),
                    ),
                  ),
                  if (secondaryActionRoute != null &&
                      secondaryActionRoute!.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => context.push(
                          secondaryActionRoute!,
                          extra: {
                            'amount': amount,
                            'processedAt': processedAt?.toIso8601String(),
                            'reference': reference,
                            'account': account,
                            'paymentMethod': paymentMethod,
                            'newBalance': newBalance,
                            'isPending': isPending,
                          },
                        ),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(secondaryActionLabel ?? 'View Receipt'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime() {
    final date = processedAt;
    if (date == null) return 'Unavailable';
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

  List<Widget> _generateDecorativeDots() {
    final colors = [
      const Color(0xFFE8F5E9),
      const Color(0xFFFFF9C4),
      const Color(0xFFE0F2F1),
      const Color(0xFFF0F4C3),
      const Color(0xFFE8F5E9),
    ];

    final positions = [
      (dx: -40.0, dy: -60.0),
      (dx: 60.0, dy: -50.0),
      (dx: -70.0, dy: 20.0),
      (dx: 80.0, dy: 30.0),
      (dx: 0.0, dy: 80.0),
    ];

    return List.generate(
      colors.length,
      (i) => Positioned(
        left: 60 + positions[i].dx,
        top: 60 + positions[i].dy,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: colors[i], shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _TransactionDetailRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final ThemeData theme;

  const _TransactionDetailRow(this.label, this.value, this.theme) : icon = '';

  @override
  Widget build(BuildContext context) {
    final iconMap = {
      'Account': Icons.account_balance_wallet_rounded,
      'Method': Icons.payment_rounded,
      'Reference': Icons.receipt_rounded,
      'Date': Icons.calendar_today_rounded,
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
