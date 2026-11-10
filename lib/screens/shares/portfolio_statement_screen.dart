import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';
import '../../core/providers/app_providers.dart';

class PortfolioStatementScreen extends ConsumerStatefulWidget {
  const PortfolioStatementScreen({
    super.key,
    this.productId,
    this.accountTitle,
    this.isShares = false,
  });

  final String? productId;
  final String? accountTitle;
  final bool isShares;

  @override
  ConsumerState<PortfolioStatementScreen> createState() =>
      _PortfolioStatementScreenState();
}

class _PortfolioStatementScreenState
    extends ConsumerState<PortfolioStatementScreen> {
  String? _selectedShareProductId;

  List<({String id, String name})> _shareProducts(
    List<Map<String, dynamic>> shares,
  ) {
    final products = <({String id, String name})>[];
    final seenIds = <String>{};

    for (final share in shares) {
      final id =
          (share['product_id'] ??
                  share['share_id'] ??
                  share['account_id'] ??
                  share['savings_id'] ??
                  share['id'])
              ?.toString()
              .trim();
      if (id == null || id.isEmpty || !seenIds.add(id)) continue;

      final name =
          (share['product_name'] ??
                  share['company_name'] ??
                  share['name'] ??
                  share['company'])
              ?.toString()
              .trim();
      products.add((id: id, name: name?.isNotEmpty == true ? name! : 'Shares'));
    }

    return products;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sharesAsync = widget.isShares ? ref.watch(sharesProvider) : null;
    final shareProducts = sharesAsync?.valueOrNull == null
        ? const <({String id, String name})>[]
        : _shareProducts(sharesAsync!.valueOrNull!);
    final selectedShare = shareProducts.where(
      (product) => product.id == _selectedShareProductId,
    );
    final effectiveShareId = selectedShare.isNotEmpty
        ? selectedShare.first.id
        : shareProducts.firstOrNull?.id;
    final productId = widget.isShares
        ? effectiveShareId
        : widget.productId?.trim();
    final statementAsync = productId == null || productId.isEmpty
        ? null
        : ref.watch(productStatementProvider(productId));

    return AppScaffold(
      title: widget.isShares ? 'Portfolio Statement' : 'Savings Statement',
      backRoute: widget.isShares ? '/shares' : '/savings',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.isShares && sharesAsync!.isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (widget.isShares && sharesAsync!.hasError)
              Expanded(
                child: _StatementMessage(
                  icon: Icons.cloud_off_outlined,
                  message: 'Unable to load your share accounts.',
                  actionLabel: 'Try again',
                  onPressed: () => ref.invalidate(sharesProvider),
                ),
              )
            else ...[
              if (widget.isShares && shareProducts.length > 1) ...[
                DropdownButtonFormField<String>(
                  initialValue: effectiveShareId,
                  decoration: const InputDecoration(
                    labelText: 'Share account',
                    border: OutlineInputBorder(),
                  ),
                  items: shareProducts
                      .map(
                        (product) => DropdownMenuItem(
                          value: product.id,
                          child: Text(product.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedShareProductId = value),
                ),
                const SizedBox(height: 16),
              ],
              if (widget.accountTitle?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    widget.accountTitle!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Expanded(
                child: _buildStatementContent(
                  context,
                  productId,
                  statementAsync,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatementContent(
    BuildContext context,
    String? productId,
    AsyncValue<List<Map<String, dynamic>>>? statementAsync,
  ) {
    if (productId == null || productId.isEmpty) {
      return _StatementMessage(
        icon: Icons.description_outlined,
        message: widget.isShares
            ? 'No share product IDs are available for a statement.'
            : 'This savings goal has no linked product ID, so a statement is unavailable.',
      );
    }

    return statementAsync!.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _StatementMessage(
        icon: Icons.error_outline_rounded,
        message: 'Unable to load this statement.',
        actionLabel: 'Retry',
        onPressed: () => ref.invalidate(productStatementProvider(productId)),
      ),
      data: (transactions) {
        if (transactions.isEmpty) {
          return const _StatementMessage(
            icon: Icons.receipt_long_outlined,
            message:
                'No statement transactions were returned for this account.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(productStatementProvider(productId));
            await ref.read(productStatementProvider(productId).future);
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _StatementTransaction(transaction: transactions[index]),
          ),
        );
      },
    );
  }
}

class _StatementTransaction extends StatelessWidget {
  const _StatementTransaction({required this.transaction});

  final Map<String, dynamic> transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = transaction['amount'];
    final formattedAmount = amount is num
        ? 'GH₵ ${amount.toStringAsFixed(2)}'
        : 'Amount unavailable';
    final type = transaction['type']?.toString() ?? 'Transaction';
    final normalizedType = type.trim().toLowerCase();
    final isDeposit =
        normalizedType.contains('credit') || normalizedType.contains('deposit');
    final isWithdrawal =
        normalizedType.contains('debit') || normalizedType.contains('withdraw');
    final transactionColor = isDeposit
        ? theme.colorScheme.primary
        : isWithdrawal
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;
    final transactionIcon = isDeposit
        ? Icons.call_received_rounded
        : isWithdrawal
        ? Icons.call_made_rounded
        : Icons.receipt_long_outlined;
    final date = transaction['date']?.toString() ?? '';
    final description = transaction['description']?.toString().trim() ?? '';

    return AppCard(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: transactionColor.withValues(alpha: 0.1),
          child: Icon(transactionIcon, color: transactionColor),
        ),
        title: Text(
          description.isEmpty ? type : description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          [type, date].where((value) => value.isNotEmpty).join(' • '),
        ),
        trailing: Text(
          formattedAmount,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: transactionColor,
          ),
        ),
      ),
    );
  }
}

class _StatementMessage extends StatelessWidget {
  const _StatementMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onPressed,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onPressed != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onPressed, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
