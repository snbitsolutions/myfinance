import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_card.dart';
import '../../../core/app_scaffold.dart';
import 'transfer_model.dart';

class ProcessingTransferScreen extends StatelessWidget {
  final TransferData? initialData;

  const ProcessingTransferScreen({super.key, this.initialData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = initialData;

    return AppScaffold(
      title: 'Transfer Not Submitted',
      backRoute: '/savings',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 56,
                    color: theme.colorScheme.tertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No money was moved',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The transfer details were prepared in the app only. The recipient was not verified and the transfer was not submitted to the bank.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (data != null) ...[
                    const SizedBox(height: 20),
                    _TransferDetail(
                      label: 'Recipient',
                      value: data.recipientName ?? 'Not provided',
                    ),
                    const SizedBox(height: 10),
                    _TransferDetail(
                      label: 'Phone',
                      value: data.recipientPhone ?? 'Not provided',
                    ),
                    const SizedBox(height: 10),
                    _TransferDetail(
                      label: 'Amount',
                      value: 'GH₵${data.amount.toStringAsFixed(2)}',
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => context.go('/savings'),
                      child: const Text('Back to Savings'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TransferDetail extends StatelessWidget {
  final String label;
  final String value;

  const _TransferDetail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
