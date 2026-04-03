import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/action_triple_row.dart';
import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';
import '../../core/balance_card_shell.dart';
import '../../core/color_ext.dart';

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
    accent: const Color(0xFF43A047),
    target: 12000,
    balance: 7850,
    interest: 152.30,
    monthlyDeposit: 500,
    createdLabel: 'Created Feb 01, 2026',
    transactions: [
      {'type': 'Deposit', 'amount': 500.0, 'date': 'Mar 01, 2026'},
      {'type': 'Interest', 'amount': 12.3, 'date': 'Feb 28, 2026'},
      {'type': 'Deposit', 'amount': 450.0, 'date': 'Feb 20, 2026'},
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

  const SavingsDetailScreen({super.key, required this.savingsId});

  @override
  State<SavingsDetailScreen> createState() => _SavingsDetailScreenState();
}

class _SavingsDetailScreenState extends State<SavingsDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final savings =
        _savingsCatalog[widget.savingsId] ?? _savingsCatalog.values.first;
    final String title = savings.title;
    final double target = savings.target;
    final double balance = savings.balance;
    final progress = (balance / target).clamp(0.0, 1.0);
    final remaining = target - balance;
    final transactions = savings.transactions;
    return AppScaffold(
      title: '$title Details',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Balance Card
            BalanceCardShell(
              gradientColors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
              shadowColor: theme.colorScheme.primary.withOpacitySafe(0.30),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              textScaler: const TextScaler.linear(1.0),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Current balance',
                              textScaler: const TextScaler.linear(1.0),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.68),
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'GH₵${balance.toStringAsFixed(2)}',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.45,
                                  shadows: const [
                                    Shadow(
                                      color: Color(0x33000000),
                                      blurRadius: 10,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          savings.icon,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Target: GH₵${target.toStringAsFixed(0)} • Progress: ${(progress * 100).toStringAsFixed(1)}%',
                            textScaler: const TextScaler.linear(1.0),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _SavingsCardMeta(
                                label: 'Target',
                                value: 'GH₵${target.toStringAsFixed(0)}',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SavingsCardMeta(
                                label: 'Progress',
                                value:
                                    '${(progress * 100).toStringAsFixed(1)}%',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: _SavingsCardMeta(
                                label: 'Remaining',
                                value: 'GH₵${remaining.toStringAsFixed(0)}',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SavingsCardMeta(
                                label: 'Created',
                                value: savings.createdLabel.replaceAll(
                                  'Created ',
                                  '',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            ActionTripleRow(
              deposit: ActionItem(
                label: 'Deposit',
                icon: Icons.add_circle_outline,
                color: theme.colorScheme.primary,
                onTap: () => context.go('/payment'),
              ),
              withdraw: ActionItem(
                label: 'Withdraw',
                icon: Icons.remove_circle_outline,
                color: Theme.of(context).colorScheme.error,
                onTap: () => context.go('/savings/${savings.id}/withdraw'),
              ),
              transfer: ActionItem(
                label: 'Transfer',
                icon: Icons.swap_horiz_rounded,
                color: const Color(0xFF1B8A9B),
                onTap: () => context.go('/savings/transfer'),
              ),
            ),

            const SizedBox(height: 24),

            // Recent Activity Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Recent Activity',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Coming soon!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Transaction List
            AppCard(
              margin: EdgeInsets.zero,
              child: Column(
                children: transactions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tx = entry.value;
                  final isDeposit = tx['type'] == 'Deposit';
                  final isInterest = tx['type'] == 'Interest';
                  final isLast = index == transactions.length - 1;

                  // Mock extra detail fields
                  final refNumber =
                      'TXN${savings.id.hashCode.abs() % 90000 + 10000}${index + 1}';
                  final method = isInterest ? 'Auto-credited' : 'Mobile Money';
                  final status = 'Completed';
                  final amountLabel =
                      '${isDeposit || isInterest ? '+' : '-'}GH₵${(tx['amount'] as double).toStringAsFixed(2)}';
                  final amountColor = isDeposit || isInterest
                      ? Colors.green
                      : theme.colorScheme.error;

                  return Column(
                    children: [
                      InkWell(
                        onTap: () => showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (_) => _TxDetailSheet(
                            type: tx['type'] as String,
                            date: tx['date'] as String,
                            refNumber: refNumber,
                            method: method,
                            status: status,
                            amountLabel: amountLabel,
                            amountColor: amountColor,
                            isDeposit: isDeposit,
                            isInterest: isInterest,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isInterest
                                      ? theme.colorScheme.secondaryContainer
                                            .withOpacitySafe(0.5)
                                      : isDeposit
                                      ? theme.colorScheme.primaryContainer
                                            .withOpacitySafe(0.5)
                                      : theme.colorScheme.errorContainer
                                            .withOpacitySafe(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isInterest
                                      ? Icons.percent
                                      : isDeposit
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: isInterest
                                      ? theme.colorScheme.secondary
                                      : isDeposit
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.error,
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
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    Text(
                                      tx['date'] as String,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withOpacitySafe(0.6),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 110,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '${isDeposit || isInterest ? '+' : '-'}GH₵${(tx['amount'] as double).toStringAsFixed(2)}',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isDeposit || isInterest
                                          ? Colors.green
                                          : theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: theme.colorScheme.onSurface
                                    .withOpacitySafe(0.35),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!isLast) ...[
                        const SizedBox(height: 16),
                        Divider(
                          height: 1,
                          color: theme.colorScheme.outline.withOpacitySafe(0.2),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Quick Insights
            Text(
              'Insights',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            AppCard(
              margin: EdgeInsets.zero,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacitySafe(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'On track!',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You need to save GH₵${(remaining / 5).toStringAsFixed(0)} per month for 5 months to reach your goal.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacitySafe(
                              0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 80), // Extra space for FAB
          ],
        ),
      ),
    );
  }
}

class _TxDetailSheet extends StatelessWidget {
  final String type;
  final String date;
  final String refNumber;
  final String method;
  final String status;
  final String amountLabel;
  final Color amountColor;
  final bool isDeposit;
  final bool isInterest;

  const _TxDetailSheet({
    required this.type,
    required this.date,
    required this.refNumber,
    required this.method,
    required this.status,
    required this.amountLabel,
    required this.amountColor,
    required this.isDeposit,
    required this.isInterest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconData = isInterest
        ? Icons.percent
        : isDeposit
        ? Icons.arrow_downward
        : Icons.arrow_upward;
    final iconColor = isInterest
        ? theme.colorScheme.secondary
        : isDeposit
        ? theme.colorScheme.primary
        : theme.colorScheme.error;
    final iconBg = isInterest
        ? theme.colorScheme.secondaryContainer.withOpacitySafe(0.5)
        : isDeposit
        ? theme.colorScheme.primaryContainer.withOpacitySafe(0.5)
        : theme.colorScheme.errorContainer.withOpacitySafe(0.5);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withOpacitySafe(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Icon + title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    date,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacitySafe(0.55),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                amountLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: amountColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(
            height: 1,
            color: theme.colorScheme.outline.withOpacitySafe(0.15),
          ),
          const SizedBox(height: 16),
          _SheetRow(label: 'Reference No.', value: refNumber, theme: theme),
          const SizedBox(height: 12),
          _SheetRow(label: 'Payment Method', value: method, theme: theme),
          const SizedBox(height: 12),
          _SheetRow(
            label: 'Status',
            value: status,
            theme: theme,
            valueColor: Colors.green,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final Color? valueColor;

  const _SheetRow({
    required this.label,
    required this.value,
    required this.theme,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacitySafe(0.55),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _SavingsCardMeta extends StatelessWidget {
  final String label;
  final String value;
  const _SavingsCardMeta({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textScaler: const TextScaler.linear(1.0),
          style: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          textScaler: const TextScaler.linear(1.0),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
