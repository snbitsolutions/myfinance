import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';
import '../../core/providers/app_providers.dart';

class ShareDetailScreen extends ConsumerWidget {
  final String? shareId;

  const ShareDetailScreen({super.key, this.shareId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shares = ref.watch(sharesProvider);
    final share = shares.valueOrNull?.cast<Map<String, dynamic>>().where(
          (item) => '${item['id'] ?? item['share_id'] ?? ''}' == shareId,
        ).firstOrNull;

    return AppScaffold(
      title: 'Share Details',
      child: shares.isLoading
          ? const Center(child: CircularProgressIndicator())
          : shares.hasError
              ? _Message(
                  icon: Icons.error_outline,
                  title: 'Unable to load share details',
                  body: 'Please check your connection and try again.',
                )
              : share == null
                  ? _Message(
                      icon: Icons.info_outline,
                      title: 'Share details unavailable',
                      body:
                          'The documented customer API does not provide separate share-detail data.',
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${share['company'] ?? share['name'] ?? 'Shares'}',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              _ValueRow(
                                label: 'Units held',
                                value: '${share['shares_owned'] ?? share['quantity'] ?? 'Unavailable'}',
                              ),
                              _ValueRow(
                                label: 'Portfolio value',
                                value: _amount(share['total_value'] ?? share['value'] ?? share['balance']),
                              ),
                              _ValueRow(
                                label: 'Purchase history',
                                value: 'Unavailable',
                              ),
                              _ValueRow(
                                label: 'Dividend history',
                                value: 'Unavailable',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Only values returned by the documented portfolio endpoint are shown. Share pricing, gains, and dividend details are not available from that contract.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
    );
  }

  static String _amount(Object? value) {
    if (value is num) return 'GH₵ ${value.toStringAsFixed(2)}';
    return 'Unavailable';
  }
}

class _ValueRow extends StatelessWidget {
  final String label;
  final String value;

  const _ValueRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Message({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 42),
              const SizedBox(height: 12),
              Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(body, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}
