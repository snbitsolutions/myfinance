import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'transfer_model.dart';

class SuccessTransferScreen extends StatelessWidget {
  final TransferData? initialData;

  const SuccessTransferScreen({
    super.key,
    this.initialData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = initialData ?? TransferData();
    final total = data.amount + data.transactionFee;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Green header with back button
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  bottom: 32,
                  left: 16,
                  right: 16,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF075D21),
                      Color(0xFF08752B),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Decorative dots in top-right
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: List.generate(
                        3,
                        (i) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Success icon
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Amount
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Transfer Successful',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'GH₵${total.toStringAsFixed(2)}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // Transfer details
                    Text(
                      'Transfer Details',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Recipient
                    _buildDetailRow(
                      context,
                      'Recipient',
                      data.recipientName ?? '-',
                    ),
                    const SizedBox(height: 12),

                    // Amount transferred
                    _buildDetailRow(
                      context,
                      'Amount',
                      'GH₵${data.amount.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 12),

                    // Fee
                    _buildDetailRow(
                      context,
                      'Transfer Fee',
                      'GH₵${data.transactionFee.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 12),

                    // Total
                    _buildDetailRow(
                      context,
                      'Total Debited',
                      'GH₵${total.toStringAsFixed(2)}',
                      highlight: true,
                    ),
                    const SizedBox(height: 32),

                    // Action buttons
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          context.push(
                            '/transfer/receipt',
                            extra: data,
                          );
                        },
                        child: const Text('View Receipt'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          context.go('/home');
                        },
                        child: const Text('Go to Home'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
