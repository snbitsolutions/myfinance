import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';

class SellSharesScreen extends StatefulWidget {
  final String? shareId;

  const SellSharesScreen({
    super.key,
    this.shareId,
  });

  @override
  State<SellSharesScreen> createState() => _SellSharesScreenState();
}

class _SellSharesScreenState extends State<SellSharesScreen> {
  late Map<String, dynamic> share;
  late TextEditingController _quantityController;
  double _sliderValue = 0;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController();
    
    // Mock share data
    share = {
      'id': 'SH-001',
      'company': 'AdePa Fintech Ltd',
      'shares_owned': 500,
      'current_price': 12.50,
      'purchase_price': 10.00,
      'gain': 1250.00,
      'gain_percent': 25.00,
      'icon': Icons.business,
    };
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  double get _totalProceeds {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    return quantity * (share['current_price'] as double);
  }

  double get _transactionFee {
    return _totalProceeds * 0.01; // 1% fee
  }

  double get _netProceeds {
    return _totalProceeds - _transactionFee;
  }

  double get _unrealizedGain {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    return quantity * ((share['current_price'] as double) - (share['purchase_price'] as double));
  }

  bool get _canProceed {
    final qty = int.tryParse(_quantityController.text);
    return qty != null && qty > 0 && qty <= (share['shares_owned'] as int);
  }

  void _setQuantity(double value) {
    final maxShares = share['shares_owned'] as int;
    final quantity = (value * maxShares).round();
    _quantityController.text = quantity.toString();
    _sliderValue = value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final gainColor = _unrealizedGain > 0 ? Colors.green : Colors.red;

    return AppScaffold(
      title: 'Sell Shares',
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
                              'You own ${share['shares_owned']} shares',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color,
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

              // Current Price & Gain
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Price',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'GH₵ ${(share['current_price'] as double).toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Purchase Price',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'GH₵ ${(share['purchase_price'] as double).toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Gain',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(share['gain_percent'] as double).toStringAsFixed(2)}%',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: gainColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quantity Selection
              Text(
                'Number of Shares to Sell',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Slider for quantity selection
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Quantity',
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            '${_quantityController.text.isEmpty ? '0' : _quantityController.text} / ${share['shares_owned']}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Slider(
                        value: _sliderValue,
                        onChanged: _setQuantity,
                        min: 0,
                        max: 1,
                        divisions: (share['shares_owned'] as int),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('0', style: theme.textTheme.labelSmall),
                          Text('${share['shares_owned']}', style: theme.textTheme.labelSmall),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Quick Selection Buttons
              Text(
                'Or select',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionButton(
                      label: '25%',
                      onTap: () {
                        final qty = ((share['shares_owned'] as int) * 0.25).round();
                        _quantityController.text = qty.toString();
                        _sliderValue = 0.25;
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickActionButton(
                      label: '50%',
                      onTap: () {
                        final qty = ((share['shares_owned'] as int) * 0.5).round();
                        _quantityController.text = qty.toString();
                        _sliderValue = 0.5;
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickActionButton(
                      label: '75%',
                      onTap: () {
                        final qty = ((share['shares_owned'] as int) * 0.75).round();
                        _quantityController.text = qty.toString();
                        _sliderValue = 0.75;
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickActionButton(
                      label: '100%',
                      onTap: () {
                        _quantityController.text = (share['shares_owned']).toString();
                        _sliderValue = 1.0;
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Proceeds Summary
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
                        value: _quantityController.text.isEmpty ? '0' : _quantityController.text,
                        theme: theme,
                      ),
                      Divider(height: 16, color: theme.dividerColor),
                      _PriceRow(
                        label: 'Gross Proceeds',
                        value: 'GH₵ ${_totalProceeds.toStringAsFixed(2)}',
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
                        label: 'Unrealized Gain',
                        value: 'GH₵ ${_unrealizedGain.toStringAsFixed(2)}',
                        theme: theme,
                        isBold: true,
                        valueColor: gainColor,
                      ),
                      Divider(height: 16, color: theme.dividerColor),
                      _PriceRow(
                        label: 'Net Proceeds',
                        value: 'GH₵ ${_netProceeds.toStringAsFixed(2)}',
                        theme: theme,
                        isBold: true,
                      ),
                    ],
                  ),
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
                          context.push('/shares/sell/review', extra: {
                            'company': share['company'],
                            'quantity': int.parse(_quantityController.text),
                            'price': share['current_price'],
                            'proceeds': _netProceeds,
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
  final Color? valueColor;

  const _PriceRow({
    required this.label,
    required this.value,
    required this.theme,
    this.isBold = false,
    this.valueColor,
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
            color: valueColor ?? (isBold ? theme.colorScheme.primary : null),
          ),
        ),
      ],
    );
  }
}
