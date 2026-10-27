import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';
import '../../core/balance_card_shell.dart';
import '../../core/color_ext.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/layout/responsive.dart';
import '../../core/modern_input.dart';
import '../../core/providers/app_providers.dart';

class RepaymentScreen extends ConsumerStatefulWidget {
  const RepaymentScreen({super.key, this.loanId});

  final String? loanId;

  static String? normalizeLoanId(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;

    final normalized = text.replaceAll(RegExp(r'\s+'), '');
    return normalized.isEmpty ? null : normalized;
  }

  static Map<String, dynamic>? findLoanForRepayment(
    List<Map<String, dynamic>> loans,
    String? rawLoanId,
  ) {
    final normalizedTarget = normalizeLoanId(rawLoanId);
    if (normalizedTarget == null) return null;

    for (final loan in loans) {
      final candidates = [
        loan['loan_id'],
        loan['loanId'],
        loan['id'],
        loan['product_id'],
        loan['productId'],
      ];

      for (final candidate in candidates) {
        if (normalizeLoanId(candidate) == normalizedTarget) {
          return loan;
        }
      }
    }

    return null;
  }

  @override
  ConsumerState<RepaymentScreen> createState() => _RepaymentScreenState();
}

class _RepaymentScreenState extends ConsumerState<RepaymentScreen> {
  static const _repaymentNetworks = {
    'MTN Ghana': 'mtn-gh',
    'Tigo Ghana': 'tigo-gh',
    'Telecel': 'telecel-gh',
  };
  static const _repaymentProductId = '59656';
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedRepaymentChannel = 'mtn-gh';
  String? _selectedLoanId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final routeLoanId = widget.loanId ?? _routeLoanId();
    if (routeLoanId != null) {
      _selectedLoanId = routeLoanId;
    }
    final phone = ref.read(authProvider).userEmail?.trim() ?? '';
    _phoneController.text = _toLocalPhone(phone);
  }

  String? _routeLoanId() {
    final currentRoute = GoRouterState.of(
      context,
    ).uri.queryParameters['loanId'];
    final trimmed = currentRoute?.trim();
    return trimmed != null && trimmed.isNotEmpty ? trimmed : null;
  }

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

  String get _momoProvider => switch (_selectedRepaymentChannel) {
    'mtn-gh' => 'MTN MoMo',
    'tigo-gh' => 'Tigo MoMo',
    'telecel-gh' => 'Telecel Cash',
    _ => 'Mobile Money',
  };

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

  double _outstandingBalance(Map<String, dynamic> loan) {
    final value = loan['outstanding_balance'] ?? loan['balance'];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '') ?? '') ?? 0;
  }

  String _toLocalPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('233') && digits.length == 12) {
      return '0${digits.substring(3)}';
    }
    return digits;
  }

  String _toInternationalPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0') && digits.length == 10) {
      return '233${digits.substring(1)}';
    }
    return digits;
  }

  Future<void> _submitRepayment({
    required Map<String, dynamic> loan,
    required double outstanding,
  }) async {
    if (_isSubmitting ||
        _amount <= 0 ||
        _amount > outstanding ||
        !_isValidPhone(_phoneController.text)) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      final result = await ref
          .read(paymentServiceProvider)
          .repayLoan(
            phoneNumber: _toInternationalPhone(_phoneController.text),
            channel: _selectedRepaymentChannel,
            amount: _amount,
            currentOutstanding: outstanding,
            username: profile?['name']?.toString().trim().isNotEmpty == true
                ? profile!['name'].toString().trim()
                : 'Member',
            productId: _repaymentProductId,
          );
      if (!mounted) return;

      ref.invalidate(loansProvider);
      ref.invalidate(transactionsProvider);
      final isPending = result['is_pending'] == true;
      final loanName = loan['name']?.toString() ?? 'Loan';
      context.go(
        '/payment-success',
        extra: {
          'amount': _amount,
          'processedAt': DateTime.now().toIso8601String(),
          'reference': result['reference']?.toString(),
          'title': isPending ? 'Loan Repayment Pending' : 'Loan Repayment',
          'message': isPending
              ? 'Your repayment request was submitted and is awaiting provider confirmation.'
              : result['message']?.toString() ?? 'Repayment submitted.',
          'primaryActionLabel': 'Back to Loans',
          'primaryActionRoute': '/loans',
          'account': loanName,
          'paymentMethod': _momoProvider,
          'isPending': isPending,
        },
      );
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to submit the repayment. Check your transaction history before trying again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
    final loansAsync = ref.watch(loansProvider);
    final loans = loansAsync.valueOrNull ?? const <Map<String, dynamic>>[];
    final normalizedRequestedLoanId = RepaymentScreen.normalizeLoanId(
      widget.loanId,
    );
    final selectedLoan = normalizedRequestedLoanId == null
        ? null
        : RepaymentScreen.findLoanForRepayment(
            loans,
            normalizedRequestedLoanId,
          );
    final payableLoans = loans
        .where(
          (loan) =>
              (loan['loan_id']?.toString().trim().isNotEmpty ?? false) &&
              _outstandingBalance(loan) > 0,
        )
        .toList();
    final preferredLoanId =
        normalizedRequestedLoanId ??
        RepaymentScreen.normalizeLoanId(_selectedLoanId);
    Map<String, dynamic>? loan;
    if (payableLoans.isNotEmpty) {
      if (preferredLoanId == null) {
        loan = payableLoans.first;
      } else {
        for (final item in payableLoans) {
          if (RepaymentScreen.normalizeLoanId(item['loan_id']) ==
              preferredLoanId) {
            loan = item;
            break;
          }
        }

        if (loan == null && selectedLoan != null) {
          loan = selectedLoan;
        }
      }
    }
    final amt = _amount;
    final outstanding = loan == null ? 0.0 : _outstandingBalance(loan);
    final amountError = _amountError(outstanding);
    final phoneText = _phoneController.text.trim();
    final showPhoneError = phoneText.isNotEmpty && !_isValidPhone(phoneText);
    final canSubmit =
        loan != null &&
        amt > 0 &&
        amt <= outstanding &&
        _isValidPhone(phoneText) &&
        !_isSubmitting;

    return AppScaffold(
      title: 'Repay Loan',
      backRoute: '/loans',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= Responsive.medium;

          if (loansAsync.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (loansAsync.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load your loans. Please try again before making a repayment.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            );
          }

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
                if (payableLoans.length > 1) ...[
                  DropdownButtonFormField<String>(
                    initialValue: loan['loan_id'].toString(),
                    decoration: const InputDecoration(
                      labelText: 'Loan account',
                    ),
                    items: payableLoans
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item['loan_id'].toString(),
                            child: Text(item['name']?.toString() ?? 'Loan'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() {
                      _selectedLoanId = value;
                      _amountController.clear();
                    }),
                  ),
                  const SizedBox(height: 14),
                ],
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
                          'Loan account: ${loan['name']?.toString() ?? 'Loan'}',
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
                      DropdownButtonFormField<String>(
                        initialValue: _selectedRepaymentChannel,
                        decoration: const InputDecoration(
                          labelText: 'Mobile money network',
                          prefixIcon: Icon(Icons.phone_android_rounded),
                        ),
                        items: _repaymentNetworks.entries
                            .map(
                              (network) => DropdownMenuItem<String>(
                                value: network.value,
                                child: Text(network.key),
                              ),
                            )
                            .toList(),
                        onChanged: _isSubmitting
                            ? null
                            : (channel) {
                                if (channel == null) return;
                                setState(
                                  () => _selectedRepaymentChannel = channel,
                                );
                              },
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
                                'No separate fee',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
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
                                    'GH₵${amt.toStringAsFixed(2)}',
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
                    onPressed: canSubmit
                        ? () => _submitRepayment(
                            loan: loan!,
                            outstanding: outstanding,
                          )
                        : null,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.payments_outlined),
                    label: Text(
                      _isSubmitting ? 'Submitting...' : 'Submit Repayment',
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
