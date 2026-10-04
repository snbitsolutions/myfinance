import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';
import '../../core/balance_card_shell.dart';
import '../../core/color_ext.dart';
import '../../core/layout/responsive.dart';
import '../../core/modern_input.dart';
import 'loan_application_provider.dart';

class RepaymentScreen extends ConsumerStatefulWidget {
  const RepaymentScreen({super.key});

  @override
  ConsumerState<RepaymentScreen> createState() => _RepaymentScreenState();
}

class _RepaymentScreenState extends ConsumerState<RepaymentScreen> {
  static const _momoProvider = 'Mobile Money';
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  void _setAmount(double value) {
    final text = value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
    _amountController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() {});
  }

  double _parseAmount(String value) {
    final normalized = value.replaceAll(',', '').trim();
    return double.tryParse(normalized) ?? 0;
  }

  double get _amount => _parseAmount(_amountController.text);

  bool _isValidPhone(String value) {
    final phone = value.trim();
    return RegExp(r'^0\d{9}$').hasMatch(phone);
  }

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
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amt = _amount;
    // Local application drafts are not backend loan records and cannot be
    // used as repayment identifiers.
    final LoanApplicationState? loan = null;
    final outstanding = loan?.outstandingBalance ?? 0.0;
    final amountError = _amountError(outstanding);
    final phoneText = _phoneController.text.trim();
    final showPhoneError = phoneText.isNotEmpty && !_isValidPhone(phoneText);

    return AppScaffold(
      title: 'Repay Loan',
      backRoute: '/loans',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= Responsive.medium;

          final noLoanContent = SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                AppCard(
                  child: Column(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Repayment data unavailable',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Repayment requires a loan account returned by the backend. A locally saved application draft is not an active loan.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacitySafe(
                            0.64,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => context.go('/apply-loan'),
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          label: const Text('Apply for a Loan'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

          if (loan == null || outstanding <= 0) {
            if (isTablet) {
              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: noLoanContent,
                ),
              );
            }

            return noLoanContent;
          }

          final innerContent = SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                BalanceCardShell(
                  gradientColors: const [Color(0xFFB86A14), Color(0xFFD98D1F)],
                  shadowColor: const Color(0x33B86A14),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_outlined,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Loan repayment',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.86),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'GH₵${outstanding.toStringAsFixed(2)}',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'Ref: ${loan.referenceNumber} • Plan: ${loan.repaymentPlan}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.payments_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Repayment Amount',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter an amount and choose where the repayment should be charged from.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacitySafe(
                            0.64,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
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
                        runSpacing: 8,
                        children: [
                          for (final ratio in [0.25, 0.5, 0.75])
                            FilterChip(
                              label: Text('${(ratio * 100).round()}%'),
                              onSelected: (_) =>
                                  _setAmount(outstanding * ratio),
                              backgroundColor: theme
                                  .colorScheme
                                  .primaryContainer
                                  .withOpacitySafe(0.2),
                              selectedColor: theme.colorScheme.primary
                                  .withOpacitySafe(0.3),
                            ),
                          FilterChip(
                            label: Text(
                              'Full payoff (GH₵${outstanding.toStringAsFixed(2)})',
                            ),
                            onSelected: (_) => _setAmount(outstanding),
                            backgroundColor: theme.colorScheme.primaryContainer
                                .withOpacitySafe(0.2),
                            selectedColor: theme.colorScheme.primary
                                .withOpacitySafe(0.3),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                            color: theme.colorScheme.outline.withOpacitySafe(
                              0.2,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.phone_android_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _momoProvider,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      ModernInput(
                        label: 'MoMo Phone Number',
                        hintText: 'e.g. 0241234567',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        onChanged: (_) => setState(() {}),
                        errorText: showPhoneError
                            ? 'Enter a valid 10-digit number (e.g. 024XXXXXXX)'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      if (amt > 0) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer
                                .withOpacitySafe(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.error.withOpacitySafe(
                                0.2,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Repayment fee',
                                style: theme.textTheme.bodySmall,
                              ),
                              Text(
                                'Unavailable',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withOpacitySafe(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  Text(
                                    'Unavailable',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (phoneText.isNotEmpty &&
                                  _isValidPhone(phoneText)) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Paying from',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    Text(
                                      phoneText,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
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
                                color: theme.colorScheme.onSurface
                                    .withOpacitySafe(0.45),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Repayment terms unavailable',
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

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.info_outline_rounded),
                    label: const Text('Repayment unavailable'),
                  ),
                ),
              ],
            ),
          );

          if (isTablet) {
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: innerContent,
              ),
            );
          }
          return innerContent;
        },
      ),
    );
  }
}
