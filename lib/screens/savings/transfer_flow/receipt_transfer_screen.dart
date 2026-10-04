import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'transfer_model.dart';

class ReceiptTransferScreen extends StatelessWidget {
  final TransferData? initialData;

  const ReceiptTransferScreen({
    super.key,
    this.initialData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = initialData ?? TransferData();

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Green header with ADEPA branding
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
                  children: [
                    // ADEPA branding
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ADEPA',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Receipt title
                    Text(
                      'Transfer Receipt',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Receipt content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // Status badge
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          border: Border.all(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Transfer not submitted',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Main amount display
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Amount entered',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'GH₵${data.amount.toStringAsFixed(2)}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Transaction details section
                    Text(
                      'Transaction Details',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Recipient info
                    _buildReceiptRow(
                      context,
                      'Recipient Name',
                      data.recipientName ?? '-',
                    ),
                    const SizedBox(height: 12),
                    _buildReceiptRow(
                      context,
                      'Recipient Phone',
                      data.recipientPhone ?? '-',
                    ),
                    const SizedBox(height: 12),
                    _buildReceiptRow(
                      context,
                      'Amount entered',
                      'GH₵${data.amount.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 12),
                    _buildReceiptRow(
                      context,
                      'Transfer fee',
                      'Unavailable',
                    ),
                    const SizedBox(height: 12),
                    _buildReceiptRow(
                      context,
                      'Total debit',
                      'Unavailable',
                      highlight: true,
                    ),
                    const SizedBox(height: 24),

                    // Reference number
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reference Number',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'TXN-${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Action buttons
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Share receipt functionality would go here
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Receipt shared'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: const Text('Share Receipt'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          context.go('/home');
                        },
                        child: const Text('Done'),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(
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
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: highlight ? theme.colorScheme.onPrimaryContainer : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
