import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:adepa_teachers/screens/loans/loan_application_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persists and restores a draft without implying submission', () async {
    final notifier = LoanApplicationNotifier();
    await notifier.prepareDraft(
      amount: 1500,
      purpose: 'Stock purchase',
      repaymentPlan: '6 months',
    );

    await Future<void>.delayed(const Duration(milliseconds: 20));

    final restored = LoanApplicationNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(restored.state, isNotNull);
    expect(restored.state!.amount, 1500);
    expect(restored.state!.purpose, 'Stock purchase');
    expect(restored.state!.repaymentPlan, '6 months');
    expect(restored.state!.toJson().containsKey('referenceNumber'), isFalse);
    expect(restored.state!.toJson().containsKey('effectiveRate'), isFalse);
  });

  test('clears the saved loan application draft', () async {
    final notifier = LoanApplicationNotifier();
    await notifier.prepareDraft(
      amount: 1200,
      purpose: 'School fees',
      repaymentPlan: '3 months',
    );
    await notifier.clear();
    final restored = LoanApplicationNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(restored.state, isNull);
  });

  test('persists submission state separately from an unsubmitted draft', () async {
    final notifier = LoanApplicationNotifier();
    await notifier.prepareDraft(
      amount: 1200,
      purpose: 'School fees',
      repaymentPlan: '3 months',
    );
    await notifier.markSubmitted(message: 'Application received');

    final restored = LoanApplicationNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(restored.state!.isSubmitted, isTrue);
    expect(restored.state!.submissionMessage, 'Application received');
  });
}
