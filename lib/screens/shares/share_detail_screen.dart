import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_scaffold.dart';
import '../../core/providers/app_providers.dart';

class ShareDetailScreen extends ConsumerWidget {
  final String? shareId;

  const ShareDetailScreen({super.key, this.shareId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shares = ref.watch(sharesProvider);

    return AppScaffold(
      title: 'Share Details',
      backRoute: '/shares',
      child: shares.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) {
          debugPrint('Unable to load share details: $error');
          return _Message(
            icon: Icons.error_outline_rounded,
            title: 'Unable to load share details',
            body: 'Please check your connection and try again.',
            action: FilledButton.icon(
              onPressed: () => ref.invalidate(sharesProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          );
        },
        data: (items) {
          final share = items.where((item) {
            final id =
                item['id'] ??
                item['share_id'] ??
                item['account_id'] ??
                item['product_id'] ??
                item['savings_id'] ??
                item['symbol'] ??
                'share';
            return id?.toString() == shareId;
          }).firstOrNull;

          if (share == null) {
            return const _Message(
              icon: Icons.info_outline_rounded,
              title: 'Share details unavailable',
              body:
                  'This holding is not in your current portfolio. Refresh your shares list and try again.',
            );
          }

          return _ShareDetails(share: share);
        },
      ),
    );
  }
}

class _ShareDetails extends StatelessWidget {
  final Map<String, dynamic> share;

  const _ShareDetails({required this.share});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final company =
        share['company'] ??
        share['company_name'] ??
        share['product_name'] ??
        share['name'] ??
        'Shares';
    final units = _number(
      share['shares_owned'] ??
          share['quantity'] ??
          share['units'] ??
          share['shares'],
    );
    final price = _number(
      share['current_price'] ??
          share['unit_price'] ??
          share['price'] ??
          share['share_price'],
    );
    final value = _number(
      share['total_value'] ??
          share['market_value'] ??
          share['current_value'] ??
          share['value'] ??
          share['shares_value'] ??
          share['balance'],
    );
    final invested = _number(
      share['invested_value'] ??
          share['amount_invested'] ??
          share['purchase_value'] ??
          share['cost_basis'] ??
          share['principal'],
    );
    final dividendPerShare = _number(
      share['dividend_per_share'] ?? share['dividend'],
    );
    final change = _number(share['change_24h'] ?? share['change']);
    final hasChange = share['change_24h'] != null || share['change'] != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primary, const Color(0xFF0C4A34)],
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.18),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.business_rounded,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Text(
                            company.toString(),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (hasChange)
                          _ChangeBadge(value: change, isLight: true),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Portfolio value',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _formatAmount(value),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      units == null
                          ? 'Units held unavailable'
                          : '${_formatUnits(units)} ${units == 1 ? 'share' : 'shares'} held',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Holding details',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF1D2B23),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5EBE6)),
                ),
                child: Column(
                  children: [
                    _DetailRow(
                      label: 'Units held',
                      value: units == null
                          ? 'Unavailable'
                          : _formatUnits(units),
                      icon: Icons.pie_chart_outline_rounded,
                    ),
                    _DetailRow(
                      label: 'Price per share',
                      value: _formatAmount(price),
                      icon: Icons.sell_outlined,
                    ),
                    _DetailRow(
                      label: 'Invested amount',
                      value: _formatAmount(invested),
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    if (value != null && invested != null)
                      _DetailRow(
                        label: 'Value change',
                        value: _formatAmount(value - invested),
                        icon: Icons.trending_up_rounded,
                        isLast: true,
                      ),
                    if (dividendPerShare != null)
                      _DetailRow(
                        label: 'Dividend per share',
                        value: _formatAmount(dividendPerShare),
                        icon: Icons.payments_outlined,
                        isLast: true,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => context.go('/shares/buy'),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Buy Shares'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/shares/sell'),
                      icon: const Icon(Icons.call_made_rounded),
                      label: const Text('Sell Shares'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'Your records',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF1D2B23),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              _NavigationTile(
                icon: Icons.receipt_long_rounded,
                title: 'Portfolio statement',
                subtitle: 'Review your portfolio records',
                onTap: () => context.go('/shares/statement'),
              ),
              const SizedBox(height: 10),
              _NavigationTile(
                icon: Icons.payments_outlined,
                title: 'Dividend history',
                subtitle: 'View available dividend records',
                onTap: () => context.go('/shares/dividends'),
              ),
              const SizedBox(height: 14),
              Text(
                'Values and records are shown only when provided by your portfolio data.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF708077),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isLast;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: isLast
          ? null
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF0F3F1))),
            ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF528265), size: 19),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF708077), fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Color(0xFF26372D),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavigationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5EBE6)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3ED),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: const Color(0xFF286B45), size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF26372D),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF708077),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF708077)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChangeBadge extends StatelessWidget {
  final double? value;
  final bool isLight;

  const _ChangeBadge({required this.value, this.isLight = false});

  @override
  Widget build(BuildContext context) {
    final isPositive = (value ?? 0) >= 0;
    final color = isLight
        ? Colors.white
        : isPositive
        ? const Color(0xFF28784D)
        : const Color(0xFFB44343);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: isLight
            ? Colors.white.withValues(alpha: 0.14)
            : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${isPositive ? '+' : ''}${value?.toStringAsFixed(1) ?? '0.0'}%',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: const Color(0xFF528265)),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

double? _number(Object? value) {
  if (value is num) return value.toDouble();
  final text = value?.toString().replaceAll(',', '').trim();
  if (text == null || text.isEmpty) return null;
  return double.tryParse(text);
}

String _formatAmount(double? value) {
  if (value == null) return 'Unavailable';
  final formatted = value
      .toStringAsFixed(2)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
  return 'GH₵ $formatted';
}

String _formatUnits(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(2);
}
