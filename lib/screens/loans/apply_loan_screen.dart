import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';
import '../../core/modern_input.dart';

class ApplyLoanScreen extends StatefulWidget {
  const ApplyLoanScreen({super.key});

  @override
  State<ApplyLoanScreen> createState() => _ApplyLoanScreenState();
}

class _ApplyLoanScreenState extends State<ApplyLoanScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  String _repaymentPlan = '3 months';

  bool get _canSubmit {
    final amt = double.tryParse(_amountController.text) ?? 0;
    return amt > 0 && _purposeController.text.trim().isNotEmpty;
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
                    hintText: 'e.g., 1000',
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    prefixText: '₵ ',
                    prefixIcon: Icons.attach_money,
                    onChanged: (_) => setState(() {}),
                  ),
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
                        color: theme.colorScheme.outline.withOpacity(0.2),
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
                        color: theme.colorScheme.primaryContainer.withOpacity(
                          0.2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Estimated Interest (12%)',
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            '₵${(double.tryParse(_amountController.text) ?? 0) * 0.12}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
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
                onPressed: _canSubmit ? () => context.go('/loan-status') : null,
                child: const Text('Submit Application'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
