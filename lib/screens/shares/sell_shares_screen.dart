import 'package:flutter/material.dart';

import '../../core/app_scaffold.dart';

class SellSharesScreen extends StatelessWidget {
  final String? shareId;

  const SellSharesScreen({super.key, this.shareId});

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: 'Sell Shares',
    backRoute: '/shares',
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 42),
            const SizedBox(height: 12),
            Text(
              'Share sales unavailable',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'No documented sell-shares endpoint is available, so this screen cannot safely submit or simulate a sale.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}
