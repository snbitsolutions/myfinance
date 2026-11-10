import 'package:flutter/material.dart';
import '../../core/color_ext.dart';
import 'transaction_model.dart';

class TransactionTile extends StatelessWidget {
  final AppTransaction transaction;

  const TransactionTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accentColor = switch (transaction.type) {
      TransactionType.deposit => scheme.primary,
      TransactionType.withdrawal => scheme.error,
      TransactionType.repayment => Colors.orange,
      TransactionType.unknown => scheme.outline,
    };
    final amountSign = switch (transaction.type) {
      TransactionType.deposit => '+',
      TransactionType.withdrawal || TransactionType.repayment => '-',
      TransactionType.unknown => '',
    };
    final icon = switch (transaction.type) {
      TransactionType.deposit => Icons.call_received_rounded,
      TransactionType.withdrawal => Icons.call_made_rounded,
      TransactionType.repayment => Icons.credit_card,
      TransactionType.unknown => Icons.receipt_long_outlined,
    };

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: accentColor.withOpacitySafe(0.12),
        child: Icon(icon, color: accentColor),
      ),
      title: Text(transaction.title, style: TextStyle(color: scheme.onSurface)),
      subtitle: Text(
        transaction.date.toString().substring(0, 16),
        style: TextStyle(color: scheme.onSurface.withOpacitySafe(0.7)),
      ),
      trailing: Text(
        '$amountSign GHS ${transaction.amount}',
        style: TextStyle(fontWeight: FontWeight.bold, color: accentColor),
      ),
    );
  }
}
