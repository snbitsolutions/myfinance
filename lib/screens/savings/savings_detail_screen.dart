import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'savings_model.dart';

class _SavingsDetailData {
  final String id;
  final String title;
  final IconData icon;
  final Color accent;
  final double target;
  final double balance;
  final double interest;
  final double monthlyDeposit;
  final String createdLabel;
  final List<Map<String, dynamic>> transactions;

  const _SavingsDetailData({
    required this.id,
    required this.title,
    required this.icon,
    required this.accent,
    required this.target,
    required this.balance,
    required this.interest,
    required this.monthlyDeposit,
    required this.createdLabel,
    required this.transactions,
  });
}

final Map<String, _SavingsDetailData> _savingsCatalog = {
  'member-savings': _SavingsDetailData(
    id: 'member-savings',
    title: 'Member Savings',
    icon: Icons.groups_rounded,
    accent: const Color(0xFF2F7C52),
    target: 120000,
    balance: 45000.00,
    interest: 1250.00,
    monthlyDeposit: 5000,
    createdLabel: '15 Jan 2022',
    transactions: [
      {'type': 'Deposit', 'amount': 1000.0, 'date': '23 Aug 2026'},
      {'type': 'Withdrawal', 'amount': 500.0, 'date': '20 Aug 2026'},
      {'type': 'Deposit', 'amount': 2000.0, 'date': '18 Aug 2026'},
      {'type': 'Transfer In', 'amount': 5000.0, 'date': '15 Aug 2026'},
      {'type': 'Interest Credit', 'amount': 150.0, 'date': '08 Aug 2026'},
    ],
  ),
  'current-savings': _SavingsDetailData(
    id: 'current-savings',
    title: 'Current Savings',
    icon: Icons.account_balance_wallet_rounded,
    accent: const Color(0xFF3498DB),
    target: 6000,
    balance: 2140,
    interest: 24.80,
    monthlyDeposit: 220,
    createdLabel: 'Created Jan 12, 2026',
    transactions: [
      {'type': 'Deposit', 'amount': 220.0, 'date': 'Mar 03, 2026'},
      {'type': 'Deposit', 'amount': 180.0, 'date': 'Feb 18, 2026'},
      {'type': 'Interest', 'amount': 4.8, 'date': 'Feb 15, 2026'},
    ],
  ),
  'kiddy-savings': _SavingsDetailData(
    id: 'kiddy-savings',
    title: 'Kiddy Savings',
    icon: Icons.child_care_rounded,
    accent: const Color(0xFFFF6B9D),
    target: 10000,
    balance: 3650,
    interest: 61.20,
    monthlyDeposit: 300,
    createdLabel: 'Created Dec 20, 2025',
    transactions: [
      {'type': 'Deposit', 'amount': 300.0, 'date': 'Mar 01, 2026'},
      {'type': 'Deposit', 'amount': 250.0, 'date': 'Feb 10, 2026'},
      {'type': 'Interest', 'amount': 11.2, 'date': 'Feb 01, 2026'},
    ],
  ),
  'fixed-savings': _SavingsDetailData(
    id: 'fixed-savings',
    title: 'Fixed Savings',
    icon: Icons.lock_clock_rounded,
    accent: const Color(0xFF9B59B6),
    target: 25000,
    balance: 15400,
    interest: 480.00,
    monthlyDeposit: 1200,
    createdLabel: 'Created Nov 15, 2025',
    transactions: [
      {'type': 'Deposit', 'amount': 1200.0, 'date': 'Mar 01, 2026'},
      {'type': 'Interest', 'amount': 80.0, 'date': 'Feb 28, 2026'},
      {'type': 'Deposit', 'amount': 1000.0, 'date': 'Feb 01, 2026'},
    ],
  ),
  'emergency-fund': _SavingsDetailData(
    id: 'emergency-fund',
    title: 'Emergency Fund',
    icon: Icons.medical_information_rounded,
    accent: const Color(0xFFE74C3C),
    target: 2000,
    balance: 1200,
    interest: 45.50,
    monthlyDeposit: 150,
    createdLabel: 'Created Jan 15, 2026',
    transactions: [
      {'type': 'Deposit', 'amount': 200.0, 'date': 'Jan 20, 2026'},
      {'type': 'Interest', 'amount': 5.50, 'date': 'Jan 15, 2026'},
      {'type': 'Deposit', 'amount': 150.0, 'date': 'Jan 10, 2026'},
    ],
  ),
  'goal-savings': _SavingsDetailData(
    id: 'goal-savings',
    title: 'Goal Savings',
    icon: Icons.flag_rounded,
    accent: const Color(0xFF16A085),
    target: 8000,
    balance: 2950,
    interest: 73.10,
    monthlyDeposit: 400,
    createdLabel: 'Created Jan 05, 2026',
    transactions: [
      {'type': 'Deposit', 'amount': 400.0, 'date': 'Mar 05, 2026'},
      {'type': 'Deposit', 'amount': 350.0, 'date': 'Feb 05, 2026'},
      {'type': 'Interest', 'amount': 8.1, 'date': 'Feb 01, 2026'},
    ],
  ),
  'vacation-savings': _SavingsDetailData(
    id: 'vacation-savings',
    title: 'Vacation',
    icon: Icons.flight_takeoff_rounded,
    accent: const Color(0xFFF39C12),
    target: 7000,
    balance: 3200,
    interest: 55.00,
    monthlyDeposit: 350,
    createdLabel: 'Created Dec 01, 2025',
    transactions: [
      {'type': 'Deposit', 'amount': 350.0, 'date': 'Mar 01, 2026'},
      {'type': 'Deposit', 'amount': 300.0, 'date': 'Feb 01, 2026'},
      {'type': 'Interest', 'amount': 7.0, 'date': 'Jan 31, 2026'},
    ],
  ),
  'education-savings': _SavingsDetailData(
    id: 'education-savings',
    title: 'Education',
    icon: Icons.school_rounded,
    accent: const Color(0xFF8E44AD),
    target: 15000,
    balance: 6400,
    interest: 121.40,
    monthlyDeposit: 650,
    createdLabel: 'Created Oct 10, 2025',
    transactions: [
      {'type': 'Deposit', 'amount': 650.0, 'date': 'Mar 01, 2026'},
      {'type': 'Deposit', 'amount': 600.0, 'date': 'Feb 01, 2026'},
      {'type': 'Interest', 'amount': 16.4, 'date': 'Jan 31, 2026'},
    ],
  ),
  'custom-savings': _SavingsDetailData(
    id: 'custom-savings',
    title: 'Custom Savings',
    icon: Icons.add_circle_outline_rounded,
    accent: const Color(0xFF34495E),
    target: 5000,
    balance: 900,
    interest: 14.90,
    monthlyDeposit: 120,
    createdLabel: 'Created Mar 01, 2026',
    transactions: [
      {'type': 'Deposit', 'amount': 200.0, 'date': 'Mar 08, 2026'},
      {'type': 'Deposit', 'amount': 150.0, 'date': 'Mar 05, 2026'},
      {'type': 'Interest', 'amount': 1.9, 'date': 'Mar 04, 2026'},
    ],
  ),
};

