import 'package:flutter/material.dart';

import '../../core/app_scaffold.dart';

class DividendHistoryScreen extends StatelessWidget {
  const DividendHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) => AppScaffold(
        title: 'Dividend History',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.receipt_long_outlined, size: 42),
                const SizedBox(height: 12),
                Text(
                  'Dividend history unavailable',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'The documented customer API provides portfolio balances only. It does not provide dividend history or payment dates.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
}
