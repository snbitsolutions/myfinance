import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'transfer_model.dart';

class EnterTransferAmountScreen extends StatefulWidget {
  final TransferData? initialData;

  const EnterTransferAmountScreen({
    super.key,
    this.initialData,
  });

  @override
  State<EnterTransferAmountScreen> createState() =>
      _EnterTransferAmountScreenState();
}

class _EnterTransferAmountScreenState extends State<EnterTransferAmountScreen> {
  late TextEditingController _amountController;
  late TransferData _data;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _data = widget.initialData ?? TransferData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  bool get _canContinue {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    return amount > 0 && amount <= 10000; // Mock max transfer amount
  }

  double get _transactionFee {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    return amount * 0.015; // 1.5% fee
  }

  double get _totalAmount {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    return amount + _transactionFee;
  }

  void _setAmount(double amount) {
    _amountController.text = amount.toStringAsFixed(2);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Amount'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount input
            Text(
              'Transfer Amount',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '0.00',
                prefixText: 'GH₵ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),

            // Quick amount buttons
            Text(
              'Quick Amounts',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [500, 1000, 2000, 5000].map((amount) {
                return ActionChip(
                  label: Text('GH₵${amount.toStringAsFixed(2)}'),
                  onPressed: () => _setAmount(amount.toDouble()),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Fee breakdown
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fee Breakdown',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Amount',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      Text(
                        'GH₵${(double.tryParse(_amountController.text) ?? 0.0).toStringAsFixed(2)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transfer Fee (1.5%)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      Text(
                        'GH₵${_transactionFee.toStringAsFixed(2)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'GH₵${_totalAmount.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Continue button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canContinue
                    ? () {
                        final amount =
                            double.tryParse(_amountController.text) ?? 0.0;
                        final updated = _data.copyWith(
                          amount: amount,
                          transactionFee: _transactionFee,
                        );
                        context.push(
                          '/transfer/review',
                          extra: updated,
                        );
                      }
                    : null,
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
