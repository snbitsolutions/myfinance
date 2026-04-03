import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/color_ext.dart';
import '../../core/app_scaffold.dart';
import '../../core/app_card.dart';
import '../../core/balance_card_shell.dart';
import 'transaction_model.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _selectedFilter = 'All';
  String _selectedPeriod = 'This Month';
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
      // Filter by type
      if (_selectedFilter == 'All') {
        // include all
      } else if (_selectedFilter == 'Income') {
        if (tx.type != TransactionType.deposit) return false;
      } else if (_selectedFilter == 'Expense') {
        if (tx.type != TransactionType.withdrawal) return false;
      } else if (_selectedFilter == 'Repayment') {
        if (tx.type != TransactionType.repayment) return false;
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final matchesTitle = tx.title.toLowerCase().contains(_searchQuery);
        final matchesDesc = (tx.description?.toLowerCase() ?? '').contains(
          _searchQuery,
        );
        if (!matchesTitle && !matchesDesc) return false;
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
    final netBalance = totalIncome - totalExpense - totalRepayment;

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
                // Net Balance Hero
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: BalanceCardShell(
                    gradientColors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                    shadowColor: theme.colorScheme.primary.withOpacitySafe(
                      0.24,
                    ),
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
                                    'Net Balance',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.78,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedPeriod,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.68,
                                      ),
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'GH₵${netBalance.toStringAsFixed(2)}',
                                      style: theme.textTheme.headlineMedium
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.4,
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
                              child: const Icon(
                                Icons.account_balance_wallet,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
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
                                Icons.receipt_long,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${transactions.length} transactions in view',
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
                      ],
                    ),
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search transactions...',
                      hintStyle: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.45,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.55,
                        ),
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () => _searchController.clear(),
                              child: Icon(
                                Icons.close_rounded,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.55,
                                ),
                                size: 18,
                              ),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.25,
                          ),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.25,
                          ),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.4,
                          ),
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                  ),
                ),

                // Summary Cards
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
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
                        netBalance,
                        Icons.account_balance_wallet,
                        theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),

                // Filter Chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AppCard(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Filter & Sort',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.82,
                                ),
                                letterSpacing: 0.3,
                              ),
                            ),
                            PopupMenuButton<String>(
                              initialValue: _selectedPeriod,
                              onSelected: (value) =>
                                  setState(() => _selectedPeriod = value),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.18,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      color: theme.colorScheme.primary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _selectedPeriod,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                    ),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      color: theme.colorScheme.primary,
                                      size: 18,
                                    ),
                                  ],
                                ),
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
                        const SizedBox(height: 14),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip(theme, 'All'),
                              const SizedBox(width: 10),
                              _buildFilterChip(theme, 'Income'),
                              const SizedBox(width: 10),
                              _buildFilterChip(theme, 'Expense'),
                              const SizedBox(width: 10),
                              _buildFilterChip(theme, 'Repayment'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Transactions List
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final offsetAnimation = Tween<Offset>(
                        begin: const Offset(0, 0.03),
                        end: Offset.zero,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: offsetAnimation,
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey(
                        'list-$_selectedFilter-$_selectedPeriod-${groupedTransactions.length}',
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: groupedTransactions.length,
                        itemBuilder: (context, index) {
                          final dateKey = groupedTransactions.keys.elementAt(
                            index,
                          );
                          final dayTransactions = groupedTransactions[dateKey]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      dateKey,
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurface
                                                .withOpacitySafe(0.75),
                                          ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${dayTransactions.length} item${dayTransactions.length > 1 ? 's' : ''}',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withOpacitySafe(0.55),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              AppCard(
                                margin: EdgeInsets.zero,
                                child: Column(
                                  children: dayTransactions.asMap().entries.map(
                                    (entry) {
                                      final i = entry.key;
                                      final tx = entry.value;
                                      final isLast =
                                          i == dayTransactions.length - 1;
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
                                    },
                                  ).toList(),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          );
                        },
                      ),
                    ),
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
              color: theme.colorScheme.primaryContainer.withOpacitySafe(0.3),
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
    final gradientStart = color.withValues(alpha: 0.88);
    final gradientEnd = color.withValues(alpha: 0.65);
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradientStart, gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'GH₵${amount.toStringAsFixed(2)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 16,
                  letterSpacing: 0.2,
                ),
              ),
            ],
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
              : theme.colorScheme.outline.withOpacitySafe(0.3),
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
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: getColor().withOpacitySafe(0.1),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: getColor().withOpacitySafe(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${isCredit ? '+' : '-'}GH₵${transaction.amount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: getColor(),
                    ),
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withOpacitySafe(0.35),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(14),
                child: Row(
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
                                .withOpacitySafe(0.12),
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
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat(
                              'MMM dd, yyyy • HH:mm',
                            ).format(transaction.date),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacitySafe(0.62),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              BalanceCardShell(
                gradientColors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacitySafe(0.82),
                ],
                shadowColor: theme.colorScheme.primary.withOpacitySafe(0.28),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Amount',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacitySafe(0.92),
                      ),
                    ),
                    Text(
                      '${isCredit ? '+' : '-'}GH₵${transaction.amount.toStringAsFixed(2)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    if (transaction.description != null)
                      _buildDetailRow(
                        theme,
                        'Description',
                        transaction.description!,
                      ),
                    if (transaction.description != null)
                      const SizedBox(height: 12),
                    if (transaction.category != null)
                      _buildDetailRow(theme, 'Category', transaction.category!),
                    if (transaction.category != null)
                      const SizedBox(height: 12),
                    _buildDetailRow(theme, 'Transaction ID', transaction.id),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      theme,
                      'Status',
                      'Completed',
                      valueColor: Colors.green,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
