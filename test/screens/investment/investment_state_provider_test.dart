import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:adepa_teachers/screens/investment/investment_state_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persists and restores investment progress', () async {
    final notifier = InvestmentNotifier();
    notifier.recordStart(planName: 'Growth Plan', amount: 500);

    await Future<void>.delayed(const Duration(milliseconds: 20));

    final restored = InvestmentNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(restored.state.selectedPlanName, 'Growth Plan');
    expect(restored.state.activePlans, 1);
    expect(restored.state.totalInvested, 500);
    expect(restored.state.activities, isNotEmpty);
    expect(restored.state.activities.first.planName, 'Growth Plan');
    expect(restored.state.activities.first.amount, 500);
  });
}
