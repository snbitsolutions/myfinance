import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';
import '../../core/constants/app_constants.dart';
import '../../core/color_ext.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/layout/responsive.dart';
import '../../core/modern_input.dart';
import '../../core/providers/app_providers.dart';
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
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(loanApplicationProvider);
    if (draft != null) {
      _amountController.text = draft.amount.toStringAsFixed(2);
      _purposeController.text = draft.purpose;
      _repaymentPlan = draft.repaymentPlan;
    }
  }

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

  String? get _amountError {
    if (_amountController.text.trim().isEmpty) return null;
    if (_loanAmount <= 0) return 'Enter a valid loan amount.';
    if (_loanAmount < AppConstants.loanMinAmount) {
      return 'Minimum loan amount is GH₵${AppConstants.loanMinAmount.toStringAsFixed(0)}.';
    }
    if (_loanAmount > AppConstants.loanMaxAmount) {
      return 'Maximum loan amount is GH₵${AppConstants.loanMaxAmount.toStringAsFixed(0)}.';
    }
    return null;
  }

  bool get _canSubmit =>
      _loanAmount >= AppConstants.loanMinAmount &&
      _loanAmount <= AppConstants.loanMaxAmount &&
      _purposeController.text.trim().isNotEmpty;

  Future<void> _submitApplication() async {
    if (!_canSubmit || _isSubmitting) return;
    final auth = ref.read(authProvider);
    final accountNumber = auth.userId?.trim() ?? '';
    if (!auth.isAuthenticated || accountNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in again before submitting a loan application.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final notifier = ref.read(loanApplicationProvider.notifier);
      await notifier.prepareDraft(
        amount: _loanAmount,
        purpose: _purposeController.text,
        repaymentPlan: _repaymentPlan,
      );
      final result = await ref
          .read(loanServiceProvider)
          .applyLoan(
            accountNumber: accountNumber,
            amount: _loanAmount,
            purpose: _purposeController.text,
            imeiNumber: await ref
                .read(deviceIdentityServiceProvider)
                .getBackendDeviceNumber(),
          );
      await notifier.markSubmitted(message: result['message']?.toString());
      if (mounted) context.go('/loan-status');
    } on AppException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
      backRoute: '/loans',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= Responsive.medium;

          final infoBanner = Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E6B47),
                  theme.colorScheme.primary,
                  const Color(0xFF3DA66B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.22),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.rocket_launch_rounded,
                        size: 27,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ADEPA TEACHERS LOANS',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Funds for what matters',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Prepare your loan details before submission.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.90),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_outward_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: _LoanHeroMetric(
                          value: 'Draft',
                          label: 'Preparation',
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      const Expanded(
                        child: _LoanHeroMetric(
                          value: 'Not sent',
                          label: 'Submission',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _LoanInfoChip(
                      theme: theme,
                      icon: Icons.verified_user_outlined,
                      label: 'No application is sent from this screen',
                    ),
                    _LoanInfoChip(
                      theme: theme,
                      icon: Icons.visibility_outlined,
                      label: 'Final terms are confirmed by the lender',
                    ),
                  ],
                ),
              ],
            ),
          );

          final submitButton = AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: _canSubmit
                  ? null
                  : theme.colorScheme.surfaceContainerHighest,
              gradient: _canSubmit
                  ? LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withOpacitySafe(0.8),
                        theme.colorScheme.primary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              borderRadius: BorderRadius.circular(12),
              boxShadow: _canSubmit
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : const [],
            ),
            child: ElevatedButton(
              onPressed: _canSubmit && !_isSubmitting
                  ? _submitApplication
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isSubmitting) ...[
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Submitting...'),
                  ] else ...[
                    const Text('Submit Application'),
                    const SizedBox(width: 8),
                    const Icon(Icons.send_rounded, size: 18),
                  ],
                ],
              ),
            ),
          );

          final formCard = AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Let’s plan your loan',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your requested amount and purpose. Your application will be sent securely for review.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacitySafe(0.68),
                  ),
                ),
                const SizedBox(height: 14),
                _ApplicationStepRow(
                  theme: theme,
                  step: '1',
                  title: 'Set your amount',
                  isComplete: _loanAmount >= 100,
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
                _ApplicationStepRow(
                  theme: theme,
                  step: '2',
                  title: 'Tell us what it is for',
                  isComplete: _purposeController.text.trim().isNotEmpty,
                ),
                ModernInput(
                  label: 'Purpose',
                  hintText: 'e.g., school fees, rent, business stock',
                  controller: _purposeController,
                  maxLines: 3,
                  prefixIcon: Icons.description,
                  helperText:
                      'A clear purpose helps us review your application.',
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                _ApplicationStepRow(
                  theme: theme,
                  step: '3',
                  title: 'Choose a preferred duration',
                  isComplete: true,
                ),
                const SizedBox(height: 6),
                ..._repaymentPlans.map(
                  (plan) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _RepaymentPlanOption(
                      theme: theme,
                      plan: plan,
                      rate:
                          'Planning preference only — not included in the submitted request',
                      monthlyAmount: null,
                      selected: _repaymentPlan == plan,
                      onTap: () => setState(() => _repaymentPlan = plan),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Repayment rates and estimates are not shown because approved terms have not been configured.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
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

class _LoanHeroMetric extends StatelessWidget {
  final String value;
  final String label;

  const _LoanHeroMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _ApplicationStepRow extends StatelessWidget {
  final ThemeData theme;
  final String step;
  final String title;
  final bool isComplete;

  const _ApplicationStepRow({
    required this.theme,
    required this.step,
    required this.title,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isComplete
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
          ),
          child: isComplete
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text(
                  step,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RepaymentPlanOption extends StatelessWidget {
  final ThemeData theme;
  final String plan;
  final String rate;
  final double? monthlyAmount;
  final bool selected;
  final VoidCallback onTap;

  const _RepaymentPlanOption({
    required this.theme,
    required this.plan,
    required this.rate,
    required this.monthlyAmount,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withOpacitySafe(0.08)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withOpacitySafe(0.2),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacitySafe(0.45),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(rate, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              if (monthlyAmount != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'GH₵${monthlyAmount!.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text('per month', style: theme.textTheme.labelSmall),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
