import 'package:flutter/material.dart';
import '../../core/color_ext.dart';
import 'transaction_model.dart';

class TransactionTile extends StatelessWidget {
  final AppTransaction transaction;

  const TransactionTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type == TransactionType.deposit;
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: (isCredit ? scheme.primary : scheme.error)
            .withOpacitySafe(0.12),
        child: Icon(
          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
          color: isCredit ? scheme.primary : scheme.error,
        ),
      ),
      title: Text(transaction.title, style: TextStyle(color: scheme.onSurface)),
      subtitle: Text(
        transaction.date.toString().substring(0, 16),
        style: TextStyle(color: scheme.onSurface.withOpacitySafe(0.7)),
      ),
      trailing: Text(
        '${isCredit ? '+' : '-'} GHS ${transaction.amount}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isCredit ? scheme.primary : scheme.error,
        ),
      ),
    );
  }
}
