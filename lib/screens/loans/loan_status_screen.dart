import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';
import 'loan_application_provider.dart';

class LoanStatusScreen extends ConsumerWidget {
  const LoanStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final draft = ref.watch(loanApplicationProvider);
    final isSubmitted = draft?.isSubmitted ?? false;

    return AppScaffold(
      title: 'Loan Application',
      backRoute: '/loans',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    draft == null
                        ? Icons.edit_note_rounded
                        : isSubmitted
                        ? Icons.check_circle_outline_rounded
                        : Icons.info_outline_rounded,
                    size: 52,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    draft == null
                        ? 'No saved draft'
                        : isSubmitted
                        ? 'Application submitted'
                        : 'Draft saved locally',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    draft == null
                        ? 'You can prepare your loan details in the application form.'
                        : isSubmitted
                        ? draft.submissionMessage?.isNotEmpty == true
                              ? draft.submissionMessage!
                              : 'Your application was received by the loan service. Submission does not mean the loan is approved.'
                        : 'This is only a draft on this device. Your loan application has not been submitted, and no application status or approval is available.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  if (draft != null) ...[
                    const SizedBox(height: 20),
                    _DraftDetail(
                      label: 'Requested amount',
                      value: 'GH₵${draft.amount.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 10),
                    _DraftDetail(label: 'Purpose', value: draft.purpose),
                    if (!isSubmitted) ...[
                      const SizedBox(height: 10),
                      _DraftDetail(
                        label: 'Planning duration',
                        value: draft.repaymentPlan,
                      ),
                    ],
                    const SizedBox(height: 10),
                    _DraftDetail(
                      label: 'Prepared',
                      value: MaterialLocalizations.of(
                        context,
                      ).formatMediumDate(draft.preparedAt),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.go('/loans'),
                          child: const Text('Back to Loans'),
                        ),
                      ),
                      if (!isSubmitted) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => context.go('/apply-loan'),
                            child: Text(
                              draft == null ? 'Apply for Loan' : 'Edit Draft',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DraftDetail extends StatelessWidget {
  final String label;
  final String value;

  const _DraftDetail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
