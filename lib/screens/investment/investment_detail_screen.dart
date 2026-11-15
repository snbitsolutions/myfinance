import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';
import '../../core/providers/app_providers.dart';

class InvestmentDetailScreen extends ConsumerWidget {
  final String? investmentId;

  const InvestmentDetailScreen({super.key, this.investmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investments = ref.watch(investmentsApiProvider);
    final investment = investments.valueOrNull
        ?.cast<Map<String, dynamic>>()
        .where(
          (item) =>
              '${item['id'] ?? item['investment_id'] ?? item['account_id'] ?? ''}' ==
              investmentId,
        )
        .firstOrNull;

    return AppScaffold(
      title: 'Investment Details',
      child: investments.isLoading
          ? const Center(child: CircularProgressIndicator())
          : investments.hasError
          ? const _Unavailable(
              title: 'Investment data unavailable',
              body:
                  'The documented customer API does not provide an investments endpoint.',
            )
          : investment == null
          ? const _Unavailable(
              title: 'Investment details unavailable',
              body:
                  'No documented investment detail record matches this account.',
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${investment['type'] ?? investment['investment_type'] ?? 'Investment'}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Current value: ${_amount(investment['current_value'] ?? investment['value'] ?? investment['balance'])}',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Interest, maturity, and transaction history: Unavailable',
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  static String _amount(Object? value) =>
      value is num ? 'GH₵ ${value.toStringAsFixed(2)}' : 'Unavailable';
}

class _Unavailable extends StatelessWidget {
  final String title;
  final String body;

  const _Unavailable({required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline, size: 42),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(body, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
