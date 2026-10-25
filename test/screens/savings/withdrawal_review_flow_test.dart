import 'package:adepa_teachers/screens/savings/withdrawal_flow/authenticate_withdrawal_screen.dart';
import 'package:adepa_teachers/screens/savings/withdrawal_flow/review_withdrawal_screen.dart';
import 'package:adepa_teachers/screens/savings/withdrawal_flow/withdrawal_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('review authorizes and opens withdrawal PIN authentication', (
    tester,
  ) async {
    final data = WithdrawalData(
      savingsId: 'savings-1',
      amount: 100,
      phoneNumber: '0241234567',
      method: 'Mobile Money (MTN)',
      fromAccount: 'Member Savings',
      usedDailyLimit: 0,
      usedMonthlyLimit: 0,
      availableBalance: 500,
    );
    final router = GoRouter(
      initialLocation: '/review',
      routes: [
        GoRoute(
          path: '/review',
          builder: (context, state) => ReviewWithdrawalScreen(data: data),
        ),
        GoRoute(
          path: '/withdrawal/authenticate',
          builder: (context, state) => AuthenticateWithdrawalScreen(
            data: state.extra! as WithdrawalData,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Not provided'), findsOneWidget);
    expect(find.text('GH₵ 100.00'), findsNWidgets(2));
    expect(
      find.text(
        'Continuing will submit a withdrawal request to your savings provider. The provider has not supplied a fee estimate, so any additional charge is not shown here. A pending result means the provider has not confirmed completion.',
      ),
      findsOneWidget,
    );
    final authorize = find.text('Authorize Withdrawal');
    await tester.ensureVisible(authorize);
    await tester.tap(authorize);
    await tester.pumpAndSettle();

    expect(find.byType(AuthenticateWithdrawalScreen), findsOneWidget);
    expect(find.text('Enter your PIN'), findsOneWidget);
  });
}
