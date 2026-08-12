import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/exceptions/app_exceptions.dart';
import '../../core/models/loan_repayment_result.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/secure_auth_storage.dart';
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
  bool _isSubmitting = false;

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

  Future<void> _completeRepayment(
    BuildContext context,
    LoanApplicationState loan,
    double amount,
  ) async {
    final momoPhone = _phoneController.text.trim();
    final navigator = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final loanService = ref.read(loanServiceProvider);
      final auth = ref.read(authProvider);
      final pin = await SecureAuthStorage.instance.readPin() ?? '';
      final account = auth.userId ?? '';

      final response = await loanService.repayLoan(
        loanId: loan.referenceNumber,
        amount: amount,
        currentOutstanding: loan.outstandingBalance,
        accountNumber: account,
        pin: pin,
        paymentMethod: _momoProvider,
        momoPhoneNumber: momoPhone,
      );
      final result = LoanRepaymentResult.fromApiResponse(response);
      final safeAmount = result.amount > 0 ? result.amount : amount;
      final safeNewOutstanding = result.newOutstanding > 0
          ? result.newOutstanding
          : (loan.outstandingBalance - amount).clamp(
              0,
              loan.outstandingBalance,
            );

      ref
          .read(loanApplicationProvider.notifier)
          .recordPayment(result.amountApplied);

      if (!mounted) return;
      navigator.go(
        '/payment-success',
        extra: {
          'amount': safeAmount,
          'processedAt': result.processedAt.toIso8601String(),
          'reference': result.transactionId,
          'title': 'Loan Repayment Successful',
          'message':
              'Your repayment of GH₵${safeAmount.toStringAsFixed(2)} via ${result.paymentMethod} from $momoPhone was received. Remaining balance: GH₵${safeNewOutstanding.toStringAsFixed(2)}.',
          'primaryActionLabel': 'View Loan Details',
          'primaryActionRoute': '/loan-detail',
          'secondaryActionLabel': 'Back to Loans',
          'secondaryActionRoute': '/loans',
        },
      );
    } on AppException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  error.message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amt = _amount;
    final loan = ref.watch(loanApplicationProvider);
    final outstanding = loan?.outstandingBalance ?? 0.0;
    final amountError = _amountError(outstanding);
    final fee = amt * 0.01;
    final total = amt + fee;
    final balanceAfter = (outstanding - amt).clamp(0, outstanding);
    final phoneText = _phoneController.text.trim();
    final showPhoneError = phoneText.isNotEmpty && !_isValidPhone(phoneText);
    final canContinue =
        loan != null &&
        outstanding > 0 &&
        amt > 0 &&
        amountError == null &&
        _isValidPhone(phoneText);

    return AppScaffold(
      title: 'Repay Loan',
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
                        'No active loan to repay',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Apply for a loan first, then your repayment options will appear here.',
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
                                    'GH₵${total.toStringAsFixed(2)}',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Balance after payment',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  Text(
                                    'GH₵${balanceAfter.toStringAsFixed(2)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
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

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: canContinue
                        ? (_isSubmitting
                              ? null
                              : () {
                                  _completeRepayment(context, loan, amt);
                                })
                        : null,
                    icon: Icon(
                      _isSubmitting
                          ? Icons.hourglass_top_rounded
                          : canContinue
                          ? Icons.check_circle_outline_rounded
                          : amt > 0
                          ? Icons.phone_android_rounded
                          : Icons.payments_outlined,
                    ),
                    label: Text(
                      _isSubmitting
                          ? 'Processing repayment...'
                          : canContinue
                          ? 'Pay GH₵${total.toStringAsFixed(2)}'
                          : amt > 0
                          ? 'Enter your MoMo number to continue'
                          : 'Enter an amount to continue',
                    ),
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