class SavingsDetailScreen extends StatefulWidget {
  final String savingsId;
  final Savings? savings;

  const SavingsDetailScreen({super.key, required this.savingsId, this.savings});

  @override
  State<SavingsDetailScreen> createState() => _SavingsDetailScreenState();
}

class _SavingsDetailScreenState extends State<SavingsDetailScreen> {
  _SavingsDetailData _fromSavedGoal(Savings goal) {
    final accent = switch (goal.type) {
      SavingsType.memberSaving => const Color(0xFF43A047),
      SavingsType.currentSaving => const Color(0xFF3498DB),
      SavingsType.kiddySaving => const Color(0xFFFF6B9D),
      SavingsType.fixedDeposit => const Color(0xFF9B59B6),
    };

    final today = DateTime.now();
    final createdLabel = 'Created ${today.day}/${today.month}/${today.year}';

    return _SavingsDetailData(
      id: goal.id,
      title: goal.title,
      icon: goal.type.icon,
      accent: accent,
      target: goal.target,
      balance: goal.balance,
      interest: goal.interestRate ?? 0,
      monthlyDeposit: (goal.target / 12).clamp(0, goal.target),
      createdLabel: createdLabel,
      transactions: const [],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final savings = widget.savings != null
        ? _fromSavedGoal(widget.savings!)
        : _savingsCatalog[widget.savingsId] ??
              _savingsCatalog['custom-savings'] ??
              _fromSavedGoal(
                Savings(
                  id: widget.savingsId,
                  title: 'Savings Goal',
                  balance: 0,
                  target: 1,
                  type: SavingsType.memberSaving,
                ),
              );

    final title = savings.title;
    final transactionRows = [
      {
        'type': 'Deposit',
        'subtitle': 'Counter Deposit',
        'amount': 1000.0,
        'date': '23 Aug 2026',
        'icon': Icons.arrow_downward,
        'color': const Color(0xFF1FA66E),
        'positive': true,
      },
      {
        'type': 'Withdrawal',
        'subtitle': 'Cash Withdrawal',
        'amount': 500.0,
        'date': '20 Aug 2026',
        'icon': Icons.arrow_upward,
        'color': const Color(0xFFE57373),
        'positive': false,
      },
      {
        'type': 'Deposit',
        'subtitle': 'Mobile Deposit',
        'amount': 2000.0,
        'date': '18 Aug 2026',
        'icon': Icons.arrow_downward,
        'color': const Color(0xFF1FA66E),
        'positive': true,
      },
      {
        'type': 'Transfer In',
        'subtitle': 'From Investments A/C',
        'amount': 5000.0,
        'date': '15 Aug 2026',
        'icon': Icons.swap_horiz,
        'color': const Color(0xFF5DA9E9),
        'positive': true,
      },
      {
        'type': 'Interest Credit',
        'subtitle': 'Interest for Jul 2026',
        'amount': 150.0,
        'date': '08 Aug 2026',
        'icon': Icons.account_balance_wallet_outlined,
        'color': const Color(0xFFB4C4A6),
        'positive': true,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F3),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 26,
                    ),
                    splashRadius: 22,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 31,
                        letterSpacing: -0.5,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.black87,
                        ),
                      ),
                      Positioned(
                        right: 3,
                        top: 5,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3D8B52),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '3',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            color: const Color(
                              0xFF2E8B57,
                            ).withValues(alpha: 0.25),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                              const Text(
                                'GH₵ 45,000.00',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.18,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_upward_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '8.4%',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'vs last month',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
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
                                      color: Colors.white.withValues(
                                        alpha: 0.18,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      '•••• 4839',
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
                            icon: Icons.arrow_downward,
                            label: 'Deposit',
                            active: true,
                            onTap: () => context.go('/savings/${widget.savingsId}/deposit'),
                          ),
                          _ActionButton(
                            icon: Icons.arrow_upward,
                            label: 'Withdraw',
                            onTap: () {},
                          ),
                          _ActionButton(
                            icon: Icons.swap_horiz,
                            label: 'Transfer',
                            onTap: () {},
                          ),
                          _ActionButton(
                            icon: Icons.receipt_long_rounded,
                            label: 'Statement',
                            onTap: () {},
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
                            value: 'GH₵ 75,000.00',
                            background: const Color(0xFFF0F7F3),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _OverviewTile(
                            icon: Icons.arrow_upward_rounded,
                            iconColor: const Color(0xFFDD7F7F),
                            label: 'Total Withdrawals',
                            value: 'GH₵ 30,000.00',
                            background: const Color(0xFFF9F2F2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _OverviewTile(
                            icon: Icons.trending_up_rounded,
                            iconColor: const Color(0xFF7DAE78),
                            label: 'Interest Earned',
                            value: 'GH₵ 1,250.00',
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
                            value: 'Member Savings',
                            icon: Icons.account_balance_rounded,
                          ),
                          _DetailRow(
                            label: 'Opened On',
                            value: '15 Jan 2022',
                            icon: Icons.calendar_today_rounded,
                          ),
                          _DetailRow(
                            label: 'Currency',
                            value: 'Ghana Cedi (GH₵)',
                            icon: Icons.currency_exchange_rounded,
                          ),
                          _DetailRow(
                            label: 'Status',
                            value: 'Active',
                            icon: Icons.check_circle_rounded,
                            valueColor: const Color(0xFF2E8B57),
                          ),
                          _DetailRow(
                            label: 'Next Interest Payout',
                            value: '30 Sep 2026',
                            icon: Icons.schedule_rounded,
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
                          onPressed: () {},
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
                              border: Border.all(
                                color: const Color(0xFFE5E7E5),
                              ),
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
                                color: (tx['color'] as Color).withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                tx['icon'] as IconData,
                                color: tx['color'] as Color,
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
                                    color: isPositive
                                        ? const Color(0xFF2E8B57)
                                        : const Color(0xFFDA5F5F),
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
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.active = false,
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
                color: active ? const Color(0xFFE9F5ED) : const Color(0xFFF4F5F4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: active ? const Color(0xFF2E8B57) : Colors.black87,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: active ? const Color(0xFF2E8B57) : Colors.black87,
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

