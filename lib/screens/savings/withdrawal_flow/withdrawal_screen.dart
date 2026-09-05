import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_card.dart';
import '../../../core/app_scaffold.dart';
import '../../../core/color_ext.dart';
import '../../../core/modern_input.dart';
import 'withdrawal_model.dart';

class WithdrawalScreen extends StatefulWidget {
  final String? savingsId;
  final WithdrawalData? initialData;

  const WithdrawalScreen({
    super.key,
    this.savingsId,
    this.initialData,
  });

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  static const _quickAmounts = [500, 1000, 2000];
  static const _dailyLimit = 5000.0;
  static const _monthlyLimit = 20000.0;

  late TextEditingController _amountController;
  late TextEditingController _phoneController;

  String _selectedMethod = 'Mobile Money';
  late double _usedDailyLimit;
  late double _usedMonthlyLimit;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    _amountController = TextEditingController(text: data?.amount.toStringAsFixed(2) ?? '');
    _phoneController = TextEditingController(text: data?.phoneNumber ?? '');
    _selectedMethod = data?.method ?? 'Mobile Money';
    _usedDailyLimit = data?.usedDailyLimit ?? 1000.0;
    _usedMonthlyLimit = data?.usedMonthlyLimit ?? 5000.0;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountController.text) ?? 0.0;
  double get _availableDaily => _dailyLimit - _usedDailyLimit;
  double get _availableMonthly => _monthlyLimit - _usedMonthlyLimit;

  bool get _canContinue {
    if (_amount <= 0) return false;
    if (_amount > _availableDaily) return false;
    if (_amount > _availableMonthly) return false;
    return _phoneController.text.trim().isNotEmpty;
  }

  void _selectQuickAmount(int amount) {
    _amountController.text = amount.toStringAsFixed(2);
    setState(() {});
  }

  void _continueToReview() {
    final data = WithdrawalData(
      savingsId: widget.savingsId,
      amount: _amount,
      phoneNumber: _phoneController.text.trim(),
      method: _selectedMethod,
      fromAccount: 'Member Savings',
      usedDailyLimit: _usedDailyLimit,
      usedMonthlyLimit: _usedMonthlyLimit,
    );
    context.push('/withdrawal/review', extra: data);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Withdraw',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // From Account
            AppCard(
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
                            color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
                          ),
                        ),
                        Text(
                          'Member Savings',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '•••• 4839',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
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
            AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Balance',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'GH₵ 45,000.00',
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
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ModernInput(
              controller: _amountController,
              label: 'GH₵',
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            // Quick Amounts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _quickAmounts
                  .map((amount) => Expanded(
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
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            // Withdrawal Limits
            Text(
              'Withdrawal Limits',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                children: [
                  _LimitRow(
                    label: 'Daily Limit',
                    total: _dailyLimit,
                    used: _usedDailyLimit,
                    theme: theme,
                  ),
                  const Divider(height: 16),
                  _LimitRow(
                    label: 'Monthly Limit',
                    total: _monthlyLimit,
                    used: _usedMonthlyLimit,
                    theme: theme,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Withdrawal Method
            Text(
              'Withdrawal Method',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            AppCard(
              child: Column(
                children: [
                  _MethodRadio(
                    label: 'Mobile Money',
                    icon: Icons.phone_rounded,
                    value: 'Mobile Money',
                    groupValue: _selectedMethod,
                    onChanged: (val) => setState(() => _selectedMethod = val ?? ''),
                  ),
                  const Divider(height: 16),
                  _MethodRadio(
                    label: 'Bank Account',
                    icon: Icons.account_balance_rounded,
                    value: 'Bank Account',
                    groupValue: _selectedMethod,
                    onChanged: (val) => setState(() => _selectedMethod = val ?? ''),
                  ),
                ],
              ),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    final percentage = used / total;

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

class _MethodRadio extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _MethodRadio({
    required this.label,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // ignore: deprecated_member_use
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
            ),
            Icon(icon, size: 24, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
