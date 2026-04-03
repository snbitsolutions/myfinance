import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_scaffold.dart';
import '../../core/app_card.dart';
import '../../core/color_ext.dart';
import '../../core/modern_input.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _amountController = TextEditingController();
  String _method = 'Card';

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amt = double.tryParse(_amountController.text) ?? 0;

    return AppScaffold(
      title: 'Payment',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _PaymentHero(theme: theme, method: _method),

            const SizedBox(height: 16),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PaymentSectionHeader(
                    title: 'Amount',
                    subtitle: 'Enter how much you want to pay',
                    icon: Icons.payments_rounded,
                    theme: theme,
                  ),
                  const SizedBox(height: 10),
                  ModernInput(
                    label: 'Amount to Pay',
                    hintText: 'e.g., 500',
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    prefixText: 'GH₵ ',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  _PaymentSectionHeader(
                    title: 'Payment Method',
                    subtitle: 'Choose how you want to complete this payment',
                    icon: Icons.account_balance_wallet_rounded,
                    theme: theme,
                  ),
                  const SizedBox(height: 8),
                  _PaymentDropdownShell(
                    theme: theme,
                    child: DropdownButton<String>(
                      value: _method,
                      isExpanded: true,
                      underline: const SizedBox(),
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      items: ['Card', 'Mobile Money', 'Bank Transfer']
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Row(
                                children: [
                                  Icon(
                                    m == 'Card'
                                        ? Icons.credit_card_rounded
                                        : m == 'Mobile Money'
                                        ? Icons.phone_android_rounded
                                        : Icons.account_balance_rounded,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(m),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _method = v ?? _method),
                    ),
                  ),
                  if (amt > 0) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer
                            .withOpacitySafe(0.2),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacitySafe(
                            0.18,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                                'Payment Summary',
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
                              Text('Total', style: theme.textTheme.bodyMedium),
                              Text(
                                'GH₵${amt.toStringAsFixed(2)}',
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

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: amt > 0
                    ? () {
                        if (amt >= 1) {
                          context.go('/payment-success');
                        } else {
                          context.go('/payment-failed');
                        }
                      }
                    : null,
                icon: const Icon(Icons.lock_outline_rounded),
                label: const Text('Proceed to Payment'),
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

class _PaymentHero extends StatelessWidget {
  final ThemeData theme;
  final String method;

  const _PaymentHero({required this.theme, required this.method});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacitySafe(0.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacitySafe(0.25),
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
              Icons.lock_rounded,
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
                  'Secure Checkout',
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

class _PaymentSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final ThemeData theme;

  const _PaymentSectionHeader({
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
            color: theme.colorScheme.primaryContainer.withOpacitySafe(0.55),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: theme.colorScheme.primary),
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

class _PaymentDropdownShell extends StatelessWidget {
  final ThemeData theme;
  final Widget child;

  const _PaymentDropdownShell({required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacitySafe(0.35),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacitySafe(0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}
