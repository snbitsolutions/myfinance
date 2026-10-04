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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // From Account
            _WithdrawalCard(
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacitySafe(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From Account',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacitySafe(
                              0.6,
                            ),
                          ),
                        ),
                        Text(
                          (_account?['name'] ?? 'Savings Account').toString(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _maskedAccountNumber(
                            ref.read(authProvider).userId ?? '',
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacitySafe(
                              0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Available Balance
            _WithdrawalCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Balance',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacitySafe(
                            0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        balance == null
                            ? 'Unavailable'
                            : 'GH₵ ${balance.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.trending_up_rounded,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _quickAmounts
                  .map(
                    (amount) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: OutlinedButton(
                          onPressed: () => _selectQuickAmount(amount),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('GH₵ $amount'),
                        ),
                      ),
                    ),
                  )
                  .toList(),
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
                    .map((network) => DropdownMenuItem(
                          value: network,
                          child: Text('$network Mobile Money'),
                        ))
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
                  color: theme.colorScheme.onSurface.withOpacitySafe(0.65),
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
            const SizedBox(height: 24),
            // Continue Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _canContinue ? _continueToReview : null,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
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
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacitySafe(0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacitySafe(0.12),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: theme.colorScheme.primary.withOpacitySafe(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
