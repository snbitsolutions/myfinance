import 'package:flutter/material.dart';

import '../../core/app_scaffold.dart';

class PortfolioStatementScreen extends StatelessWidget {
  const PortfolioStatementScreen({super.key});

  @override
  Widget build(BuildContext context) => AppScaffold(
        title: 'Portfolio Statement',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.description_outlined, size: 42),
                const SizedBox(height: 12),
                Text(
                  'Portfolio statement unavailable',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'The documented customer API provides current share balances only. It does not provide purchase, sale, or dividend transaction history.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
}
