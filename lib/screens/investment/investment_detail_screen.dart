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
    final isFixedDeposit =
        '${investment?['type'] ?? investment?['investment_type'] ?? ''}'
            .toLowerCase() ==
        'fixed deposit';
    final title = isFixedDeposit ? 'Fixed Deposit' : 'Investment Details';

    return AppScaffold(
      title: title,
      child: investments.isLoading
          ? const Center(child: CircularProgressIndicator())
          : investments.hasError
          ? const _Unavailable(
              title: 'Account data unavailable',
              body:
                  'We could not load this account right now. Please try again.',
            )
          : investment == null
          ? const _Unavailable(
              title: 'Account details unavailable',
              body:
                  'No account record matches this selection.',
            )
          : _AccountDetails(
              investment: investment,
              isFixedDeposit: isFixedDeposit,
            ),
    );
  }

  static String _amount(Object? value) {
    final amount = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString().replaceAll(',', '') ?? '');
    return amount == null ? 'Unavailable' : 'GH₵ ${amount.toStringAsFixed(2)}';
  }
}

class _AccountDetails extends StatelessWidget {
  final Map<String, dynamic> investment;
  final bool isFixedDeposit;

  const _AccountDetails({
    required this.investment,
    required this.isFixedDeposit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final principal = investment['principal'];
    final currentValue =
        investment['current_value'] ??
        investment['value'] ??
        investment['balance'];
    final plan =
        investment['plan'] ??
        investment['plan_name'] ??
        investment['pro_name'] ??
        'Investment Plan';
    final details = <(String, String)>[
      if (principal != null)
        ('Principal', InvestmentDetailScreen._amount(principal)),
      if (investment['interest_rate'] != null)
        ('Interest rate', '${investment['interest_rate']}%'),
      if (investment['duration'] != null) ('Term', '${investment['duration']} days'),
      if (investment['start_date'] != null)
        ('Opened', '${investment['start_date']}'),
      if (investment['maturity_date'] != null &&
          investment['maturity_date'] != '—')
        ('Maturity date', '${investment['maturity_date']}'),
      if (investment['status'] != null) ('Status', '${investment['status']}'),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D6B4D), Color(0xFF2D8E66)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D6B4D).withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isFixedDeposit
                          ? Icons.lock_clock_rounded
                          : Icons.account_balance_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$plan',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Current value',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                InvestmentDetailScreen._amount(currentValue),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Account details',
          style: theme.textTheme.titleMedium?.copyWith(
            color: const Color(0xFF1D2B26),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        AppCard(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              for (var index = 0; index < details.length; index++) ...[
                _DetailRow(label: details[index].$1, value: details[index].$2),
                if (index < details.length - 1)
                  const Divider(height: 18, color: Color(0xFFE3EAE6)),
              ],
              if (details.isEmpty)
                Text(
                  'Additional account details are not available.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6B7A74),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF6B7A74),
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF1D2B26),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
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
