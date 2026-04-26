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
  });

  String _formatAmount() {
    final value = amount ?? 500;
    return 'GH₵${value.toStringAsFixed(2)}';
  }

  String _formatProcessedAt() {
    final value = processedAt ?? DateTime.now();
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
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '${months[value.month - 1]} ${value.day}, ${value.year} • $hour:$minute $period';
  }

  String _formatReference() {
    if (reference != null && reference!.trim().isNotEmpty) {
      return reference!.trim();
    }
    return 'TXN#${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedTitle =
        (title != null && title!.trim().isNotEmpty)
        ? title!
        : 'Payment Successful';
    final resolvedMessage =
        (message != null && message!.trim().isNotEmpty)
        ? message!
        : 'Your transaction was completed successfully.';
    final resolvedPrimaryActionLabel =
      (primaryActionLabel != null && primaryActionLabel!.trim().isNotEmpty)
      ? primaryActionLabel!
      : 'Go Home';
    final resolvedPrimaryActionRoute =
      (primaryActionRoute != null && primaryActionRoute!.trim().isNotEmpty)
      ? primaryActionRoute!
      : '/home';
    final resolvedSecondaryActionLabel =
      (secondaryActionLabel != null && secondaryActionLabel!.trim().isNotEmpty)
      ? secondaryActionLabel!
      : 'View Transactions';
    final resolvedSecondaryActionRoute =
      (secondaryActionRoute != null && secondaryActionRoute!.trim().isNotEmpty)
      ? secondaryActionRoute!
      : '/transactions';

    return AppScaffold(
      title: resolvedTitle,
      showBack: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
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
                    color: theme.colorScheme.primary.withOpacitySafe(0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacitySafe(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    resolvedTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    resolvedMessage,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacitySafe(0.92),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AppCard(
              backgroundColor: theme.colorScheme.primaryContainer
                  .withOpacitySafe(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Transaction Summary',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _PaymentDetail(
                    label: 'Amount',
                    value: _formatAmount(),
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  Divider(
                    color: theme.colorScheme.outline.withOpacitySafe(0.2),
                  ),
                  const SizedBox(height: 12),
                  _PaymentDetail(
                    label: 'Processed On',
                    value: _formatProcessedAt(),
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  Divider(
                    color: theme.colorScheme.outline.withOpacitySafe(0.2),
                  ),
                  const SizedBox(height: 12),
                  _PaymentDetail(
                    label: 'Reference',
                    value: _formatReference(),
                    theme: theme,
                    isMonospace: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () => context.go(resolvedPrimaryActionRoute),
                icon: const Icon(Icons.home_rounded),
                label: Text(resolvedPrimaryActionLabel),
                style: FilledButton.styleFrom(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => context.go(resolvedSecondaryActionRoute),
                icon: const Icon(Icons.receipt_long_rounded),
                label: Text(resolvedSecondaryActionLabel),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentDetail extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final bool isMonospace;

  const _PaymentDetail({
    required this.label,
    required this.value,
    required this.theme,
    this.isMonospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontFamily: isMonospace ? 'monospace' : null,
          ),
        ),
      ],
    );
  }
}
