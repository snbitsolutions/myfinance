import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_scaffold.dart';
import '../../core/providers/app_providers.dart';
import 'savings_model.dart';

class _SavingsDetailData {
  final String id;
  final String title;
  final IconData icon;
  final Color accent;
  final double? balance;
  final double? interest;
  final double? monthlyDeposit;
  final String createdLabel;
  final List<Map<String, dynamic>> transactions;
  final bool isRemote;

  const _SavingsDetailData({
    required this.id,
    required this.title,
    required this.icon,
    required this.accent,
    required this.balance,
    required this.interest,
    required this.monthlyDeposit,
    required this.createdLabel,
    required this.transactions,
    required this.isRemote,
  });
}

class SavingsDetailScreen extends ConsumerStatefulWidget {
  final String savingsId;
  final Savings? savings;

  const SavingsDetailScreen({super.key, required this.savingsId, this.savings});

  @override
  ConsumerState<SavingsDetailScreen> createState() =>
      _SavingsDetailScreenState();
}

class _SavingsDetailScreenState extends ConsumerState<SavingsDetailScreen> {
  double? _resolvedBalance;
  bool _isLoadingBalance = false;

  @override
  void initState() {
    super.initState();
    _refreshMissingBalance();
  }

  Future<void> _refreshMissingBalance() async {
    final records = ref.read(savingsProvider).valueOrNull ?? const [];
    final record = records.firstWhere(
      (item) =>
          (item['savings_id'] ?? item['id'] ?? item['product_id'])
              ?.toString()
              .trim() ==
          widget.savingsId,
      orElse: () => const <String, dynamic>{},
    );
    if (widget.savingsId.trim().isEmpty) return;

    final rawBalance =
        record['balance'] ?? record['current_balance'] ?? record['amount'];
    if (rawBalance != null) {
      final amount = _toAmount(rawBalance);
      if (mounted) {
        setState(() => _resolvedBalance = amount);
      }
      return;
    }

    final productId =
        (record['savings_id'] ?? record['id'] ?? record['product_id'])
            ?.toString()
            .trim();
    if (productId == null || productId.isEmpty) return;

    if (mounted) {
      setState(() => _isLoadingBalance = true);
    }

    try {
      final response = await ref
          .read(savingsServiceProvider)
          .getSavingsBalance(productId: productId);
      final balance = response['balance'];
      if (balance is num && mounted) {
        setState(() => _resolvedBalance = balance.toDouble());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingBalance = false);
      }
    }
  }

  void _showLocalGoalMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'This local goal is not a backend account. Deposit and withdrawal require a customer savings account.',
        ),
      ),
    );
  }

  void _showSavingsStatement(BuildContext context, _SavingsDetailData savings) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${savings.title} statement',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Current account activity and balance summary',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 18),
              _SavingsSummaryRow(
                label: 'Current balance',
                value: savings.balance == null
                    ? 'Unavailable'
                    : 'GH₵${savings.balance!.toStringAsFixed(2)}',
                icon: Icons.account_balance_wallet_outlined,
              ),
              _SavingsSummaryRow(
                label: 'Interest earned',
                value: savings.interest == null
                    ? 'Unavailable'
                    : 'GH₵${savings.interest!.toStringAsFixed(2)}',
                icon: Icons.trending_up_rounded,
              ),
              _SavingsSummaryRow(
                label: 'Monthly contribution',
                value: savings.monthlyDeposit == null
                    ? 'Unavailable'
                    : 'GH₵${savings.monthlyDeposit!.toStringAsFixed(2)}',
                icon: Icons.calendar_month_outlined,
              ),
              const SizedBox(height: 8),
              Text(
                'Statement download is not available yet.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionHistory(
    BuildContext context,
    List<Map<String, dynamic>> transactions,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.72,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            itemCount: transactions.length,
            separatorBuilder: (_, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              final isCredit = transaction['positive'] == true;
              final colorScheme = Theme.of(context).colorScheme;
              final transactionColor = isCredit
                  ? colorScheme.primary
                  : colorScheme.error;
              final amount = (transaction['amount'] as num?)?.toDouble() ?? 0;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: transactionColor.withValues(alpha: 0.12),
                  child: Icon(
                    isCredit
                        ? Icons.call_received_rounded
                        : Icons.call_made_rounded,
                    color: transactionColor,
                  ),
                ),
                title: Text(
                  transaction['type']?.toString() ?? 'Transaction',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${transaction['subtitle'] ?? 'Savings activity'} • ${transaction['date'] ?? ''}',
                ),
                trailing: Text(
                  '${isCredit ? '+' : '-'}GH₵${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: transactionColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showMoreActions(BuildContext context, _SavingsDetailData savings) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.receipt_long_rounded),
              title: const Text('Statement'),
              subtitle: const Text('View your balance summary'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showSavingsStatement(context, savings);
              },
            ),
          ],
        ),
      ),
    );
  }

  _SavingsDetailData _fromSavedGoal(Savings goal) {
    final accent = switch (goal.type) {
      SavingsType.memberSaving => const Color(0xFF43A047),
      SavingsType.currentSaving => const Color(0xFF3498DB),
      SavingsType.kiddySaving => const Color(0xFFFF6B9D),
      SavingsType.fixedDeposit => const Color(0xFF9B59B6),
    };

    return _SavingsDetailData(
      id: goal.id,
      title: goal.title,
      icon: goal.type.icon,
      accent: accent,
      balance: goal.balanceAvailable ? goal.balance : null,
      interest: goal.interestRate,
      monthlyDeposit: null,
      createdLabel:
          '${goal.createdAt.day.toString().padLeft(2, '0')}/'
          '${goal.createdAt.month.toString().padLeft(2, '0')}/'
          '${goal.createdAt.year}',
      transactions: const [],
      isRemote: goal.isRemote,
    );
  }

  Savings? _findLiveSavings() {
    final records = ref.read(savingsProvider).valueOrNull ?? const [];
    for (final record in records) {
      final recordId =
          (record['savings_id'] ?? record['id'] ?? record['product_id'])
              ?.toString()
              .trim();
      if (recordId == widget.savingsId) {
        final name =
            (record['name'] ??
                    record['product_name'] ??
                    record['account_name'] ??
                    'Savings Account')
                .toString();
        final balance = _toAmount(
          record['balance'] ?? record['current_balance'] ?? record['amount'],
        );
        return Savings(
          id: recordId!,
          title: name,
          balance: balance,
          target: _toAmount(
            record['target'] ??
                record['target_amount'] ??
                record['goal_amount'] ??
                0,
          ),
          type: SavingsType.memberSaving,
          interestRate: _toOptionalAmount(
            record['interest_rate'] ?? record['rate'],
          ),
          isRemote: true,
          balanceAvailable:
              record['balance'] != null ||
              record['current_balance'] != null ||
              record['amount'] != null,
        );
      }
    }
    return null;
  }

  double _toAmount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '') ?? '') ?? 0;
  }

  double? _toOptionalAmount(dynamic value) {
    if (value is num) return value.toDouble();
    if (value == null) return null;
    return double.tryParse(value.toString().replaceAll(',', ''));
  }

  String _maskedAccountNumber(String accountNumber) {
    final digits = accountNumber.trim();
    if (digits.isEmpty) return 'Unavailable';
    final suffix = digits.length <= 4
        ? digits
        : digits.substring(digits.length - 4);
    return '•••• $suffix';
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(savingsProvider);
    final liveSavings = widget.savings ?? _findLiveSavings();
    final baseSavings = liveSavings != null
        ? _fromSavedGoal(liveSavings)
        : _SavingsDetailData(
            id: widget.savingsId,
            title: 'Savings Account',
            icon: Icons.savings_rounded,
            accent: const Color(0xFF2F7C52),
            balance: null,
            interest: null,
            monthlyDeposit: null,
            createdLabel: 'Account details unavailable',
            transactions: const [],
            isRemote: false,
          );
    final savings = _SavingsDetailData(
      id: baseSavings.id,
      title: baseSavings.title,
      icon: baseSavings.icon,
      accent: baseSavings.accent,
      balance: _resolvedBalance ?? baseSavings.balance,
      interest: baseSavings.interest,
      monthlyDeposit: baseSavings.monthlyDeposit,
      createdLabel: baseSavings.createdLabel,
      transactions: baseSavings.transactions,
      isRemote: baseSavings.isRemote,
    );
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final accountNumber =
        (profile?['account_number'] ??
                profile?['accountNumber'] ??
                ref.read(authProvider).userId ??
                '')
            .toString();

    final title = savings.title;
    final transactionRows = savings.transactions;

    return AppScaffold(
      title: title,
      backRoute: '/savings',
      child: Container(
        color: const Color(0xFFF5F6F3),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoadingBalance)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Center(
                    child: Text(
                      'Refreshing balance…',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: const Color(0xFF2E8B57),
                      ),
                    ),
                  ),
                ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B6845), Color(0xFF2E8B57)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E8B57).withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -28,
                      bottom: -38,
                      child: Opacity(
                        opacity: 0.15,
                        child: Container(
                          width: 170,
                          height: 170,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Available Balance',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 9,
                                  height: 9,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: const [
                                Icon(
                                  Icons.star_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Primary Account',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          savings.balance == null
                              ? 'GH₵ —'
                              : 'GH₵ ${savings.balance!.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            const Text(
                              'Account Number',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _maskedAccountNumber(accountNumber),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ActionButton(
                      icon: Icons.call_received_rounded,
                      label: 'Deposit',
                      active: true,
                      onTap: () => savings.isRemote
                          ? context.go(
                              '/savings/${widget.savingsId}/deposit',
                              extra: widget.savings,
                            )
                          : _showLocalGoalMessage(),
                    ),
                    _ActionButton(
                      icon: Icons.call_made_rounded,
                      label: 'Withdraw',
                      color: Theme.of(context).colorScheme.error,
                      onTap: () => savings.isRemote
                          ? context.go('/savings/${widget.savingsId}/withdraw')
                          : _showLocalGoalMessage(),
                    ),
                    _ActionButton(
                      icon: Icons.swap_horiz,
                      label: 'Transfer',
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Savings transfers are unavailable until recipient verification and transfer processing are connected to the backend.',
                          ),
                        ),
                      ),
                    ),
                    _ActionButton(
                      icon: Icons.more_horiz_rounded,
                      label: 'More',
                      onTap: () => _showMoreActions(context, savings),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Account Overview',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _OverviewTile(
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: const Color(0xFF6E8A7A),
                      label: 'Total Deposits',
                      value: '—',
                      background: const Color(0xFFF0F7F3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _OverviewTile(
                      icon: Icons.call_made_rounded,
                      iconColor: const Color(0xFFDD7F7F),
                      label: 'Total Withdrawals',
                      value: '—',
                      background: const Color(0xFFF9F2F2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _OverviewTile(
                      icon: Icons.trending_up_rounded,
                      iconColor: const Color(0xFF7DAE78),
                      label: 'Interest Earned',
                      value: savings.interest != null
                          ? 'GH₵ ${savings.interest!.toStringAsFixed(2)}'
                          : '—',
                      background: const Color(0xFFF0F7EE),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Account Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    _DetailRow(
                      label: 'Account Type',
                      value: savings.title,
                      icon: Icons.account_balance_rounded,
                    ),
                    _DetailRow(
                      label: 'Opened On',
                      value: savings.isRemote
                          ? 'Unavailable'
                          : savings.createdLabel,
                      icon: Icons.calendar_today_rounded,
                    ),
                    _DetailRow(
                      label: 'Currency',
                      value: 'Ghana Cedi (GH₵)',
                      icon: Icons.currency_exchange_rounded,
                    ),
                    _DetailRow(
                      label: 'Status',
                      value: savings.isRemote ? 'Unavailable' : 'Local goal',
                      icon: Icons.check_circle_rounded,
                      valueColor: savings.isRemote
                          ? null
                          : const Color(0xFF2E8B57),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        _showTransactionHistory(context, transactionRows),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        color: Color(0xFF2E8B57),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7E5)),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.search_rounded,
                            color: Colors.grey,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Search transactions',
                            style: TextStyle(
                              color: Color(0xFF8A8F89),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 54,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7E5)),
                    ),
                    child: const Icon(
                      Icons.filter_list_rounded,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Today',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              ...transactionRows.map((tx) {
                final isPositive = tx['positive'] as bool;
                final amount = (tx['amount'] as num).toDouble();
                final transactionColor = isPositive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error;
                final amountText =
                    '${isPositive ? '+' : '-'}GH₵ ${amount.toStringAsFixed(2)}';
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: transactionColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isPositive
                              ? Icons.call_received_rounded
                              : Icons.call_made_rounded,
                          color: transactionColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx['type'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              tx['subtitle'] as String,
                              style: const TextStyle(
                                color: Color(0xFF7B827D),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              tx['date'] as String,
                              style: const TextStyle(
                                color: Color(0xFF8E9390),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            amountText,
                            style: TextStyle(
                              color: transactionColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF8A8F89),
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color? color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.active = false,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFE9F5ED)
                    : const Color(0xFFF4F5F4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD9E6DE)),
              ),
              child: Icon(
                icon,
                color:
                    color ??
                    (active ? const Color(0xFF2E8B57) : Colors.black87),
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color:
                    color ??
                    (active ? const Color(0xFF2E8B57) : Colors.black87),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color background;

  const _OverviewTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF5A625F)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF4E5552),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? const Color(0xFF1C2320),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SavingsSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SavingsSummaryRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
