import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import 'savings_model.dart';

class SavingsDepositScreen extends ConsumerStatefulWidget {
  final String savingsId;
  final Savings? savings;

  const SavingsDepositScreen({
    super.key,
    required this.savingsId,
    this.savings,
  });

  @override
  ConsumerState<SavingsDepositScreen> createState() =>
      _SavingsDepositScreenState();
}

class _SavingsDepositScreenState extends ConsumerState<SavingsDepositScreen> {
  static const List<int> _quickAmounts = [50, 100, 200, 500, 1000];

  final TextEditingController _amountController = TextEditingController();
  String _selectedMethod = 'Mobile Money';

  double get _amount {
    final cleaned = _amountController.text.replaceAll(',', '').trim();
    return double.tryParse(cleaned) ?? 0;
  }

  bool get _canContinue => _amount >= AppConstants.minimumSavingsDeposit;

  Map<String, dynamic>? _selectedAccount(List<Map<String, dynamic>> accounts) {
    for (final account in accounts) {
      final id =
          (account['id'] ??
                  account['product_id'] ??
                  account['savings_id'] ??
                  '')
              .toString();
      if (id == widget.savingsId) return account;
    }
    return null;
  }

  double? _readAmount(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '') ?? '');
  }

  void _applyQuickAmount(int value) {
    setState(() {
      _amountController.text = value.toString();
      _amountController.selection = TextSelection.fromPosition(
        TextPosition(offset: _amountController.text.length),
      );
    });
  }

  void _continueToPayment() {
    final savings = ref.read(savingsProvider).valueOrNull ?? const [];
    if (!_canContinue || _selectedAccount(savings) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _canContinue
                ? 'No matching savings account was found. Refresh and try again.'
                : 'The minimum deposit is GH₵ ${AppConstants.minimumSavingsDeposit.toStringAsFixed(2)}.',
          ),
        ),
      );
      return;
    }

    final returnRoute = '/savings/${widget.savingsId}';
    final destination = Uri(
      path: '/payment',
      queryParameters: {
        'returnRoute': returnRoute,
        'sourceLabel': 'Deposit',
        'amount': _amount.toStringAsFixed(2),
        'method': _selectedMethod == 'Mobile Money' ? 'MoMo' : 'Account',
        'savingsId': widget.savingsId,
      },
    ).toString();
    context.go(destination);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final savingsAsync = ref.watch(savingsProvider);
    final account = _selectedAccount(savingsAsync.valueOrNull ?? const []);
    final remoteSavings =
        widget.savings?.id == widget.savingsId &&
            widget.savings?.isRemote == true
        ? widget.savings
        : null;
    final accountTitle =
        (account?['pro_name'] ??
                account?['name'] ??
                account?['product_name'] ??
                remoteSavings?.title ??
                (savingsAsync.isLoading
                    ? 'Loading savings account'
                    : 'Savings account not found'))
            .toString()
            .trim();
    final accountNumber =
        (profile?['account_number'] ?? profile?['accountNumber'] ?? '')
            .toString()
            .trim();
    final balance =
        _readAmount(
          account?['balance'] ??
              account?['current_balance'] ??
              account?['amount'],
        ) ??
        (remoteSavings?.balanceAvailable == true
            ? remoteSavings?.balance
            : null);
    final canContinue =
        _canContinue && account != null && !savingsAsync.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      appBar: AppBar(
        title: const Text('Deposit'),
        backgroundColor: const Color(0xFFF4F7F4),
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          onPressed: () =>
              context.go('/savings/${widget.savingsId}', extra: widget.savings),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add money to savings',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: const Color(0xFF163A2A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Choose an amount and your preferred payment method.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6D7B73),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _AccountBalanceCard(
                      title: accountTitle,
                      accountNumber: accountNumber,
                      balance: balance,
                      isAvailable: account != null || remoteSavings != null,
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Deposit amount',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1D2B23),
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5F1E9),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 6,
                            ),
                            child: Text(
                              'Min. GH₵ ${AppConstants.minimumSavingsDeposit.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: Color(0xFF286B45),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE5EBE6)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'GH₵',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              color: primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                color: const Color(0xFF1D2B23),
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: '0.00',
                                hintStyle: theme.textTheme.headlineMedium
                                    ?.copyWith(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFB8C3BC),
                                    ),
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: Color(0xFF8A9990),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_amount > 0 &&
                        _amount < AppConstants.minimumSavingsDeposit)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'The minimum deposit is GH₵ ${AppConstants.minimumSavingsDeposit.toStringAsFixed(2)}.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    Wrap(
                      spacing: 9,
                      runSpacing: 9,
                      children: _quickAmounts.map((amount) {
                        final selected = _amount == amount;
                        return ChoiceChip(
                          label: Text('GH₵ $amount'),
                          selected: selected,
                          showCheckmark: false,
                          onSelected: (_) => _applyQuickAmount(amount),
                          labelStyle: TextStyle(
                            color: selected
                                ? Colors.white
                                : const Color(0xFF3B5144),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          backgroundColor: Colors.white,
                          selectedColor: primary,
                          side: BorderSide(
                            color: selected ? primary : const Color(0xFFE1E9E3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Pay with',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1D2B23),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _FundingOption(
                      icon: Icons.phone_android_rounded,
                      title: 'Mobile Money',
                      subtitle: 'MTN MoMo, Telecel Cash, AirtelTigo',
                      selected: _selectedMethod == 'Mobile Money',
                      onTap: () =>
                          setState(() => _selectedMethod = 'Mobile Money'),
                    ),
                    const SizedBox(height: 10),
                    _FundingOption(
                      icon: Icons.account_balance_rounded,
                      title: 'Bank account',
                      subtitle: 'Use Mobile Money; bank deposits are not enabled yet',
                      selected: _selectedMethod == 'Bank Account',
                      isDisabled: true,
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Bank deposits are not enabled yet. Use Mobile Money.',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FBF9),
                border: const Border(top: BorderSide(color: Color(0xFFE6ECE7))),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.035),
                    blurRadius: 16,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: canContinue ? _continueToPayment : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      disabledBackgroundColor: const Color(0xFFCAD5CD),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (_canContinue) ...[
                          const SizedBox(width: 8),
                          Text(
                            '· GH₵ ${_amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 19),
                      ],
                    ),
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

class _AccountBalanceCard extends StatelessWidget {
  final String title;
  final String accountNumber;
  final double? balance;
  final bool isAvailable;

  const _AccountBalanceCard({
    required this.title,
    required this.accountNumber,
    required this.balance,
    required this.isAvailable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF26734A), Color(0xFF164B35)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF164B35).withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -6,
            top: -28,
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: 132,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.savings_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DEPOSITING INTO',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isAvailable)
                    const Icon(
                      Icons.verified_rounded,
                      color: Color(0xFFB7E2C4),
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'AVAILABLE BALANCE',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'GH₵ ${(balance ?? 0).toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              if (accountNumber.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Account  $accountNumber',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _FundingOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _FundingOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? const Color(0xFF2E8B57)
                  : const Color(0xFFE3EAE4),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDisabled
                      ? const Color(0xFFF0F2F0)
                      : const Color(0xFFEAF3ED),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: isDisabled
                      ? const Color(0xFF89948D)
                      : const Color(0xFF286B45),
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDisabled
                            ? const Color(0xFF7C8980)
                            : const Color(0xFF25372B),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF7C8980),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDisabled)
                const Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFF99A39C),
                  size: 19,
                )
              else
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected
                      ? const Color(0xFF2E8B57)
                      : const Color(0xFFB6C0B9),
                  size: 21,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
