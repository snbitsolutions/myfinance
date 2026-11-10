import 'package:flutter/material.dart';

import '../../core/app_scaffold.dart';

class BuySharesScreen extends StatelessWidget {
  final String? shareId;

  const BuySharesScreen({super.key, this.shareId});

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: 'Buy Shares',
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
              'Share purchases unavailable',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'No documented buy-shares endpoint is available, so this screen cannot safely submit or simulate a purchase.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}
