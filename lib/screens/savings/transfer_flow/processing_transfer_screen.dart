import 'package:flutter/material.dart';
import '../../../core/app_scaffold.dart';

class ProcessingTransferScreen extends StatelessWidget {
  const ProcessingTransferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Transfer Unavailable',
      showBack: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Icon(
                Icons.cloud_off_rounded,
                size: 56,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 32),

            // Status text
            Text(
              'Transfer not submitted',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Transfers cannot be completed until recipient verification and processing are connected to the backend.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).popUntil(
                (route) => route.settings.name == '/savings' || route.isFirst,
              ),
              child: const Text('Back to savings'),
            ),
          ],
        ),
      ),
    );
  }
}
