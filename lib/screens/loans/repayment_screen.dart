import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';
import '../../core/color_ext.dart';
import '../../core/modern_input.dart';
import 'loan_application_provider.dart';

class RepaymentScreen extends ConsumerStatefulWidget {
  const RepaymentScreen({super.key});

  @override
  ConsumerState<RepaymentScreen> createState() => _RepaymentScreenState();
}

class _RepaymentScreenState extends ConsumerState<RepaymentScreen> {
  final TextEditingController _amountController = TextEditingController();

  double _parseAmount(String value) {
    final normalized = value.replaceAll(',', '').trim();
    return double.tryParse(normalized) ?? 0;
  }

  double get _amount => _parseAmount(_amountController.text);

  String? _amountError(double outstanding) {
    if (_amountController.text.trim().isEmpty) {
      return null;
    }
    if (_amount <= 0) {
      return 'Enter an amount greater than zero.';
    }
    if (_amount > outstanding) {
      return 'Amount cannot exceed outstanding balance (GH₵${outstanding.toStringAsFixed(2)}).';
    }
    return null;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amt = _amount;
    final outstanding =
        ref.watch(loanApplicationProvider)?.outstandingBalance ?? 0.0;
    final amountError = _amountError(outstanding);
    final canContinue = amt > 0 && amountError == null;
    final fee = amt * 0.01;
    final total = amt + fee;

    return AppScaffold(
      title: 'Repay Loan',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacitySafe(
                        0.18,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          color: theme.colorScheme.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Outstanding balance: GH₵${outstanding.toStringAsFixed(2)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ModernInput(
                    label: 'Amount to Pay',
                    hintText: 'e.g., 500',
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    prefixText: 'GH₵ ',
                    prefixIcon: Icons.payment,
                    onChanged: (_) => setState(() {}),
                  ),
                  if (amountError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      amountError,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Quick Amounts',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final int quick in [50, 100, 200])
                        FilterChip(
                          label: Text('GH₵$quick'),
                          onSelected: (_) => setState(
                            () => _amountController.text = quick.toString(),
                          ),
                          backgroundColor: theme.colorScheme.primaryContainer
                              .withOpacitySafe(0.2),
                          selectedColor: theme.colorScheme.primary
                              .withOpacitySafe(0.3),
                        ),
                      FilterChip(
                        label: Text(
                          'Full payoff (GH₵${outstanding.toStringAsFixed(2)})',
                        ),
                        onSelected: (_) => setState(
                          () => _amountController.text = outstanding
                              .toStringAsFixed(2),
                        ),
                        backgroundColor: theme.colorScheme.primaryContainer
                            .withOpacitySafe(0.2),
                        selectedColor: theme.colorScheme.primary
                            .withOpacitySafe(0.3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (amt > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withOpacitySafe(
                          0.2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.error.withOpacitySafe(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Processing Fee (1%)',
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            'GH₵${fee.toStringAsFixed(2)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer
                            .withOpacitySafe(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'GH₵${total.toStringAsFixed(2)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withOpacitySafe(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: theme.colorScheme.onSurface.withOpacitySafe(
                              0.45,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Enter an amount to see fee & total',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacitySafe(0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: canContinue
                    ? () {
                        ref
                            .read(loanApplicationProvider.notifier)
                            .recordPayment(_amount);
                        context.go('/payment');
                      }
                    : null,
                child: const Text('Continue to Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
