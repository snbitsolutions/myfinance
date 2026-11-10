import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/action_triple_row.dart';
import '../../core/app_card.dart';
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
    final sharesAsync = ref.watch(sharesProvider);

    if (sharesAsync.isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F8F7),
        appBar: _buildAppBar(theme),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (sharesAsync.hasError) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F8F7),
        appBar: _buildAppBar(theme),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AppCard(
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

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: _buildAppBar(theme),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BalanceCardShell(
                gradientColors: const [Color(0xFF0D6B4D), Color(0xFF2D8E66)],
                shadowColor: const Color(0xFF0D6B4D).withValues(alpha: 0.25),
                contentPadding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Share Value',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Icon(
                          Icons.visibility_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      sharesAsync.hasValue && shareValuesAvailable
                          ? _formatCurrency(totalPortfolioValue)
                          : 'GH₵ —',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: Colors.white24, thickness: 1),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatColumn(
                            context,
                            icon: Icons.pie_chart_outline_rounded,
                            label: sharesOwnedAvailable
                                ? 'Total Shares'
                                : 'Share Holdings',
                            value: sharesAsync.hasValue
                                ? sharesOwnedAvailable
                                      ? '$totalShares'
                                      : '${displayedShares.length}'
                                : '—',
                          ),
                        ),
                        Expanded(
                          child: _buildStatColumn(
                            context,
                            icon: Icons.payments_outlined,
                            label: 'Dividends',
                            value: dividendDataAvailable
                                ? _formatCurrency(totalDividends)
                                : '—',
                          ),
                        ),
                        Expanded(
                          child: _buildStatColumn(
                            context,
                            icon: Icons.account_balance_wallet_outlined,
                            label: 'Total Invested',
                            value: hasInvestmentData && investedDataAvailable
                                ? _formatCurrency(totalInvested)
                                : '—',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Quick Actions',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ActionTripleRow(
                deposit: ActionItem(
                  label: 'Buy Shares',
                  icon: Icons.add_circle_outline,
                  color: theme.colorScheme.primary,
                  onTap: () => context.go('/shares/buy'),
                ),
                withdraw: ActionItem(
                  label: 'Sell Shares',
                  icon: Icons.remove_circle_outline,
                  color: theme.colorScheme.error,
                  onTap: () => context.go('/shares/sell'),
                ),
                transfer: ActionItem(
                  label: 'Statement',
                  icon: Icons.receipt_long_outlined,
                  color: const Color(0xFF1B8A9B),
                  onTap: () => context.go('/shares/statement'),
                ),
                extra: ActionItem(
                  label: 'Dividend history',
                  icon: Icons.payments_outlined,
                  color: theme.colorScheme.primary,
                  onTap: () => context.go('/shares/dividends'),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    'My Share Holdings',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF1D2B26),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (!sharesAsync.hasValue)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    child: Text(
                      'Share account data is unavailable. Holdings are not shown until the backend responds.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              if (displayedShares.isEmpty)
                const AppCard(
                  child: Text(
                    'No shares are currently linked to this account.',
                  ),
                )
              else
                ...displayedShares.map(
                  (share) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ShareCard(
                      share: share,
                      theme: theme,
                      onTap: () =>
                          context.go('/shares/${share['id'] ?? 'unknown'}'),
                    ),
                  ),
                ),
              if (hasInvestmentData) ...[
                const SizedBox(height: 8),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Portfolio Overview',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _OverviewItem(
                              icon: Icons.account_balance_wallet_outlined,
                              label: 'Total Invested',
                              value: investedDataAvailable
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
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(ThemeData theme) {
    return AppBar(
      title: const Text('Shares'),
      backgroundColor: Colors.white,
      foregroundColor: theme.colorScheme.primary,
      elevation: 0.5,
      leading: IconButton(
        onPressed: () => context.go('/home'),
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        tooltip: 'Back',
      ),
      actions: [
        IconButton(
          onPressed: () => context.go('/shares/buy'),
          icon: const Icon(Icons.add_circle_outline_rounded),
          tooltip: 'Buy Shares',
        ),
      ],
    );
  }

  Widget _buildStatColumn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
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
