import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_card.dart';
import '../../../core/color_ext.dart';
import '../../../core/utils/receipt_clipboard.dart';
import 'withdrawal_model.dart';

class ReceiptWithdrawalScreen extends StatelessWidget {
  final WithdrawalData data;

  const ReceiptWithdrawalScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = data.processedAt != null
        ? '${data.processedAt!.day}/${data.processedAt!.month}/${data.processedAt!.year} at ${data.processedAt!.hour}:${data.processedAt!.minute.toString().padLeft(2, '0')}'
        : '—';
    final reference = data.reference?.trim().isNotEmpty == true
        ? data.reference!
        : '—';
    final balance = data.isPending
        ? 'Pending confirmation'
        : 'GH₵ ${(data.newBalance ?? 0).toStringAsFixed(2)}';
    final receiptText = [
      'ADEPA - Withdrawal Receipt',
      'Status: ${data.isPending ? 'Pending' : 'Provider reported completion'}',
      'Amount: GH₵ ${data.amount.toStringAsFixed(2)}',
      'Date: $dateFormat',
      'Reference: $reference',
      'Withdrawal method: ${data.method}',
      'Destination: ${data.phoneNumber}',
      'Account: ${data.fromAccount}',
      'New balance: $balance',
    ].join('\n');

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Dark green header
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
                  'Transaction Receipt',
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
                  // ADEPA Branding Card
                  AppCard(
                    backgroundColor: theme.colorScheme.primary,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacitySafe(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              // Logo or title
                              Text(
                                'ADEPA',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 50,
                                height: 2,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Personal Finance Management',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withOpacitySafe(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Success badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacitySafe(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                data.isPending
                                    ? Icons.hourglass_top_rounded
                                    : Icons.check_circle,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                data.isPending
                                    ? 'Withdrawal Pending'
                                    : 'Provider reported completion',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Amount
                  Text(
                    'GH₵ ${data.amount.toStringAsFixed(2)}',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.isPending
                        ? 'Withdrawal Requested'
                        : 'Withdrawal Amount',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Transaction Details
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DetailRow(
                          'Transaction Status',
                          data.isPending
                              ? 'Pending'
                              : 'Provider reported completion',
                          theme,
                        ),
                        _Divider(theme),
                        _DetailRow(
                          'Amount',
                          'GH₵ ${data.amount.toStringAsFixed(2)}',
                          theme,
                          valueColor: theme.colorScheme.error,
                        ),
                        _Divider(theme),
                        _DetailRow('Date & Time', dateFormat, theme),
                        _Divider(theme),
                        _DetailRow(
                          data.isPending
                              ? 'Request Reference'
                              : 'Provider Reference',
                          reference,
                          theme,
                        ),
                        _Divider(theme),
                        _DetailRow('Withdrawal Method', data.method, theme),
                        _Divider(theme),
                        _DetailRow('Destination', data.phoneNumber, theme),
                        _Divider(theme),
                        _DetailRow('Account', data.fromAccount, theme),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // New Balance Card (light green)
                  AppCard(
                    backgroundColor: const Color(0xFFF0F8EF),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.isPending
                              ? 'Balance will update after confirmation'
                              : 'New Available Balance',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacitySafe(
                              0.6,
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          balance,
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
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
                    child: FilledButton.icon(
                      onPressed: () =>
                          copyReceiptToClipboard(context, text: receiptText),
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy receipt'),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
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
                    child: OutlinedButton(
                      onPressed: () => context.go('/savings'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Back to Savings'),
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final Color? valueColor;

  const _DetailRow(this.label, this.value, this.theme, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final ThemeData theme;

  const _Divider(this.theme);

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: theme.colorScheme.outlineVariant);
  }
}
