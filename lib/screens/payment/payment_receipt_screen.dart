import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/color_ext.dart';
import '../../core/app_card.dart';
import '../../core/utils/receipt_clipboard.dart';

class PaymentReceiptScreen extends StatelessWidget {
  final double? amount;
  final DateTime? processedAt;
  final String? reference;
  final String? account;
  final String? paymentMethod;
  final double? newBalance;
  final bool isPending;

  const PaymentReceiptScreen({
    super.key,
    this.amount,
    this.processedAt,
    this.reference,
    this.account,
    this.paymentMethod,
    this.newBalance,
    this.isPending = false,
  });

  String _money(double? value) =>
      value == null ? 'Unavailable' : 'GH₵ ${value.toStringAsFixed(2)}';

  String _month(int month) => const [
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
  ][month - 1];

  String _time(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    return '$hour:${value.minute.toString().padLeft(2, '0')} '
        '${value.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = processedAt;
    final ref = reference?.trim().isNotEmpty == true
        ? reference!
        : 'Unavailable';
    final receiptText = [
      'ADEPA - Deposit Receipt',
      'Status: ${isPending ? 'Pending' : 'Provider reported completion'}',
      'Amount: ${_money(amount)}',
      'Account: ${account ?? 'Member Savings'}',
      'Date: ${date?.toIso8601String() ?? 'Unavailable'}',
      'Reference: $ref',
      'Payment method: ${paymentMethod ?? 'Mobile Money'}',
      if (newBalance != null && !isPending) 'Balance: ${_money(newBalance)}',
    ].join('\n');

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
                  'Deposit Receipt',
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
                  // Dark green content header with ADEPA branding
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF075D21), Color(0xFF08752B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacitySafe(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Top row: ADEPA logo and Success badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'A',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF075D21),
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'ADEPA',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Text(
                                  'Banking with Purpose',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isPending ? Colors.orange : Colors.green,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isPending
                                        ? Icons.hourglass_top_rounded
                                        : Icons.check_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isPending
                                        ? 'Pending'
                                        : 'Provider reported completion',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Receipt title
                        const Text(
                          'Deposit Receipt',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        // Large amount
                        Text(
                          _money(amount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Amount label
                        Text(
                          isPending ? 'Amount Requested' : 'Amount Deposited',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // White details section
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ReceiptDetailRow(
                          'Deposited Into',
                          account ?? 'Member Savings',
                          theme,
                        ),
                        _ReceiptDetailRow(
                          'Date & Time',
                          date == null
                              ? 'Unavailable'
                              : '${date.day} ${_month(date.month)} ${date.year} • ${_time(date)}',
                          theme,
                        ),
                        _ReceiptDetailRow('Reference', ref, theme),
                        _ReceiptDetailRow(
                          'Payment Method',
                          paymentMethod ?? 'Mobile Money',
                          theme,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // New Balance Card (light green)
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
                                _money(isPending ? null : newBalance),
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
                  const SizedBox(height: 16),
                  // Disclaimer section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 24,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isPending
                                ? 'This request is awaiting confirmation. This page does not confirm that funds have settled.'
                                : 'Thank you for banking with Adepa. This receipt is electronically generated.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacitySafe(0.65),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          copyReceiptToClipboard(context, text: receiptText),
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy receipt'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                        backgroundColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Done'),
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
}

class _ReceiptDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _ReceiptDetailRow(this.label, this.value, this.theme);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacitySafe(0.7),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
