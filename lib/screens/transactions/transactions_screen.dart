import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/color_ext.dart';
import '../../core/app_scaffold.dart';
import '../../core/app_card.dart';
import 'transaction_model.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _selectedFilter = 'All';
  String _selectedPeriod = 'This Month';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Mock transactions with more variety
    final allTransactions = [
      AppTransaction(
        id: '1',
        title: 'Savings Deposit',
        description: 'Emergency Fund',
        amount: 500,
        type: TransactionType.deposit,
        date: DateTime.now(),
        category: 'Savings',
      ),
      AppTransaction(
        id: '2',
        title: 'Loan Repayment',
        description: 'Personal Loan - Monthly Payment',
        amount: 300,
        type: TransactionType.repayment,
        date: DateTime.now().subtract(const Duration(days: 1)),
        category: 'Loans',
      ),
      AppTransaction(
        id: '3',
        title: 'Coffee Shop',
        description: 'Starbucks - Downtown',
        amount: 10.50,
        type: TransactionType.withdrawal,
        date: DateTime.now().subtract(const Duration(days: 2)),
        category: 'Food & Drink',
      ),
      AppTransaction(
        id: '4',
        title: 'Salary Deposit',
        description: 'Monthly Salary',
        amount: 2500,
        type: TransactionType.deposit,
        date: DateTime.now().subtract(const Duration(days: 5)),
        category: 'Income',
      ),
      AppTransaction(
        id: '5',
        title: 'Grocery Shopping',
        description: 'Shoprite',
        amount: 85.00,
        type: TransactionType.withdrawal,
        date: DateTime.now().subtract(const Duration(days: 7)),
        category: 'Shopping',
      ),
      AppTransaction(
        id: '6',
        title: 'Fixed Deposit',
        description: '12-Month FD',
        amount: 2000,
        type: TransactionType.deposit,
        date: DateTime.now().subtract(const Duration(days: 10)),
        category: 'Savings',
      ),
      AppTransaction(
        id: '7',
        title: 'Electricity Bill',
        description: 'ECG Payment',
        amount: 120,
        type: TransactionType.withdrawal,
        date: DateTime.now().subtract(const Duration(days: 12)),
        category: 'Bills',
      ),
      AppTransaction(
        id: '8',
        title: 'Interest Earned',
        description: 'Savings Account Interest',
        amount: 15.50,
        type: TransactionType.deposit,
        date: DateTime.now().subtract(const Duration(days: 15)),
        category: 'Interest',
      ),
    ];

    // Filter transactions
    final transactions = allTransactions.where((tx) {
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Income') {
        return tx.type == TransactionType.deposit;
      }
      if (_selectedFilter == 'Expense') {
        return tx.type == TransactionType.withdrawal;
      }
      if (_selectedFilter == 'Repayment') {
        return tx.type == TransactionType.repayment;
      }
      return true;
    }).toList();

    // Calculate totals
    final totalIncome = allTransactions
        .where((tx) => tx.type == TransactionType.deposit)
        .fold<double>(0, (sum, tx) => sum + tx.amount);
    final totalExpense = allTransactions
        .where((tx) => tx.type == TransactionType.withdrawal)
        .fold<double>(0, (sum, tx) => sum + tx.amount);
    final totalRepayment = allTransactions
        .where((tx) => tx.type == TransactionType.repayment)
        .fold<double>(0, (sum, tx) => sum + tx.amount);

    // Group transactions by date
    final groupedTransactions = <String, List<AppTransaction>>{};
    for (var tx in transactions) {
      final dateKey = _getDateKey(tx.date);
      if (!groupedTransactions.containsKey(dateKey)) {
        groupedTransactions[dateKey] = [];
      }
      groupedTransactions[dateKey]!.add(tx);
    }

    return AppScaffold(
      title: 'Transactions',
      child: transactions.isEmpty
          ? _buildEmptyState(theme)
          : Column(
              children: [
                // Summary Cards
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      _buildSummaryCard(
                        theme,
                        'Income',
                        totalIncome,
                        Icons.arrow_downward,
                        Colors.green,
                      ),
                      const SizedBox(width: 12),
                      _buildSummaryCard(
                        theme,
                        'Expense',
                        totalExpense,
                        Icons.arrow_upward,
                        Colors.red,
                      ),
                      const SizedBox(width: 12),
                      _buildSummaryCard(
                        theme,
                        'Repayment',
                        totalRepayment,
                        Icons.credit_card,
                        Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      _buildSummaryCard(
                        theme,
                        'Balance',
                        totalIncome - totalExpense - totalRepayment,
                        Icons.account_balance_wallet,
                        theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),

                // Filter Chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filter',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface
                                  .withOpacitySafe(0.7),
                            ),
                          ),
                          PopupMenuButton<String>(
                            initialValue: _selectedPeriod,
                            onSelected: (value) =>
                                setState(() => _selectedPeriod = value),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedPeriod,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                              ],
                            ),
                            itemBuilder: (context) =>
                                [
                                      'Today',
                                      'This Week',
                                      'This Month',
                                      'Last Month',
                                      'All Time',
                                    ]
                                    .map(
                                      (period) => PopupMenuItem(
                                        value: period,
                                        child: Text(period),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(theme, 'All'),
                            _buildFilterChip(theme, 'Income'),
                            _buildFilterChip(theme, 'Expense'),
                            _buildFilterChip(theme, 'Repayment'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Transactions List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: groupedTransactions.length,
                    itemBuilder: (context, index) {
                      final dateKey = groupedTransactions.keys.elementAt(index);
                      final dayTransactions = groupedTransactions[dateKey]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              dateKey,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface
                                    .withOpacitySafe(0.7),
                              ),
                            ),
                          ),
                          AppCard(
                            child: Column(
                              children: dayTransactions.asMap().entries.map((
                                entry,
                              ) {
                                final i = entry.key;
                                final tx = entry.value;
                                final isLast = i == dayTransactions.length - 1;
                                return Column(
                                  children: [
                                    _buildTransactionTile(theme, tx),
                                    if (!isLast)
                                      Divider(
                                        height: 1,
                                        color: theme.colorScheme.outline
                                            .withOpacitySafe(0.1),
                                      ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            ),
            child: Icon(
              Icons.receipt_long,
              size: 80,
              color: theme.colorScheme.primary.withOpacitySafe(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No transactions yet',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your transaction history will appear here',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    ThemeData theme,
    String label,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₵${amount.toStringAsFixed(2)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(ThemeData theme, String label) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) => setState(() => _selectedFilter = label),
        backgroundColor: theme.colorScheme.surface,
        selectedColor: theme.colorScheme.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : theme.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildTransactionTile(ThemeData theme, AppTransaction transaction) {
    final isCredit = transaction.type == TransactionType.deposit;
    final isRepayment = transaction.type == TransactionType.repayment;

    Color getColor() {
      if (isCredit) return Colors.green;
      if (isRepayment) return Colors.orange;
      return Colors.red;
    }

    IconData getIcon() {
      if (isCredit) return Icons.arrow_downward;
      if (isRepayment) return Icons.credit_card;
      return Icons.arrow_upward;
    }

    return InkWell(
      onTap: () => _showTransactionDetails(context, transaction),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: getColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(getIcon(), color: getColor(), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (transaction.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      transaction.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (transaction.category != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer
                            .withOpacitySafe(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        transaction.category!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit ? '+' : '-'}₵${transaction.amount.toStringAsFixed(2)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: getColor(),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('HH:mm').format(transaction.date),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacitySafe(0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'Today';
    } else if (transactionDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  void _showTransactionDetails(
    BuildContext context,
    AppTransaction transaction,
  ) {
    final theme = Theme.of(context);
    final isCredit = transaction.type == TransactionType.deposit;
    final isRepayment = transaction.type == TransactionType.repayment;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        (isCredit
                                ? Colors.green
                                : isRepayment
                                ? Colors.orange
                                : Colors.red)
                            .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCredit
                        ? Icons.arrow_downward
                        : isRepayment
                        ? Icons.credit_card
                        : Icons.arrow_upward,
                    color: isCredit
                        ? Colors.green
                        : isRepayment
                        ? Colors.orange
                        : Colors.red,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat(
                          'MMM dd, yyyy • HH:mm',
                        ).format(transaction.date),
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
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacitySafe(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Amount', style: theme.textTheme.bodyLarge),
                  Text(
                    '${isCredit ? '+' : '-'}₵${transaction.amount.toStringAsFixed(2)}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isCredit
                          ? Colors.green
                          : isRepayment
                          ? Colors.orange
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            if (transaction.description != null) ...[
              const SizedBox(height: 16),
              _buildDetailRow(theme, 'Description', transaction.description!),
            ],
            if (transaction.category != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(theme, 'Category', transaction.category!),
            ],
            const SizedBox(height: 12),
            _buildDetailRow(theme, 'Transaction ID', transaction.id),
            const SizedBox(height: 12),
            _buildDetailRow(
              theme,
              'Status',
              'Completed',
              valueColor: Colors.green,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Receipt downloaded')),
                      );
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Receipt shared')),
                      );
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    ThemeData theme,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
