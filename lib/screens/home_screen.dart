import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/loan.dart';
import '../models/savings.dart';
import '../models/payment.dart';
import '../services/data_service.dart';
import 'loans_screen.dart';
import 'savings_screen.dart';
import 'payments_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DataService _dataService = DataService();
  List<Loan> _loans = [];
  List<Savings> _savings = [];
  List<Payment> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final loans = await _dataService.getLoans();
    final savings = await _dataService.getSavings();
    final payments = await _dataService.getPayments();
    
    setState(() {
      _loans = loans;
      _savings = savings;
      _payments = payments;
      _isLoading = false;
    });
  }

  double get _totalLoans {
    return _loans.fold(0, (sum, loan) => sum + loan.amount);
  }

  double get _totalSavings {
    return _savings.fold(0, (sum, savings) => sum + savings.balance);
  }

  double get _monthlyIncome {
    final now = DateTime.now();
    final thisMonth = _payments.where((p) => 
      p.type == PaymentType.income &&
      p.date.year == now.year &&
      p.date.month == now.month
    );
    return thisMonth.fold(0, (sum, payment) => sum + payment.amount);
  }

  double get _monthlyExpenses {
    final now = DateTime.now();
    final thisMonth = _payments.where((p) => 
      p.type == PaymentType.expense &&
      p.date.year == now.year &&
      p.date.month == now.month
    );
    return thisMonth.fold(0, (sum, payment) => sum + payment.amount);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Finance'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryCard(
                    'Total Savings',
                    currencyFormat.format(_totalSavings),
                    Icons.savings,
                    Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryCard(
                    'Total Loans',
                    currencyFormat.format(_totalLoans),
                    Icons.account_balance,
                    Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryCard(
                    'Monthly Income',
                    currencyFormat.format(_monthlyIncome),
                    Icons.trending_up,
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryCard(
                    'Monthly Expenses',
                    currencyFormat.format(_monthlyExpenses),
                    Icons.trending_down,
                    Colors.red,
                  ),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  _buildRecentPayments(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Loans',
                Icons.account_balance,
                Colors.orange,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoansScreen()),
                ).then((_) => _loadData()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Savings',
                Icons.savings,
                Colors.green,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SavingsScreen()),
                ).then((_) => _loadData()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Payments',
                Icons.payment,
                Colors.blue,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaymentsScreen()),
                ).then((_) => _loadData()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentPayments() {
    final recentPayments = _payments.take(5).toList();
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Payments',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (recentPayments.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('No payments yet')),
            ),
          )
        else
          ...recentPayments.map((payment) {
            final isIncome = payment.type == PaymentType.income;
            return Card(
              child: ListTile(
                leading: Icon(
                  isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isIncome ? Colors.green : Colors.red,
                ),
                title: Text(payment.title),
                subtitle: Text(DateFormat.yMMMd().format(payment.date)),
                trailing: Text(
                  '${isIncome ? '+' : '-'}${currencyFormat.format(payment.amount)}',
                  style: TextStyle(
                    color: isIncome ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
