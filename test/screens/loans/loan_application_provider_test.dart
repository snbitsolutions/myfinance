import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:adepa_teachers/screens/loans/loan_application_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persists and restores submitted loan state', () async {
    final notifier = LoanApplicationNotifier();
    notifier.submit(
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
  });

  test('persists repayment progress updates', () async {
    final notifier = LoanApplicationNotifier();
    notifier.submit(
      amount: 1200,
      purpose: 'School fees',
      repaymentPlan: '3 months',
    );
    notifier.recordPayment(200);

    await Future<void>.delayed(const Duration(milliseconds: 20));

    final restored = LoanApplicationNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(restored.state, isNotNull);
    expect(restored.state!.repaidAmount, 200);
  });
}
