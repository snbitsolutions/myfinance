import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';
import '../../core/color_ext.dart';
import '../../core/modern_input.dart';
import 'loan_application_provider.dart';

class ApplyLoanScreen extends ConsumerStatefulWidget {
  const ApplyLoanScreen({super.key});

  @override
  ConsumerState<ApplyLoanScreen> createState() => _ApplyLoanScreenState();
}

class _ApplyLoanScreenState extends ConsumerState<ApplyLoanScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  String _repaymentPlan = '3 months';

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ModernInput(
                    label: 'Loan Amount',
                    hintText: 'e.g., 1,000 (Ghana cedis)',
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    prefixText: 'GH₵ ',
                    prefixIcon: Icons.currency_exchange,
                    onChanged: (_) => setState(() {}),
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
                  const SizedBox(height: 16),
                  ModernInput(
                    label: 'Purpose',
                    hintText: 'What is the loan for?',
                    controller: _purposeController,
                    maxLines: 3,
                    prefixIcon: Icons.description,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Text('Repayment Plan', style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacitySafe(0.2),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: _repaymentPlan,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: ['3 months', '6 months', '12 months']
                          .map(
                            (p) => DropdownMenuItem(value: p, child: Text(p)),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _repaymentPlan = v ?? _repaymentPlan),
                    ),
                  ),
                  if (_canSubmit) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer
                            .withOpacitySafe(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Estimated Interest (${(_effectiveRate * 100).toStringAsFixed(0)}%)',
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            'GH₵${(_loanAmount * _effectiveRate).toStringAsFixed(2)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiaryContainer
                            .withOpacitySafe(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Estimated monthly payment',
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
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 52,
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
                child: const Text('Submit Application'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
