import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';

class BuySharesScreen extends StatefulWidget {
  final String? shareId;

  const BuySharesScreen({
    super.key,
    this.shareId,
  });

  @override
  State<BuySharesScreen> createState() => _BuySharesScreenState();
}

class _BuySharesScreenState extends State<BuySharesScreen> {
  late Map<String, dynamic> share;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController();
    _priceController = TextEditingController();
    
    // Mock share data
    share = {
      'id': 'SH-001',
      'company': 'AdePa Fintech Ltd',
      'current_price': 12.50,
      'market_cap': 50000000.00,
      'pe_ratio': 18.5,
      'dividend_yield': 6.00,
      'icon': Icons.business,
    };
    
    _priceController.text = share['current_price'].toString();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  double get _totalCost {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    return quantity * price;
  }

  double get _transactionFee {
    return _totalCost * 0.01; // 1% fee
  }

  double get _totalAmount {
    return _totalCost + _transactionFee;
  }

  bool get _canProceed {
    return _quantityController.text.isNotEmpty && 
           int.tryParse(_quantityController.text) != null &&
           int.tryParse(_quantityController.text)! > 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return AppScaffold(
      title: 'Buy Shares',
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Share Header
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          share['icon'] as IconData,
                          color: primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              share['company'] as String,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'GH₵ ${(share['current_price'] as double).toStringAsFixed(2)} per share',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Quantity Input
              Text(
                'Number of Shares',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter quantity',
                  prefixIcon: const Icon(Icons.shopping_basket),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              // Quick Selection Buttons
              Row(
                children: [
                  Expanded(
                    child: _QuickActionButton(
                      label: '10',
                      onTap: () {
                        _quantityController.text = '10';
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickActionButton(
                      label: '25',
                      onTap: () {
                        _quantityController.text = '25';
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickActionButton(
                      label: '50',
                      onTap: () {
                        _quantityController.text = '50';
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickActionButton(
                      label: '100',
                      onTap: () {
                        _quantityController.text = '100';
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Price Info
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _PriceRow(
                        label: 'Unit Price',
                        value: 'GH₵ ${(share['current_price'] as double).toStringAsFixed(2)}',
                        theme: theme,
                      ),
                      Divider(height: 16, color: theme.dividerColor),
                      _PriceRow(
                        label: 'Quantity',
                        value: _quantityController.text.isEmpty 
                            ? '0' 
                            : _quantityController.text,
                        theme: theme,
                      ),
                      Divider(height: 16, color: theme.dividerColor),
                      _PriceRow(
                        label: 'Total Cost',
                        value: 'GH₵ ${_totalCost.toStringAsFixed(2)}',
                        theme: theme,
                      ),
                      Divider(height: 16, color: theme.dividerColor),
                      _PriceRow(
                        label: 'Transaction Fee (1%)',
                        value: 'GH₵ ${_transactionFee.toStringAsFixed(2)}',
                        theme: theme,
                      ),
                      Divider(height: 16, color: theme.dividerColor),
                      _PriceRow(
                        label: 'Total Amount',
                        value: 'GH₵ ${_totalAmount.toStringAsFixed(2)}',
                        theme: theme,
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Company Details
              Text(
                'Company Details',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  children: [
                    _DetailRow(
                      label: 'Market Cap',
                      value: 'GH₵ ${(share['market_cap'] as double) / 1000000} M',
                      theme: theme,
                    ),
                    Divider(height: 1, color: theme.dividerColor),
                    _DetailRow(
                      label: 'P/E Ratio',
                      value: (share['pe_ratio'] as double).toStringAsFixed(2),
                      theme: theme,
                    ),
                    Divider(height: 1, color: theme.dividerColor),
                    _DetailRow(
                      label: 'Dividend Yield',
                      value: '${(share['dividend_yield'] as double).toStringAsFixed(2)}%',
                      theme: theme,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Review & Confirm Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _canProceed
                      ? () {
                          context.push('/shares/buy/review', extra: {
                            'company': share['company'],
                            'quantity': int.parse(_quantityController.text),
                            'price': share['current_price'],
                            'total': _totalAmount,
                          });
                        }
                      : null,
                  child: const Text('Review & Confirm'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.primary),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final bool isBold;

  const _PriceRow({
    required this.label,
    required this.value,
    required this.theme,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? theme.colorScheme.primary : null,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
