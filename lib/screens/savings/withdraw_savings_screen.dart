import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';
import '../../core/color_ext.dart';
import '../../core/modern_input.dart';

class WithdrawSavingsScreen extends StatefulWidget {
  final String? savingsId;

  const WithdrawSavingsScreen({super.key, this.savingsId});

  @override
  State<WithdrawSavingsScreen> createState() => _WithdrawSavingsScreenState();
}

class _WithdrawSavingsScreenState extends State<WithdrawSavingsScreen> {
  final TextEditingController _amountController = TextEditingController();
  static const String _method = 'Mobile Money';

  double get _amount => double.tryParse(_amountController.text) ?? 0.0;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _completeWithdrawal() async {
    final destination = widget.savingsId == null
        ? '/savings'
        : '/savings/${widget.savingsId}';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Withdrawal Successful'),
          content: Text(
            'Your withdrawal of GH₵${_amount.toStringAsFixed(2)} will be sent via $_method shortly.',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    context.go(destination);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Withdraw',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _WithdrawHero(theme: theme, method: _method),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _WithdrawSectionHeader(
                    title: 'Withdrawal Amount',
                    subtitle: 'Enter how much you want to withdraw',
                    icon: Icons.account_balance_wallet_outlined,
                    theme: theme,
                  ),
                  const SizedBox(height: 10),
                  ModernInput(
                    label: 'Amount to Withdraw',
                    hintText: 'e.g., 500',
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    prefixText: 'GH₵ ',
                    onChanged: (_) => setState(() {}),
                  ),
                  if (widget.savingsId != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer
                            .withOpacitySafe(0.35),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Savings account: ${widget.savingsId}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _WithdrawSectionHeader(
                    title: 'Withdrawal Method',
                    subtitle: 'Funds will be sent to your Mobile Money account',
                    icon: Icons.send_to_mobile_rounded,
                    theme: theme,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withOpacitySafe(0.35),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacitySafe(0.2),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.phone_android_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _method,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_amount > 0) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withOpacitySafe(
                          0.25,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.error.withOpacitySafe(0.16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                size: 18,
                                color: theme.colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Withdrawal Summary',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'You will receive',
                                style: theme.textTheme.bodyMedium,
                              ),
                              Text(
                                'GH₵${_amount.toStringAsFixed(2)}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Method: $_method',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacitySafe(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _amount > 0 ? _completeWithdrawal : null,
                icon: const Icon(Icons.arrow_upward_rounded),
                label: const Text('Proceed to Withdraw'),
                style: FilledButton.styleFrom(
                  elevation: 0,
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

class _WithdrawHero extends StatelessWidget {
  final ThemeData theme;
  final String method;

  const _WithdrawHero({required this.theme, required this.method});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.error,
            theme.colorScheme.error.withOpacitySafe(0.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.error.withOpacitySafe(0.22),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacitySafe(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_upward_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Withdraw Funds',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Selected method: $method',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacitySafe(0.92),
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

class _WithdrawSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final ThemeData theme;

  const _WithdrawSectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.withOpacitySafe(0.55),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: theme.colorScheme.error),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacitySafe(0.65),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
