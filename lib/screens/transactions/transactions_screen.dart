import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/color_ext.dart';
import '../../core/app_scaffold.dart';
import '../../core/app_card.dart';
import '../../core/balance_card_shell.dart';
import '../../core/providers/app_providers.dart';
import 'transaction_model.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  final String? savingsId;
  final String? savingsTitle;
  final List<Map<String, dynamic>>? savingsTransactions;

  const TransactionsScreen({
    super.key,
    this.savingsId,
    this.savingsTitle,
    this.savingsTransactions,
  });

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _selectedFilter = 'All';
  String _selectedPeriod = 'This Month';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSavingsFiltered = (widget.savingsId ?? '').isNotEmpty;

    if (isSavingsFiltered && _selectedFilter == 'Repayment') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedFilter = 'All');
      });
    }

    // Use provider data for main transactions, savings data otherwise
    final liveTransactionsAsync = isSavingsFiltered
        ? const AsyncData<List<Map<String, dynamic>>>([])
        : ref.watch(transactionsProvider);

    final isLoadingLive = !isSavingsFiltered && liveTransactionsAsync.isLoading;

    final allTransactions = isSavingsFiltered
        ? _buildSavingsTransactions(
            widget.savingsId!,
            widget.savingsTitle,
            widget.savingsTransactions,
          )
        : _normalizeApiTransactions(
            liveTransactionsAsync.valueOrNull ?? const [],
          );
    final periodTransactions = allTransactions
        .where((tx) => _isWithinSelectedPeriod(tx.date, DateTime.now()))
        .toList();

    // Filter transactions
    final transactions = periodTransactions.where((tx) {
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

      return true;
    }).toList();

    // Calculate totals
    final totalIncome = periodTransactions
        .where((tx) => tx.amount != null && tx.type == TransactionType.deposit)
        .fold<double>(0, (sum, tx) => sum + (tx.amount ?? 0));
    final totalExpense = periodTransactions
        .where(
          (tx) => tx.amount != null && tx.type == TransactionType.withdrawal,
        )
        .fold<double>(0, (sum, tx) => sum + (tx.amount ?? 0));
    final totalRepayment = periodTransactions
        .where(
          (tx) => tx.amount != null && tx.type == TransactionType.repayment,
        )
        .fold<double>(0, (sum, tx) => sum + (tx.amount ?? 0));
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

    final listContent = AnimatedSwitcher(
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
          child: SlideTransition(position: offsetAnimation, child: child),
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
            final dateKey = groupedTransactions.keys.elementAt(index);
            final dayTransactions = groupedTransactions[dateKey]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacitySafe(
                            0.08,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          dateKey,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${dayTransactions.length} item${dayTransactions.length > 1 ? 's' : ''}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacitySafe(
                            0.55,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AppCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: dayTransactions.asMap().entries.map((entry) {
                      final i = entry.key;
                      final tx = entry.value;
                      final isLast = i == dayTransactions.length - 1;
                      return Column(
                        children: [
                          _buildTransactionTile(theme, tx),
                          if (!isLast)
                            Divider(
                              height: 1,
                              color: theme.colorScheme.outline.withOpacitySafe(
                                0.1,
                              ),
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
    );

    return AppScaffold(
      title: isSavingsFiltered ? 'Savings Activity' : 'Activity',
      actions: !isSavingsFiltered
          ? [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh',
                onPressed: () => ref.invalidate(transactionsProvider),
              ),
            ]
          : null,
      child: isLoadingLive
          ? _buildLoadingState(theme)
          : liveTransactionsAsync.hasError && !isSavingsFiltered
          ? _buildApiErrorState(
              theme,
              liveTransactionsAsync.error!,
              () => ref.invalidate(transactionsProvider),
            )
          : transactions.isEmpty
          ? _buildEmptyState(theme)
          : LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = constraints.maxWidth >= 900;

                final controlsPane = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isSavingsFiltered)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: AppCard(
                          margin: EdgeInsets.zero,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.filter_alt_rounded,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Viewing ${widget.savingsTitle ?? 'Savings'} only',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.go('/transactions'),
                                child: const Text('Clear'),
                              ),
                            ],
                          ),
                        ),
                      ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Activity Overview',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: Colors.white.withValues(
                                                alpha: 0.78,
                                              ),
                                              fontSize: 12,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _selectedPeriod,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: Colors.white.withValues(
                                                alpha: 0.68,
                                              ),
                                              fontSize: 10,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
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
                                    Icons.receipt_long,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _miniStatPill(
                                    label: 'Income',
                                    value:
                                        'GH₵${totalIncome.toStringAsFixed(2)}',
                                    background: Colors.green.withValues(
                                      alpha: 0.18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _miniStatPill(
                                    label: 'Expense',
                                    value:
                                        'GH₵${totalExpense.toStringAsFixed(2)}',
                                    background: Colors.red.withValues(
                                      alpha: 0.18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _miniStatPill(
                                    label: 'Repayment',
                                    value:
                                        'GH₵${totalRepayment.toStringAsFixed(2)}',
                                    background: Colors.orange.withValues(
                                      alpha: 0.18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: AppCard(
                        margin: EdgeInsets.zero,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: PopupMenuButton<String>(
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
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.18),
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
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                                  if (!isSavingsFiltered) ...[
                                    const SizedBox(width: 10),
                                    _buildFilterChip(theme, 'Repayment'),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );

                if (!isTablet) {
                  return Column(
                    children: [
                      Flexible(
                        fit: FlexFit.loose,
                        child: SingleChildScrollView(child: controlsPane),
                      ),
                      const SizedBox(height: 8),
                      Expanded(child: listContent),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 360,
                      child: SingleChildScrollView(child: controlsPane),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: listContent,
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  /// Convert raw API transaction maps into [AppTransaction] objects.
  List<AppTransaction> _normalizeApiTransactions(
    List<Map<String, dynamic>> raw,
  ) {
    return raw
        .map((txn) {
          final typeStr = txn['type']?.toString().toLowerCase() ?? 'unknown';
          final type = switch (typeStr) {
            'credit' => TransactionType.deposit,
            'repayment' => TransactionType.repayment,
            'debit' || 'withdraw' || 'withdrawal' => TransactionType.withdrawal,
            _ => TransactionType.unknown,
          };
          final amount =
              (txn['amount'] as num?)?.toDouble() ??
              double.tryParse(txn['amount']?.toString() ?? '');
          final description =
              txn['description'] as String? ??
              txn['narration'] as String? ??
              '';
          final dateStr = txn['date']?.toString() ?? '';
          final date = DateTime.tryParse(dateStr);
          final id = txn['transaction_id']?.toString().trim() ?? '';
          if (date == null || id.isEmpty) return null;
          return AppTransaction(
            id: id,
            title: description.isEmpty ? 'Transaction' : description,
            description: description,
            amount: amount,
            type: type,
            date: date,
            category: typeStr == 'credit' ? 'Income' : 'Expense',
          );
        })
        .whereType<AppTransaction>()
        .toList();
  }

  bool _isWithinSelectedPeriod(DateTime date, DateTime now) {
    final localDate = date.toLocal();
    final transactionDay = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
    );
    final today = DateTime(now.year, now.month, now.day);

    return switch (_selectedPeriod) {
      'Today' => transactionDay == today,
      'This Week' =>
        !transactionDay.isBefore(
              today.subtract(Duration(days: today.weekday - 1)),
            ) &&
            transactionDay.isBefore(
              today
                  .subtract(Duration(days: today.weekday - 1))
                  .add(const Duration(days: 7)),
            ),
      'This Month' =>
        localDate.year == now.year && localDate.month == now.month,
      'Last Month' =>
        localDate.year == DateTime(now.year, now.month - 1).year &&
            localDate.month == DateTime(now.year, now.month - 1).month,
      _ => true,
    };
  }

  List<AppTransaction> _buildSavingsTransactions(
    String savingsId,
    String? savingsTitle,
    List<Map<String, dynamic>>? savingsTransactions,
  ) {
    final title = (savingsTitle ?? '').trim().isEmpty
        ? 'Savings Goal'
        : savingsTitle!.trim();
    final source = savingsTransactions ?? const [];

    return source.asMap().entries.map((entry) {
      final index = entry.key;
      final tx = entry.value;

      final rawType = (tx['type'] as String? ?? '').trim().toLowerCase();
      final type = switch (rawType) {
        'withdraw' || 'withdrawal' => TransactionType.withdrawal,
        'repayment' => TransactionType.repayment,
        'deposit' || 'credit' => TransactionType.deposit,
        _ => TransactionType.unknown,
      };

      final rawAmount = tx['amount'];
      final amount = rawAmount is num
          ? rawAmount.toDouble()
          : double.tryParse(rawAmount?.toString() ?? '');

      DateTime parsedDate = DateTime.now();
      final rawDate = tx['date'];
      if (rawDate is String) {
        parsedDate =
            DateTime.tryParse(rawDate) ??
            _tryParseDisplayDate(rawDate) ??
            parsedDate;
      }

      final displayType = (tx['type'] as String?)?.trim();
      final normalizedTitle = (displayType == null || displayType.isEmpty)
          ? 'Activity'
          : displayType;

      return AppTransaction(
        id: '${savingsId}_${index + 1}',
        title: normalizedTitle,
        description: '$title activity',
        amount: amount,
        type: type,
        date: parsedDate,
        category: 'Savings',
      );
    }).toList();
  }

  DateTime? _tryParseDisplayDate(String value) {
    try {
      return DateFormat('MMM dd, yyyy').parse(value);
    } catch (_) {
      return null;
    }
  }

  Widget _buildLoadingState(ThemeData theme) {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildApiErrorState(
    ThemeData theme,
    Object error,
    VoidCallback onRetry,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load transactions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString().replaceFirst(RegExp(r'^.*Exception: '), ''),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
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

  Widget _miniStatPill({
    required String label,
    required String value,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
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
    final isDebit = transaction.type == TransactionType.withdrawal;
    final amountLabel = transaction.amount == null
        ? 'GH₵ —'
        : '${isCredit
              ? '+'
              : isDebit || isRepayment
              ? '-'
              : ''}GH₵${transaction.amount!.toStringAsFixed(2)}';

    Color getColor() {
      if (isCredit) return Colors.green;
      if (isRepayment) return Colors.orange;
      if (!isDebit) return theme.colorScheme.outline;
      return Colors.red;
    }

    IconData getIcon() {
      if (isCredit) return Icons.arrow_downward;
      if (isRepayment) return Icons.credit_card;
      if (!isDebit) return Icons.receipt_long_outlined;
      return Icons.arrow_upward;
    }

    return InkWell(
      onTap: () => _showTransactionDetails(context, transaction),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: getColor().withOpacitySafe(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(getIcon(), color: getColor(), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
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
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacitySafe(0.09),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        transaction.category!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
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
                    amountLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: getColor(),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
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
    final isDebit = transaction.type == TransactionType.withdrawal;
    final amountLabel = transaction.amount == null
        ? 'GH₵ —'
        : '${isCredit
              ? '+'
              : isDebit || isRepayment
              ? '-'
              : ''}GH₵${transaction.amount!.toStringAsFixed(2)}';

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
                    Expanded(
                      child: Text(
                        'Amount',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacitySafe(0.92),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      amountLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
