import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';
import '../../core/color_ext.dart';
import '../../core/layout/responsive.dart';
import '../../core/modern_input.dart';
import 'loan_application_provider.dart';

class ApplyLoanScreen extends ConsumerStatefulWidget {
  const ApplyLoanScreen({super.key});

  @override
  ConsumerState<ApplyLoanScreen> createState() => _ApplyLoanScreenState();
}

class _ApplyLoanScreenState extends ConsumerState<ApplyLoanScreen> {
  static const _quickAmounts = <int>[500, 1000, 2000, 5000];
  static const _repaymentPlans = <String>['3 months', '6 months', '12 months'];

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  String _repaymentPlan = '3 months';

  void _applyQuickAmount(int amount) {
    final text = amount.toString();
    _amountController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() {});
  }

  double _parseAmount(String value) {
    final normalized = value.replaceAll(',', '').trim();
    return double.tryParse(normalized) ?? 0;
  }

  double get _loanAmount => _parseAmount(_amountController.text);

  int get _planMonths => int.tryParse(_repaymentPlan.split(' ').first) ?? 3;

  double get _effectiveRate {
    switch (_planMonths) {
      case 3:
        return 0.06;
      case 6:
        return 0.10;
      default:
        return 0.12;
    }
  }

  String? get _amountError {
    if (_amountController.text.trim().isEmpty) return null;
    if (_loanAmount <= 0) return 'Enter a valid loan amount.';
    if (_loanAmount < 100) return 'Minimum loan amount is GH₵100.';
    return null;
  }

  bool get _canSubmit {
    return _loanAmount >= 100 &&
        _purposeController.text.trim().isNotEmpty &&
        _amountError == null;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Apply for Loan',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= Responsive.medium;

          final infoBanner = Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacitySafe(0.95),
                  theme.colorScheme.primaryContainer.withOpacitySafe(0.92),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.auto_graph_rounded,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fast loan approval',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Apply in minutes and receive a response quickly.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.90),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _LoanInfoChip(
                      theme: theme,
                      icon: Icons.check_circle_outline,
                      label: 'Quick review',
                    ),
                    const SizedBox(width: 8),
                    _LoanInfoChip(
                      theme: theme,
                      icon: Icons.schedule,
                      label: '1-2 day response',
                    ),
                  ],
                ),
              ],
            ),
          );

          final submitButton = Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacitySafe(0.8),
                  theme.colorScheme.primary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _canSubmit
                  ? () {
                      ref
                          .read(loanApplicationProvider.notifier)
                          .submit(
                            amount: _loanAmount,
                            purpose: _purposeController.text.trim(),
                            repaymentPlan: _repaymentPlan,
                          );
                      context.go('/loan-status');
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Submit Application'),
            ),
          );

          final formCard = AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Loan Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fill in the amount, purpose, and preferred repayment plan below.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacitySafe(0.68),
                  ),
                ),
                const SizedBox(height: 14),
                ModernInput(
                  label: 'Loan Amount',
                  hintText: 'e.g., 1,000 (Ghana cedis)',
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  prefixText: 'GH₵ ',
                  prefixIcon: Icons.account_balance_wallet,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickAmounts
                      .map(
                        (amount) => ActionChip(
                          label: Text('GH₵$amount'),
                          avatar: const Icon(Icons.flash_on_rounded, size: 16),
                          onPressed: () => _applyQuickAmount(amount),
                        ),
                      )
                      .toList(),
                ),
                if (_amountError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _amountError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                ModernInput(
                  label: 'Purpose',
                  hintText: 'What is the loan for?',
                  controller: _purposeController,
                  maxLines: 3,
                  prefixIcon: Icons.description,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Text('Repayment Plan', style: theme.textTheme.bodyLarge),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _repaymentPlans
                      .map(
                        (plan) => ChoiceChip(
                          label: Text(plan),
                          selected: _repaymentPlan == plan,
                          onSelected: (_) =>
                              setState(() => _repaymentPlan = plan),
                          selectedColor: theme.colorScheme.primaryContainer
                              .withOpacitySafe(0.6),
                          side: BorderSide(
                            color: _repaymentPlan == plan
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withOpacitySafe(
                                    0.35,
                                  ),
                          ),
                          labelStyle: theme.textTheme.bodySmall?.copyWith(
                            color: _repaymentPlan == plan
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                      .toList(),
                ),
                if (_canSubmit) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacitySafe(
                        0.2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Repayment estimate',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Loan amount',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              'GH₵${_loanAmount.toStringAsFixed(2)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Interest', style: theme.textTheme.bodySmall),
                            Text(
                              'GH₵${(_loanAmount * _effectiveRate).toStringAsFixed(2)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total repayment',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              'GH₵${(_loanAmount + (_loanAmount * _effectiveRate)).toStringAsFixed(2)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Monthly payment',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              'GH₵${((_loanAmount + (_loanAmount * _effectiveRate)) / _planMonths).toStringAsFixed(2)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.tertiary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                if (!isTablet) ...[const SizedBox(height: 12), submitButton],
              ],
            ),
          );

          if (isTablet) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: Column(children: [infoBanner])),
                      const SizedBox(width: 20),
                      Expanded(flex: 6, child: Column(children: [formCard])),
                    ],
                  ),
                  const SizedBox(height: 16),
                  submitButton,
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                infoBanner,
                const SizedBox(height: 16),
                formCard,
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LoanInfoChip extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String label;

  const _LoanInfoChip({
    required this.theme,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
