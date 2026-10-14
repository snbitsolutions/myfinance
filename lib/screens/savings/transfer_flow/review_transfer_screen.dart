import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_card.dart';
import '../../../core/app_scaffold.dart';
import 'transfer_model.dart';

class ReviewTransferScreen extends StatelessWidget {
  final TransferData? initialData;

  const ReviewTransferScreen({
    super.key,
    this.initialData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = initialData ?? TransferData();
    final total = data.amount;

    return AppScaffold(
      title: 'Review Transfer',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary card
            AppCard(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Column(
                children: [
                  Text(
                    'Transfer Amount',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'GH₵${total.toStringAsFixed(2)}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Recipient details
            Text(
              'Recipient',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              context,
              'Name',
              data.recipientName ?? '-',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              context,
              'Phone',
              data.recipientPhone ?? '-',
            ),
            const SizedBox(height: 24),

            // Transfer details
            Text(
              'Transfer Details',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              context,
              'Amount',
              'GH₵${data.amount.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              context,
              'Transfer fee',
              'Not available',
              highlight: true,
            ),
            const SizedBox(height: 12),
            Text(
              'This is a review of the details only. Recipient verification, applicable fees, and transfer processing are not connected, so no transfer can be sent.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push(
                  '/transfer/processing',
                  extra: data,
                ),
                child: const Text('Finish Preparing'),
              ),
            ),

            // Edit button
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  context.pop();
                },
                child: const Text('Edit Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool highlight = false,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 12.0,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(12),
        color: highlight ? theme.colorScheme.primaryContainer : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: highlight
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.outline,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: highlight ? theme.colorScheme.onPrimaryContainer : null,
            ),
          ),
        ],
      ),
    );
  }
}
