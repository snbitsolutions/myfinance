import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';
import '../../core/color_ext.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/layout/responsive.dart';
import '../../core/modern_input.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/secure_auth_storage.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String? sourceLabel;
  final String? returnRoute;
  final double? initialAmount;
  final String? initialMethod;
  final String? savingsId;

  const PaymentScreen({
    super.key,
    this.sourceLabel,
    this.returnRoute,
    this.initialAmount,
    this.initialMethod,
    this.savingsId,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  static const _paymentMethods = ['Account', 'MoMo'];
  static const _momoProviders = [
    'MTN MoMo',
    'Telecel Cash',
    'AirtelTigo Money',
  ];

  static const _shareSourceAccounts = [
    'Member Savings',
    'Current Savings',
    'Available Accounts',
  ];

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _momoPhoneController = TextEditingController();
  String _method = _paymentMethods.first;
  String _selectedShareAccount = _shareSourceAccounts.first;
  String _selectedInternalAccount = _shareSourceAccounts.first;
  String _selectedMomoProvider = _momoProviders.first;

  @override
  void initState() {
    super.initState();
    if (_isDepositFlow) _method = 'MoMo';
    final initialAmount = widget.initialAmount;
    if (initialAmount != null && initialAmount > 0) {
      _amountController.text = initialAmount.toStringAsFixed(2);
    }
    if (widget.initialMethod == 'MoMo' || widget.initialMethod == 'Account') {
      if (!_isDepositFlow || widget.initialMethod == 'MoMo') {
        _method = widget.initialMethod!;
      }
    }
  }

  bool get _isDepositFlow =>
      (widget.sourceLabel ?? '').trim().toLowerCase() == 'deposit';

  bool _isValidMomoNumber(String value) {
    final phone = value.trim();
    return RegExp(r'^0\d{9}$').hasMatch(phone);
  }

  Future<void> _handleProceed() async {
    if (_isDepositFlow) {
      await _submitDeposit();
      return;
    }

    final message =
        'This payment is unavailable because no matching backend operation is configured. No payment has been made.';
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submitDeposit() async {
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    final phone = ref.read(authProvider).userEmail ?? '';
    final account = ref.read(authProvider).userId ?? '';
    final savingsId = widget.savingsId ?? 'member-savings';
    final pin = await SecureAuthStorage.instance.readPin() ?? '';

    if (amount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid deposit amount.')),
      );
      return;
    }

    if (phone.isEmpty || account.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your session is incomplete. Please sign in again.'),
        ),
      );
      return;
    }

    if (pin.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your PIN is required to complete this deposit.'),
        ),
      );
      return;
    }

    try {
      if (!mounted) return;
      final response = await ref
          .read(savingsServiceProvider)
          .depositSavings(
            phoneNumber: phone,
            accountNumber: account,
            pin: pin,
            amount: amount,
            savingsId: savingsId,
            channel: 'mtn-gh',
            username:
                ref
                    .read(userProfileProvider)
                    .valueOrNull?['name']
                    ?.toString() ??
                'Member',
          );

      if (!mounted) return;
      final transactionId = response['transaction_id']?.toString();
      final reference = response['reference']?.toString() ?? transactionId;
      final newBalanceValue = response['new_balance'];
      final newBalance = newBalanceValue is num
          ? newBalanceValue.toDouble()
          : double.tryParse(newBalanceValue?.toString() ?? '');
      final isPending = response['is_pending'] == true;

      ref.invalidate(savingsProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(userProfileProvider);

      final route = isPending ? '/payment-success' : '/payment-success';
      context.push(
        route,
        extra: {
          'amount': amount,
          'reference': reference,
          'account': 'Member Savings',
          'paymentMethod': 'MoMo',
          'newBalance': newBalance,
          'processedAt': DateTime.now().toIso8601String(),
          'message':
              response['message']?.toString() ??
              'Deposit submitted successfully.',
          'title': isPending ? 'Deposit Pending' : 'Deposit Successful',
          'isPending': isPending,
          'primaryActionLabel': 'Back to Savings',
          'primaryActionRoute': widget.returnRoute ?? '/savings',
          'secondaryActionLabel': 'Home',
          'secondaryActionRoute': '/home',
        },
      );
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      context.push(
        '/payment-failed',
        extra: {
          'returnRoute': widget.returnRoute ?? '/savings',
          'isDeposit': true,
          'amount': amount,
          'message': error.message,
        },
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Deposit failed: $error')));
      context.push(
        '/payment-failed',
        extra: {
          'returnRoute': widget.returnRoute ?? '/savings',
          'isDeposit': true,
          'amount': amount,
          'message': 'Deposit failed. Please try again.',
        },
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _momoPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amt = double.tryParse(_amountController.text) ?? 0;
    final isDepositFlow = _isDepositFlow;
    final useExistingAccount = widget.sourceLabel == 'Existing account';
    final isInvestment = widget.sourceLabel == 'Investment';
    final isMomo = !useExistingAccount && _method == 'MoMo';
    final isAccountMethod = !useExistingAccount && _method == 'Account';
    final momoPhone = _momoPhoneController.text.trim();
    final isMomoPhoneValid = _isValidMomoNumber(momoPhone);
    final showMomoPhoneError =
        isMomo && momoPhone.isNotEmpty && !isMomoPhoneValid;
    final canProceed =
        amt > 0 && (!isMomo || isMomoPhoneValid) && (!isDepositFlow || isMomo);
    final selectedSource = useExistingAccount
        ? _selectedShareAccount
        : _method == 'Account'
        ? '$_method ($_selectedInternalAccount)'
        : '$_method ($_selectedMomoProvider)';

    return AppScaffold(
      title: isDepositFlow
          ? 'Deposit'
          : useExistingAccount
          ? 'Buy Shares'
          : isInvestment
          ? 'Invest'
          : 'Payment',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= Responsive.medium;
          final content = SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                children: [
                  _PaymentHero(
                    theme: theme,
                    method: selectedSource,
                    subtitle: useExistingAccount || isInvestment
                        ? 'Selected account'
                        : 'Selected method',
                  ),

                  const SizedBox(height: 16),

                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PaymentSectionHeader(
                          title: isDepositFlow ? 'Deposit Amount' : 'Amount',
                          subtitle: isDepositFlow
                              ? 'Enter how much you want to deposit'
                              : 'Enter how much you want to pay',
                          icon: Icons.payments_rounded,
                          theme: theme,
                        ),
                        const SizedBox(height: 10),
                        ModernInput(
                          label: isDepositFlow
                              ? 'Amount to Deposit'
                              : 'Amount to Pay',
                          hintText: 'e.g., 500',
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          prefixText: 'GH₵ ',
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        _PaymentSectionHeader(
                          title: useExistingAccount
                              ? 'Source Account'
                              : 'Payment Method',
                          subtitle: useExistingAccount
                              ? 'Funds will be debited from your existing account.'
                              : isInvestment
                              ? 'Choose how you want to make this investment.'
                              : 'Choose your preferred payment method.',
                          icon: Icons.account_balance_wallet_rounded,
                          theme: theme,
                        ),
                        const SizedBox(height: 8),
                        if (useExistingAccount)
                          _PaymentDropdownShell(
                            theme: theme,
                            child: DropdownButton<String>(
                              value: _selectedShareAccount,
                              isExpanded: true,
                              underline: const SizedBox(),
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: theme.colorScheme.primary,
                              ),
                              items: _shareSourceAccounts
                                  .map(
                                    (account) => DropdownMenuItem(
                                      value: account,
                                      child: Row(
                                        children: [
                                          Icon(
                                            account == 'Member Savings'
                                                ? Icons.savings_rounded
                                                : account == 'Current Savings'
                                                ? Icons
                                                      .account_balance_wallet_rounded
                                                : Icons.account_tree_rounded,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(account),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(
                                () => _selectedShareAccount =
                                    v ?? _selectedShareAccount,
                              ),
                            ),
                          )
                        else
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
                              items: _paymentMethods
                                  .where(
                                    (method) =>
                                        !isDepositFlow || method == 'MoMo',
                                  )
                                  .map(
                                    (m) => DropdownMenuItem(
                                      value: m,
                                      child: Row(
                                        children: [
                                          Icon(
                                            m == 'Account'
                                                ? Icons
                                                      .account_balance_wallet_rounded
                                                : m == 'MoMo'
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
                              onChanged: (v) =>
                                  setState(() => _method = v ?? _method),
                            ),
                          ),
                        if (isAccountMethod) ...[
                          const SizedBox(height: 12),
                          _PaymentSectionHeader(
                            title: 'Account',
                            subtitle:
                                'Select the account to debit for this payment.',
                            icon: Icons.account_balance_rounded,
                            theme: theme,
                          ),
                          const SizedBox(height: 8),
                          _PaymentDropdownShell(
                            theme: theme,
                            child: DropdownButton<String>(
                              value: _selectedInternalAccount,
                              isExpanded: true,
                              underline: const SizedBox(),
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: theme.colorScheme.primary,
                              ),
                              items: _shareSourceAccounts
                                  .map(
                                    (account) => DropdownMenuItem(
                                      value: account,
                                      child: Row(
                                        children: [
                                          Icon(
                                            account == 'Member Savings'
                                                ? Icons.savings_rounded
                                                : account == 'Current Savings'
                                                ? Icons
                                                      .account_balance_wallet_rounded
                                                : Icons.account_tree_rounded,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(account),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(
                                () => _selectedInternalAccount =
                                    v ?? _selectedInternalAccount,
                              ),
                            ),
                          ),
                        ],
                        if (isMomo) ...[
                          const SizedBox(height: 12),
                          _PaymentSectionHeader(
                            title: 'MoMo Details',
                            subtitle:
                                'Select provider and enter recipient number.',
                            icon: Icons.phone_android_rounded,
                            theme: theme,
                          ),
                          const SizedBox(height: 8),
                          _PaymentDropdownShell(
                            theme: theme,
                            child: DropdownButton<String>(
                              value: _selectedMomoProvider,
                              isExpanded: true,
                              underline: const SizedBox(),
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: theme.colorScheme.primary,
                              ),
                              items: _momoProviders
                                  .map(
                                    (provider) => DropdownMenuItem(
                                      value: provider,
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.sim_card_rounded,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(provider),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(
                                () => _selectedMomoProvider =
                                    v ?? _selectedMomoProvider,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ModernInput(
                            label: 'MoMo Number',
                            hintText: 'e.g., 0241234567',
                            controller: _momoPhoneController,
                            keyboardType: TextInputType.phone,
                            onChanged: (value) {
                              final digitsOnly = value.replaceAll(
                                RegExp(r'\D'),
                                '',
                              );
                              final normalized = digitsOnly.length > 10
                                  ? digitsOnly.substring(0, 10)
                                  : digitsOnly;
                              if (normalized != value) {
                                _momoPhoneController.value = TextEditingValue(
                                  text: normalized,
                                  selection: TextSelection.collapsed(
                                    offset: normalized.length,
                                  ),
                                );
                              }
                              setState(() {});
                            },
                          ),
                          if (showMomoPhoneError) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Enter a valid Ghana number (10 digits, starts with 0).',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                        if (amt > 0) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withOpacitySafe(0.2),
                              border: Border.all(
                                color: theme.colorScheme.primary
                                    .withOpacitySafe(0.18),
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
                                      isDepositFlow
                                          ? 'Deposit Summary'
                                          : 'Payment Summary',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      isDepositFlow
                                          ? 'Amount entered'
                                          : 'Total',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    Text(
                                      'GH₵${amt.toStringAsFixed(2)}',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  useExistingAccount
                                      ? 'Source: $selectedSource'
                                      : isInvestment
                                      ? 'Investment method: $selectedSource'
                                      : 'Method: $selectedSource',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacitySafe(0.6),
                                  ),
                                ),
                                if (isMomo) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'MoMo number: ${momoPhone.isEmpty ? '-' : momoPhone}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacitySafe(0.6),
                                    ),
                                  ),
                                ],
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
                      onPressed: canProceed ? () => _handleProceed() : null,
                      icon: Icon(
                        isDepositFlow
                            ? Icons.arrow_forward_rounded
                            : Icons.info_outline_rounded,
                      ),
                      label: Text(
                        isDepositFlow ? 'Deposit now' : 'Payment unavailable',
                      ),
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

          if (isTablet) {
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: content,
              ),
            );
          }
          return content;
        },
      ),
    );
  }
}

class _PaymentHero extends StatelessWidget {
  final ThemeData theme;
  final String method;
  final String subtitle;

  const _PaymentHero({
    required this.theme,
    required this.method,
    required this.subtitle,
  });

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
                  '$subtitle: $method',
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
