import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_scaffold.dart';
import '../../../core/color_ext.dart';
import '../../../core/modern_input.dart';
import '../../../core/providers/app_providers.dart';
import 'withdrawal_model.dart';

class WithdrawalScreen extends ConsumerStatefulWidget {
  final String? savingsId;
  final WithdrawalData? initialData;

  const WithdrawalScreen({super.key, this.savingsId, this.initialData});

  @override
  ConsumerState<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends ConsumerState<WithdrawalScreen> {
  static const _quickAmounts = [500, 1000, 2000];
  static const _networks = ['MTN', 'Telecel', 'AirtelTigo'];

  late TextEditingController _amountController;
  late TextEditingController _phoneController;

  String _selectedNetwork = 'MTN';

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    _amountController = TextEditingController(
      text: data?.amount.toStringAsFixed(2) ?? '',
    );
    final sessionPhone = ref.read(authProvider).userEmail?.trim() ?? '';
    _phoneController = TextEditingController(
      text: data?.phoneNumber.isNotEmpty == true
          ? data!.phoneNumber
          : sessionPhone,
    );
    _selectedNetwork = switch (data?.channel) {
      'telecel-gh' => 'Telecel',
      'airteltigo-gh' => 'AirtelTigo',
      _ => 'MTN',
    };
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  double get _amount =>
      double.tryParse(_amountController.text.replaceAll(',', '').trim()) ?? 0.0;
  Map<String, dynamic>? get _account =>
      ref.watch(withdrawalAccountProvider(widget.savingsId ?? '')).valueOrNull;

  double? _number(String key) {
    final value = _account?[key];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  String _maskedAccountNumber(String accountNumber) {
    final trimmed = accountNumber.trim();
    if (trimmed.isEmpty) return 'Account number unavailable';
    final suffix = trimmed.length <= 4
        ? trimmed
        : trimmed.substring(trimmed.length - 4);
    return '•••• $suffix';
  }

  double? get _availableDaily {
    final limit = _number('daily_limit');
    final used = _number('used_daily_limit') ?? 0;
    return limit == null ? null : limit - used;
  }

  double? get _availableMonthly {
    final limit = _number('monthly_limit');
    final used = _number('used_monthly_limit') ?? 0;
    return limit == null ? null : limit - used;
  }

  bool get _canContinue {
    if (_account == null) return false;
    if (_amount <= 0) return false;
    final balance = _number('balance');
    if (balance != null && _amount > balance) return false;
    final daily = _availableDaily;
    final monthly = _availableMonthly;
    if (daily != null && _amount > daily) return false;
    if (monthly != null && _amount > monthly) return false;
    final phoneDigits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    return (phoneDigits.length == 10 && phoneDigits.startsWith('0')) ||
        (phoneDigits.length == 12 && phoneDigits.startsWith('233'));
  }

  void _selectQuickAmount(int amount) {
    _amountController.text = amount.toStringAsFixed(2);
    setState(() {});
  }

  void _continueToReview() {
    final channel = switch (_selectedNetwork) {
      'Telecel' => 'telecel-gh',
      'AirtelTigo' => 'airteltigo-gh',
      _ => 'mtn-gh',
    };
    final data = WithdrawalData(
      savingsId: widget.savingsId,
      amount: _amount,
      phoneNumber: _phoneController.text.trim(),
      method: 'Mobile Money ($_selectedNetwork)',
      channel: channel,
      fromAccount: (_account?['name'] ?? 'Savings Account').toString(),
      usedDailyLimit: _number('used_daily_limit') ?? 0,
      usedMonthlyLimit: _number('used_monthly_limit') ?? 0,
      availableBalance: _number('balance'),
      dailyLimit: _number('daily_limit'),
      monthlyLimit: _number('monthly_limit'),
    );
    context.push('/withdrawal/review', extra: data);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountAsync = ref.watch(
      withdrawalAccountProvider(widget.savingsId ?? ''),
    );
    if (accountAsync.isLoading) {
      return const AppScaffold(
        title: 'Withdraw',
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (accountAsync.hasError) {
      return AppScaffold(
        title: 'Withdraw',
        child: Center(child: Text('Unable to load this savings account.')),
      );
    }
    final balance = _number('balance');
    final dailyLimit = _number('daily_limit');
    final monthlyLimit = _number('monthly_limit');

    return AppScaffold(
      title: 'Withdraw',
      child: ColoredBox(
        color: const Color(0xFFF4F7F4),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Withdraw from savings',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: const Color(0xFF163A2A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Send funds to your mobile money account.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6D7B73),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _WithdrawalBalanceCard(
                      title: (_account?['name'] ?? 'Savings Account')
                          .toString(),
                      accountNumber: _maskedAccountNumber(
                        ref.read(authProvider).userId ?? '',
                      ),
                      balance: balance,
                    ),
                    const SizedBox(height: 26),
                    // Withdrawal Amount
                    Text(
                      'Withdrawal Amount',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ModernInput(
                      controller: _amountController,
                      label: 'GH₵',
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                    if (balance != null && _amount > balance) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Amount exceeds the available balance.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Quick Amounts
                    Wrap(
                      spacing: 9,
                      runSpacing: 9,
                      children: _quickAmounts.map((amount) {
                        final selected = _amount == amount;
                        return ChoiceChip(
                          label: Text('GH₵ $amount'),
                          selected: selected,
                          showCheckmark: false,
                          onSelected: (_) => _selectQuickAmount(amount),
                          labelStyle: TextStyle(
                            color: selected
                                ? Colors.white
                                : const Color(0xFF3B5144),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          backgroundColor: Colors.white,
                          selectedColor: theme.colorScheme.primary,
                          side: BorderSide(
                            color: selected
                                ? theme.colorScheme.primary
                                : const Color(0xFFE1E9E3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    // Withdrawal Limits
                    Text(
                      'Withdrawal Limits',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _WithdrawalCard(
                      child: dailyLimit == null && monthlyLimit == null
                          ? Text(
                              'Withdrawal limits are not available for this account.',
                              style: theme.textTheme.bodyMedium,
                            )
                          : Column(
                              children: [
                                if (dailyLimit != null)
                                  _LimitRow(
                                    label: 'Daily Limit',
                                    total: dailyLimit,
                                    used: _number('used_daily_limit') ?? 0,
                                    theme: theme,
                                  ),
                                if (dailyLimit != null && monthlyLimit != null)
                                  const Divider(height: 16),
                                if (monthlyLimit != null)
                                  _LimitRow(
                                    label: 'Monthly Limit',
                                    total: monthlyLimit,
                                    used: _number('used_monthly_limit') ?? 0,
                                    theme: theme,
                                  ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 16),
                    // Supported withdrawal network
                    Text(
                      'Mobile Money Network',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _WithdrawalCard(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedNetwork,
                        decoration: const InputDecoration(
                          labelText: 'Network',
                          border: InputBorder.none,
                        ),
                        items: _networks
                            .map(
                              (network) => DropdownMenuItem(
                                value: network,
                                child: Text('$network Mobile Money'),
                              ),
                            )
                            .toList(),
                        onChanged: (network) => setState(
                          () => _selectedNetwork = network ?? _selectedNetwork,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Bank account withdrawals are unavailable.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacitySafe(
                            0.65,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Destination Phone Number',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ModernInput(
                      controller: _phoneController,
                      label: 'Phone',
                      keyboardType: TextInputType.phone,
                      onChanged: (_) => setState(() {}),
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
                    onPressed: _canContinue ? _continueToReview : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      disabledBackgroundColor: const Color(0xFFCAD5CD),
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
                        if (_amount > 0) ...[
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

class _WithdrawalBalanceCard extends StatelessWidget {
  final String title;
  final String accountNumber;
  final double? balance;

  const _WithdrawalBalanceCard({
    required this.title,
    required this.accountNumber,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final availableBalance = balance;
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
            right: -8,
            top: -30,
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
                          'WITHDRAWING FROM',
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
                availableBalance == null
                    ? 'Unavailable'
                    : 'GH₵ ${availableBalance.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                accountNumber,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LimitRow extends StatelessWidget {
  final String label;
  final double total;
  final double used;
  final ThemeData theme;

  const _LimitRow({
    required this.label,
    required this.total,
    required this.used,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = total - used;
    final percentage = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacitySafe(0.7),
              ),
            ),
            Text(
              'GH₵ ${remaining.toStringAsFixed(2)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 6,
            backgroundColor: theme.colorScheme.primary.withOpacitySafe(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage > 0.7 ? Colors.red : theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Used: GH₵ ${used.toStringAsFixed(2)} | Remaining: GH₵ ${remaining.toStringAsFixed(2)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
          ),
        ),
      ],
    );
  }
}

class _WithdrawalCard extends StatelessWidget {
  final Widget child;

  const _WithdrawalCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3EAE4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}
