import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';
import '../../core/balance_card_shell.dart';
import '../../core/layout/responsive.dart';
import '../../core/providers/app_providers.dart';

String _loanAmountLabel(dynamic value) => value is num
    ? 'GH₵${value.toDouble().toStringAsFixed(2)}'
    : 'Unavailable';

class LoansScreen extends ConsumerWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final apiLoansAsync = ref.watch(loansProvider);

    return AppScaffold(
      title: 'Loans',
      backRoute: '/home',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= Responsive.medium;

          final loansToDisplay = apiLoansAsync.valueOrNull ?? const [];

          final content = SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // API loans summary banner - handles loading and error states
                _ApiLoansSummary(apiLoansAsync: apiLoansAsync, theme: theme),
                // Keep the hub visible while only using backend loan data.
                _LoansHubView(
                  theme: theme,
                  apiLoans: loansToDisplay,
                  hasLoanData: apiLoansAsync.hasValue,
                ),
              ],
            ),
          );

          if (!isTablet) return content;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: content,
            ),
          );
        },
      ),
    );
  }
}

class _ApiLoansSummary extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> apiLoansAsync;
  final ThemeData theme;

  const _ApiLoansSummary({required this.apiLoansAsync, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (apiLoansAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    if (apiLoansAsync.hasError) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 16,
                color: theme.colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Could not load loans from server',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final loans = apiLoansAsync.value ?? const [];
    if (loans.isEmpty) return const SizedBox.shrink();

    final totalOutstanding = loans.fold<double>(0.0, (sum, l) {
      final v = l['outstanding_balance'] ?? l['balance'];
      return sum + (v is num ? v.toDouble() : 0.0);
    });
    final allBalancesAvailable = loans.every(
      (loan) => loan['outstanding_balance'] is num || loan['balance'] is num,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFB86A14).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.account_balance_rounded,
                color: Color(0xFFB86A14),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${loans.length} loan record${loans.length == 1 ? '' : 's'} returned',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    allBalancesAvailable
                        ? 'Total outstanding: GH₵${totalOutstanding.toStringAsFixed(2)}'
                        : 'Outstanding balance unavailable',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.65,
                      ),
                    ),
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

class _LoansHubView extends StatefulWidget {
  final ThemeData theme;
  final List<Map<String, dynamic>> apiLoans;
  final bool hasLoanData;

  const _LoansHubView({
    required this.theme,
    required this.apiLoans,
    required this.hasLoanData,
  });

  @override
  State<_LoansHubView> createState() => _LoansHubViewState();
}

class _LoansHubViewState extends State<_LoansHubView> {
  int _selectedQuickAction = 0;

  void _showLoanOverview(BuildContext context) {
    setState(() => _selectedQuickAction = 0);
    final loans = widget.apiLoans;
    final theme = Theme.of(context);
    final totalOutstanding = loans.fold<double>(0, (sum, loan) {
      final value =
          loan['outstanding_balance'] ?? loan['balance'];
      return sum + (value is num ? value.toDouble() : 0);
    });
    final allBalancesAvailable = loans.every(
      (loan) => loan['outstanding_balance'] is num || loan['balance'] is num,
    );

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
                'Loan overview',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'A quick look at your current loan portfolio',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _OverviewMetric(
                      label: 'Outstanding',
                      value: allBalancesAvailable
                          ? 'GH₵${totalOutstanding.toStringAsFixed(2)}'
                          : 'Unavailable',
                      icon: Icons.payments_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _OverviewMetric(
                      label: 'Active loans',
                      value: loans.length.toString(),
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (loans.isEmpty)
                Text(
                  'No loan activity is available yet. Your balance and repayment progress will appear here after you apply.',
                  style: theme.textTheme.bodyMedium,
                )
              else
                ...loans
                    .take(5)
                    .map(
                      (loan) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          loan['loan_type']?.toString() ?? 'Loan',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          loan['status']?.toString() ?? 'Status unavailable',
                        ),
                        trailing: Text(
                          _loanAmountLabel(
                            loan['outstanding_balance'] ?? loan['balance'],
                          ),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  void _openQuickAction(
    BuildContext context,
    int action,
    List<Map<String, dynamic>> loans,
  ) {
    setState(() => _selectedQuickAction = action);
    final titles = {
      1: 'Repayment schedule',
      2: 'Loan statement',
      3: 'Loan calculator',
    };

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final content = switch (action) {
          1 => _buildScheduleSheet(sheetContext, loans),
          2 => _buildStatementSheet(sheetContext, loans),
          _ => const _LoanCalculatorSheet(),
        };

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titles[action] ?? 'Loans',
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                content,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScheduleSheet(
    BuildContext context,
    List<Map<String, dynamic>> loans,
  ) {
    final theme = Theme.of(context);
    if (loans.isEmpty) {
      return _LoanEmptyState(
        icon: Icons.event_available_rounded,
        message: 'Your repayment schedule will appear here after you apply.',
      );
    }

    return Column(
      children: loans.take(5).map((loan) {
        final amount = loan['next_payment_amount'];
        final amountLabel = amount is num
            ? 'GH₵${amount.toDouble().toStringAsFixed(2)}'
            : 'Amount pending';
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Icon(
              Icons.calendar_month_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
          title: Text(
            loan['loan_type']?.toString() ?? 'Loan payment',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            'Due ${loan['next_payment_due']?.toString() ?? 'date pending'}',
          ),
          trailing: Text(
            amountLabel,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatementSheet(
    BuildContext context,
    List<Map<String, dynamic>> loans,
  ) {
    final theme = Theme.of(context);
    final totalOutstanding = loans.fold<double>(0, (sum, loan) {
      final value =
          loan['outstanding_balance'] ?? loan['balance'];
      return sum + (value is num ? value.toDouble() : 0);
    });
    final allBalancesAvailable = loans.every(
      (loan) => loan['outstanding_balance'] is num || loan['balance'] is num,
    );

    return Column(
      children: [
        _StatementRow(
          label: 'Accounts listed',
          value: loans.length.toString(),
          icon: Icons.account_balance_wallet_outlined,
        ),
        _StatementRow(
          label: 'Outstanding balance',
          value: allBalancesAvailable
              ? 'GH₵${totalOutstanding.toStringAsFixed(2)}'
              : 'Unavailable',
          icon: Icons.payments_outlined,
        ),
        _StatementRow(
          label: 'Statement period',
          value: 'Current account',
          icon: Icons.date_range_outlined,
        ),
        const SizedBox(height: 8),
        Text(
          'A downloadable statement will be available once payment history is synced.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loans = widget.apiLoans;
    final theme = widget.theme;

    // Calculate totals
    final totalOutstanding = loans.fold<double>(0.0, (sum, l) {
      final v = l['outstanding_balance'] ?? l['balance'];
      return sum + (v is num ? v.toDouble() : 0.0);
    });
    final hasOutstandingBalances = loans.every(
      (loan) => loan['outstanding_balance'] is num || loan['balance'] is num,
    );

    final upcomingPayments = loans
        .where((l) => (l['next_payment_due']?.toString() ?? '').isNotEmpty)
        .toList();

    return Column(
      children: [
        const SizedBox(height: 12),
        // Total Outstanding Summary Card
        BalanceCardShell(
          gradientColors: const [
            Color(0xFF1E6B47),
            Color(0xFF2E8B57),
            Color(0xFF3DA66B),
          ],
          shadowColor: const Color(0x332E8B57),
          contentPadding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LOAN PORTFOLIO',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Total outstanding',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.visibility_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.hasLoanData && hasOutstandingBalances
                    ? 'GH₵${totalOutstanding.toStringAsFixed(2)}'
                    : 'Unavailable',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.hasLoanData
                    ? 'Across ${loans.length} active loan${loans.length == 1 ? '' : 's'}'
                    : 'Loan balances are unavailable until data loads',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                    child: _PortfolioMetric(
                        value: widget.hasLoanData
                            ? loans.length.toString()
                            : '—',
                        label: 'Active loans',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    Expanded(
                    child: _PortfolioMetric(
                        value: widget.hasLoanData
                            ? upcomingPayments.length.toString()
                            : '—',
                        label: 'Upcoming payments',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.go('/apply-loan'),
                  icon: const Icon(Icons.add_rounded, size: 19),
                  label: const Text('Apply for a new loan'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2E8B57),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Quick Action Tabs
        AppCard(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      _QuickActionTab(
                        icon: Icons.pie_chart_rounded,
                        label: 'Loan Overview',
                        isSelected: _selectedQuickAction == 0,
                        onTap: () => _showLoanOverview(context),
                      ),
                      const SizedBox(width: 8),
                      _QuickActionTab(
                        icon: Icons.calendar_month_outlined,
                        label: 'Repayment Schedule',
                        isSelected: _selectedQuickAction == 1,
                        onTap: () => _openQuickAction(context, 1, loans),
                      ),
                      const SizedBox(width: 8),
                      _QuickActionTab(
                        icon: Icons.receipt_outlined,
                        label: 'Loan Statement',
                        isSelected: _selectedQuickAction == 2,
                        onTap: () => _openQuickAction(context, 2, loans),
                      ),
                      const SizedBox(width: 8),
                      _QuickActionTab(
                        icon: Icons.calculate_outlined,
                        label: 'Loan Calculator',
                        isSelected: _selectedQuickAction == 3,
                        onTap: () => _openQuickAction(context, 3, loans),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // My Active Loans Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Active Loans (${loans.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Row(
                children: [
                  Text(
                    'View Closed Loans',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (loans.isEmpty)
          AppCard(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 10),
                Text(
                  widget.hasLoanData
                      ? 'No loans returned by the backend'
                      : 'Loan data unavailable',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.hasLoanData
                      ? 'Your returned loan accounts will appear here.'
                      : 'Loan accounts, balances, and schedules will appear here when backend data is available.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          )
        else
          ...loans.map(
            (loan) => _LoanCard(
              loan: loan,
              theme: theme,
              onViewDetails: () =>
                  context.go('/loans/${loan['loan_id'] ?? 'unknown'}'),
            ),
          ),
        const SizedBox(height: 16),

        // Upcoming Payments Section
        if (upcomingPayments.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Payments',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Row(
                  children: [
                    Text(
                      'View Schedule',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...upcomingPayments
              .take(2)
              .map(
                (payment) =>
                    _UpcomingPaymentCard(payment: payment, theme: theme),
              ),
          const SizedBox(height: 16),
        ],

        // Information Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.16),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Keep up with your repayments to avoid penalties and improve your credit score.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoanEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _LoanEmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _PortfolioMetric extends StatelessWidget {
  final String value;
  final String label;

  const _PortfolioMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _OverviewMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 3),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatementRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatementRow({
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

class _LoanCalculatorSheet extends StatefulWidget {
  const _LoanCalculatorSheet();

  @override
  State<_LoanCalculatorSheet> createState() => _LoanCalculatorSheetState();
}

class _LoanCalculatorSheetState extends State<_LoanCalculatorSheet> {
  final _amountController = TextEditingController(text: '1000');
  double _months = 6;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Borrowing amount',
            prefixText: 'GH₵ ',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${_months.toInt()} month repayment plan',
          style: theme.textTheme.labelLarge,
        ),
        Slider(
          value: _months,
          min: 3,
          max: 12,
          divisions: 3,
          label: '${_months.toInt()} months',
          onChanged: (value) => setState(() => _months = value),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: _CalculatorResult(
                label: 'Estimated monthly',
                value: 'Unavailable',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CalculatorResult(
                label: 'Estimated total',
                value: 'Unavailable',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Repayment terms and interest rates are unavailable until the backend provides current loan terms.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }
}

class _CalculatorResult extends StatelessWidget {
  final String label;
  final String value;

  const _CalculatorResult({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _QuickActionTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickActionTab({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final Map<String, dynamic> loan;
  final ThemeData theme;
  final VoidCallback onViewDetails;

  const _LoanCard({
    required this.loan,
    required this.theme,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final loanName = loan['loan_type'] ?? loan['type'] ?? 'Loan';
    final description = loan['description'] ?? 'Loan account';
    final outstanding = loan['outstanding_balance'] ?? loan['balance'] ?? 0;
    final nextDue = loan['next_payment_due'] ?? 'No due date';
    final daysUntilDue = loan['days_until_due'];
    final loanId = loan['loan_id'] ?? 'Unavailable';
    final disburseDate = loan['disbursement_date'] ?? 'Unavailable';
    final status = loan['status']?.toString().toUpperCase() ?? 'UNKNOWN';

    final statusColor = status == 'ACTIVE'
        ? const Color(0xFF4CAF50)
        : status == 'PENDING'
        ? const Color(0xFFFFA500)
        : theme.colorScheme.outline;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.wallet_rounded,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loanName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Outstanding Balance',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        outstanding is num
                            ? 'GH₵${outstanding.toDouble().toStringAsFixed(2)}'
                            : 'Unavailable',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next Payment Due',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nextDue,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        daysUntilDue == null
                            ? 'Schedule unavailable'
                            : '$daysUntilDue days',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Loan ID: $loanId',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Disbursed: $disburseDate',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: onViewDetails,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.primary),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'View Details',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingPaymentCard extends StatelessWidget {
  final Map<String, dynamic> payment;
  final ThemeData theme;

  const _UpcomingPaymentCard({required this.payment, required this.theme});

  @override
  Widget build(BuildContext context) {
    final loanName = payment['loan_type'] ?? 'Loan Payment';
    final dueDate = payment['next_payment_due'] ?? 'N/A';
    final amount = payment['next_payment_amount'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        margin: EdgeInsets.zero,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loanName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dueDate,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              amount is num
                  ? 'GH₵${amount.toDouble().toStringAsFixed(2)}'
                  : 'Unavailable',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
