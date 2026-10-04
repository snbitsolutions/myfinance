import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  bool get _canContinue => _amount > 0;

  Map<String, dynamic>? _selectedAccount(Map<String, dynamic>? profile) {
    final savings = profile?['savings'];
    if (savings is! List) return null;

    for (final item in savings) {
      if (item is! Map) continue;
      final account = <String, dynamic>{
        for (final entry in item.entries) entry.key.toString(): entry.value,
      };
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

  String _readName(Map<String, dynamic>? profile) {
    final direct = profile?['name']?.toString().trim() ?? '';
    if (direct.isNotEmpty) return direct;

    final first = profile?['first_name']?.toString().trim() ?? '';
    final last = profile?['last_name']?.toString().trim() ?? '';
    return [first, last].where((value) => value.isNotEmpty).join(' ');
  }

  double _readAmount(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '') ?? '') ?? 0;
  }

  void _applyQuickAmount(int value) {
    setState(() {
      _amountController.text = value.toString();
      _amountController.selection = TextSelection.fromPosition(
        TextPosition(offset: _amountController.text.length),
      );
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.valueOrNull;
    final account = _selectedAccount(profile);
    final accountTitle =
        (account?['pro_name'] ??
                account?['name'] ??
                account?['product_name'] ??
                'Savings Account')
            .toString()
            .trim();
    final accountNumber =
        (profile?['account_number'] ?? profile?['accountNumber'] ?? '')
            .toString()
            .trim();
    final balance = _readAmount(
      account?['balance'] ?? account?['current_balance'],
    );
    final customerName = _readName(profile);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F3),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Deposit',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2E8B57),
              ),
            ),
            if (customerName.isNotEmpty)
              Text(
                customerName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: theme.colorScheme.primary,
        elevation: 0.5,
        leading: IconButton(
          onPressed: () => context.go(
            '/savings/${widget.savingsId}',
            extra: widget.savings,
          ),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: 'Back',
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Help',
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName.isEmpty
                          ? 'Savings Account'
                          : 'Deposit for $customerName',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF5EE),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.savings_rounded,
                              color: Color(0xFF2E8B57),
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  accountTitle,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  accountNumber.isEmpty
                                      ? 'Account number unavailable'
                                      : 'A/C $accountNumber',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Available balance',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'GH₵ ${balance.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2E8B57),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Amount',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF5EE),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Min GH₵ 10',
                            style: TextStyle(
                              color: Color(0xFF2E8B57),
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'GH₵',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2E8B57),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: '0.00',
                                hintStyle: TextStyle(
                                  color: Color(0xFFB7BABC),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 30,
                                ),
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _quickAmounts
                          .map(
                            (amount) => GestureDetector(
                              onTap: () => _applyQuickAmount(amount),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _amount == amount
                                      ? const Color(0xFF2E8B57)
                                      : const Color(0xFFF0F4F1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'GH₵ $amount',
                                  style: TextStyle(
                                    color: _amount == amount
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Funding Method',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          _FundingOption(
                            title: 'Mobile Money',
                            subtitle: 'MTN / Telecel / AirtelTigo',
                            selected: _selectedMethod == 'Mobile Money',
                            onTap: () => setState(
                              () => _selectedMethod = 'Mobile Money',
                            ),
                          ),
                          const Divider(height: 1),
                          _FundingOption(
                            title: 'Bank Account',
                            subtitle:
                                'Unavailable until bank deposits are connected',
                            selected: _selectedMethod == 'Bank Account',
                            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Bank-account deposits are not available yet. Use Mobile Money.',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          _SummaryRow(
                            label: 'Deposit amount',
                            value: 'GH₵ ${_amount.toStringAsFixed(2)}',
                          ),
                          const SizedBox(height: 8),
                          _SummaryRow(
                            label: 'Processing fee',
                            value: 'Shown by payment provider',
                          ),
                          const SizedBox(height: 10),
                          const Divider(),
                          const SizedBox(height: 10),
                          _SummaryRow(
                            label: 'Total charged',
                            value: 'Shown before provider confirmation',
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF7F0),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFCAE4D1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.shield_rounded,
                            color: Color(0xFF2E8B57),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'The payment provider will confirm any fees and the final transaction status.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: _canContinue
                            ? () {
                                final returnRoute =
                                    '/savings/${widget.savingsId}';
                                final destination = Uri(
                                  path: '/payment',
                                  queryParameters: {
                                    'returnRoute': returnRoute,
                                    'sourceLabel': 'Deposit',
                                    'amount': _amount.toStringAsFixed(2),
                                    'method': _selectedMethod == 'Mobile Money'
                                        ? 'MoMo'
                                        : 'Account',
                                    'savingsId': widget.savingsId,
                                  },
                                ).toString();
                                context.go(destination);
                              }
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2E8B57),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FundingOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _FundingOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFF2E8B57)
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2E8B57),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: isTotal ? Colors.black87 : Colors.black54,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
            color: isTotal ? const Color(0xFF2E8B57) : Colors.black87,
          ),
        ),
      ],
    );
  }
}
