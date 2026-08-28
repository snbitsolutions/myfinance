import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_scaffold.dart';

class PaymentReceiptScreen extends StatelessWidget {
  final double? amount;
  final DateTime? processedAt;
  final String? reference;
  final String? account;
  final String? paymentMethod;
  final double? newBalance;

  const PaymentReceiptScreen({
    super.key,
    this.amount,
    this.processedAt,
    this.reference,
    this.account,
    this.paymentMethod,
    this.newBalance,
  });

  String _money(double? value) => 'GH₵ ${(value ?? 0).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final date = processedAt ?? DateTime.now();
    final ref = reference?.trim().isNotEmpty == true
        ? reference!
        : 'ADEPA-${DateTime.now().millisecondsSinceEpoch}';
    return AppScaffold(
      title: 'Deposit Receipt',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 26),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF075D21), Color(0xFF08752B)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  const Text(
                    'ADEPA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Deposit Receipt',
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text(
                    _money(amount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text('Amount Deposited',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _row('Deposited Into', account ?? 'Member Savings'),
                    _row('Date & Time',
                        '${date.day} ${_month(date.month)} ${date.year} • ${_time(date)}'),
                    _row('Reference', ref),
                    _row('Payment Method', paymentMethod ?? 'Mobile Money'),
                    _row('Transaction Fee', 'GH₵ 0.00'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              color: const Color(0xFFF0F8EF),
              child: ListTile(
                leading: const Icon(Icons.trending_up, color: Color(0xFF08752B)),
                title: const Text('New Available Balance'),
                subtitle: Text(_money(newBalance)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context.go('/savings'),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.black54)),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  String _month(int month) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][month - 1];

  String _time(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    return '$hour:${value.minute.toString().padLeft(2, '0')} '
        '${value.hour >= 12 ? 'PM' : 'AM'}';
  }
}
