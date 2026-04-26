import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';
import '../../core/color_ext.dart';
import 'investment_state_provider.dart';

String _formatActivityDate(DateTime d) {
  return '${d.day}/${d.month}/${d.year}';
}

class InvestmentActivityScreen extends ConsumerWidget {
  const InvestmentActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(investmentProvider);
    final activities = state.activities;

    return AppScaffold(
      title: 'Investment Activity',
      child: activities.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timeline_rounded,
                      size: 56,
                      color: theme.colorScheme.primary.withOpacitySafe(0.65),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No investment activity yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Start an investment plan to see your timeline here.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacitySafe(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: _SummaryItem(
                          label: 'Total Invested',
                          value: 'GH₵${state.totalInvested.toStringAsFixed(2)}',
                          theme: theme,
                        ),
                      ),
                      Expanded(
                        child: _SummaryItem(
                          label: 'Starts',
                          value: '${state.activePlans}',
                          theme: theme,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ...activities.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacitySafe(
                                0.12,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.trending_up_rounded,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.planName,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Started on ${_formatActivityDate(entry.startedAt)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacitySafe(0.7),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ref: ${entry.reference}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacitySafe(0.65),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'GH₵${entry.amount.toStringAsFixed(2)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacitySafe(0.65),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
