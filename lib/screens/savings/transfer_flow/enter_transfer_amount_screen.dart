import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_card.dart';
import '../../../core/app_scaffold.dart';
import '../../../core/modern_input.dart';
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
    final amount = _parseAmount(_amountController.text);
    return amount.isFinite &&
        amount > 0 &&
        (_data.recipientName?.trim().isNotEmpty ?? false) &&
        (_data.recipientPhone?.trim().isNotEmpty ?? false);
  }

  double _parseAmount(String value) =>
      double.tryParse(value.replaceAll(',', '').trim()) ?? 0.0;

  void _setAmount(double amount) {
    _amountController.text = amount.toStringAsFixed(2);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Enter Amount',
      child: SingleChildScrollView(
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
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recipient',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_data.recipientName ?? 'Not provided'} · ${_data.recipientPhone ?? 'No phone number'}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Recipient details are not verified.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ModernInput(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              label: 'Amount',
              prefixText: 'GH₵ ',
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

            AppCard(
              child: Text(
                'Transfer fee and limits are unavailable until the backend provides the applicable terms. No fee is estimated here.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 32),

            // Continue button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canContinue
                    ? () {
                        final amount = _parseAmount(_amountController.text);
                        final updated = _data.copyWith(
                          amount: amount,
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
