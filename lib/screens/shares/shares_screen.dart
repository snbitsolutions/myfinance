import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_scaffold.dart';
import '../../core/balance_card_shell.dart';
import '../../core/providers/app_providers.dart';

class SharesScreen extends ConsumerStatefulWidget {
  const SharesScreen({super.key});

  @override
  ConsumerState<SharesScreen> createState() => _SharesScreenState();
}

class _SharesScreenState extends ConsumerState<SharesScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final sharesAsync = ref.watch(sharesProvider);

    if (sharesAsync.isLoading) {
      return const AppScaffold(
        title: 'Shares',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (sharesAsync.hasError) {
      return AppScaffold(
        title: 'Shares',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 42),
                const SizedBox(height: 12),
                Text(
                  'Unable to load your shares.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Please check your connection and try again.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(sharesProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final apiShares = sharesAsync.value ?? const [];
    final displayedShares = apiShares.map(_mapApiShare).toList();
    final shareValuesAvailable = displayedShares.every(
      (share) => share['total_value'] != null,
    );
    final sharesOwnedAvailable = displayedShares.every(
      (share) => share['shares_owned'] != null,
    );
    final dividendDataAvailable = displayedShares.every(
      (share) => share['dividend_per_share'] != null,
    );
    final investedDataAvailable = displayedShares.every(
      (share) => share['invested_value'] != null,
    );

    final totalPortfolioValue = displayedShares.fold<double>(
      0,
      (sum, share) => sum + _asDouble(share['total_value']),
    );

    final totalShares = displayedShares.fold<int>(
      0,
      (sum, share) => sum + _asInt(share['shares_owned']),
    );

    final totalDividends = displayedShares.fold<double>(
      0,
      (sum, share) =>
          sum +
          (_asInt(share['shares_owned']) *
              _asDouble(share['dividend_per_share'])),
    );
    final totalInvested = displayedShares.fold<double>(
      0,
      (sum, share) => sum + _asDouble(share['invested_value']),
    );
    final hasInvestmentData = displayedShares.any(
      (share) => share['has_investment_data'] == true,
    );
    final totalGain = hasInvestmentData
        ? totalPortfolioValue - totalInvested
        : null;
    final returnPercent = hasInvestmentData && totalInvested > 0
        ? (totalGain! / totalInvested) * 100
        : null;

    return AppScaffold(
      title: 'Shares',
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primary,
                      primary.withValues(alpha: 0.9),
                      const Color(0xFF0C4A34),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.22),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -18,
                      right: -12,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(70),
                        ),
                      ),
                    ),
                    const Positioned(
                      right: -2,
                      bottom: -2,
                      child: AdepaLogoBadge(size: 128, opacity: 0.2),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Total Portfolio Value',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.82),
                                fontSize: 12,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.visibility,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          shareValuesAvailable
                              ? 'GH₵ ${totalPortfolioValue.toStringAsFixed(2).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}'
                              : 'Unavailable',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _StatPill(
                      label: sharesOwnedAvailable
                          ? 'Total Shares'
                          : 'Share Holdings',
                      value: sharesOwnedAvailable
                          ? '$totalShares'
                          : '${displayedShares.length}',
                      accent: const Color(0xFF2E8B57),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatPill(
                      label: 'Dividends',
                      value: dividendDataAvailable
                          ? 'GH₵ ${totalDividends.toStringAsFixed(2)}'
                          : 'Unavailable',
                      accent: const Color(0xFF0E8F87),
                    ),
                  ),
                ],
              ),
              if (displayedShares.isNotEmpty && !sharesOwnedAvailable) ...[
                const SizedBox(height: 8),
                Text(
                  'Share unit totals are not included in the provider data.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.add,
                      label: 'Buy\nShares',
                      onTap: () => context.go('/shares/buy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.arrow_forward,
                      label: 'Sell\nShares',
                      onTap: () => context.go('/shares/sell'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.description,
                      label: 'Statement',
                      onTap: () => context.go('/shares/statement'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.payments,
                      label: 'Dividends',
                      onTap: () => context.go('/shares/dividends'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // My Shares Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Shares',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      'Watchlist →',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (displayedShares.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    'No shares are currently linked to this account.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.68,
                      ),
                    ),
                  ),
                )
              else
                ...displayedShares.map(
                  (share) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ShareCard(
                      share: share,
                      theme: theme,
                      onTap: () =>
                          context.go('/shares/${share['id'] ?? 'unknown'}'),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Portfolio Overview Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    const Positioned(
                      top: -8,
                      right: -4,
                      child: AdepaLogoBadge(size: 108),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Portfolio Overview',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {},
                              child: Text(
                                'View Analytics →',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _OverviewItem(
                                icon: Icons.account_balance_wallet,
                                label: 'Total Invested',
                                value:
                                    hasInvestmentData && investedDataAvailable
                                    ? _formatCurrency(totalInvested)
                                    : '—',
                                theme: theme,
                              ),
                            ),
                            Expanded(
                              child: _OverviewItem(
                                icon: Icons.trending_up,
                                label: 'Total Gain',
                                value: totalGain == null
                                    ? '—'
                                    : _formatCurrency(totalGain),
                                theme: theme,
                              ),
                            ),
                            Expanded(
                              child: _OverviewItem(
                                icon: Icons.percent,
                                label: 'Overall Return',
                                value: returnPercent == null
                                    ? '—'
                                    : '${returnPercent.toStringAsFixed(1)}%',
                                theme: theme,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '') ?? '') ?? 0;
  }

  int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatCurrency(double value) {
    return 'GH₵ ${value.toStringAsFixed(2).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}';
  }

  Map<String, dynamic> _mapApiShare(Map<String, dynamic> item) {
    final ownedRaw =
        item['shares_owned'] ??
        item['quantity'] ??
        item['units'] ??
        item['shares'];
    final owned = _asInt(
      item['shares_owned'] ??
          item['quantity'] ??
          item['units'] ??
          item['shares'],
    );
    final priceRaw =
        item['current_price'] ??
        item['unit_price'] ??
        item['price'] ??
        item['share_price'];
    final price = _asDouble(
      item['current_price'] ??
          item['unit_price'] ??
          item['price'] ??
          item['share_price'],
    );
    final valueRaw =
        item['total_value'] ??
        item['market_value'] ??
        item['current_value'] ??
        item['value'] ??
        item['shares_value'] ??
        item['balance'];
    final value = _asDouble(
      item['total_value'] ??
          item['market_value'] ??
          item['current_value'] ??
          item['value'] ??
          item['shares_value'] ??
          item['balance'],
    );
    final investedValue =
        item['invested_value'] ??
        item['amount_invested'] ??
        item['purchase_value'] ??
        item['cost_basis'] ??
        item['principal'];
    return {
      ...item,
      'id':
          item['id'] ??
          item['share_id'] ??
          item['account_id'] ??
          item['product_id'] ??
          item['savings_id'] ??
          item['symbol'] ??
          'share',
      'company':
          item['company'] ??
          item['company_name'] ??
          item['product_name'] ??
          item['name'] ??
          'Shares',
      'shares_owned': ownedRaw == null ? null : owned,
      'current_price': priceRaw == null ? null : price,
      'total_value': valueRaw == null ? null : value,
      'invested_value': investedValue == null ? null : _asDouble(investedValue),
      'has_investment_data': investedValue != null,
      'dividend_per_share':
          item['dividend_per_share'] == null && item['dividend'] == null
          ? null
          : _asDouble(item['dividend_per_share'] ?? item['dividend']),
      'change_24h': item['change_24h'] == null && item['change'] == null
          ? null
          : _asDouble(item['change_24h'] ?? item['change']),
      'change_color': _asDouble(item['change_24h'] ?? item['change']) >= 0,
      'icon': Icons.business,
    };
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.18),
                      theme.colorScheme.primary.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _StatPill({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: accent,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ShareCard extends StatelessWidget {
  final Map<String, dynamic> share;
  final ThemeData theme;
  final VoidCallback onTap;

  const _ShareCard({
    required this.share,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;
    final sharesOwned = share['shares_owned'] as int?;
    final currentPrice = share['current_price'] as double?;
    final totalValue = share['total_value'] as double?;
    final change = share['change_24h'] as double?;
    final changeColor = (share['change_color'] as bool)
        ? Colors.green
        : Colors.red;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primary.withValues(alpha: 0.18),
                      primary.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  share['icon'] as IconData,
                  color: primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      share['company'] as String,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sharesOwned == null
                          ? 'Units held: Unavailable'
                          : currentPrice == null
                          ? '$sharesOwned shares'
                          : '$sharesOwned shares @ GH₵ ${currentPrice.toStringAsFixed(2)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    totalValue == null
                        ? 'Value unavailable'
                        : 'GH₵ ${totalValue.toStringAsFixed(2)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (change != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: changeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: changeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: theme.textTheme.bodySmall?.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  const _OverviewItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primary, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
