import 'package:adepa_teachers/screens/savings/withdrawal_flow/authenticate_withdrawal_screen.dart';
import 'package:adepa_teachers/screens/savings/withdrawal_flow/review_withdrawal_screen.dart';
import 'package:adepa_teachers/screens/savings/withdrawal_flow/withdrawal_model.dart';
import 'package:adepa_teachers/screens/savings/withdrawal_flow/withdrawal_screen.dart';
import 'package:adepa_teachers/core/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('withdraw back button returns to the savings account safely', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/savings/savings-1/withdraw',
      routes: [
        GoRoute(
          path: '/savings/:id',
          builder: (context, state) =>
              Text('Savings ${state.pathParameters['id']}'),
        ),
        GoRoute(
          path: '/savings/:id/withdraw',
          builder: (context, state) =>
              WithdrawalScreen(savingsId: state.pathParameters['id']),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          withdrawalAccountProvider('savings-1').overrideWith(
            (ref) async => {
              'savings_id': 'savings-1',
              'name': 'Member Savings',
              'balance': 500.0,
            },
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Withdraw from savings'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Savings savings-1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('withdrawal amount leaves at least GH₵50 in savings', () {
    expect(WithdrawalScreen.canWithdraw(amount: 450, balance: 500), isTrue);
    expect(WithdrawalScreen.canWithdraw(amount: 450.01, balance: 500), isFalse);
    expect(WithdrawalScreen.canWithdraw(amount: 1, balance: 50), isFalse);
  });

  testWidgets('review authorizes and opens withdrawal PIN authentication', (
    tester,
  ) async {
    final data = WithdrawalData(
      savingsId: 'savings-1',
      amount: 100,
      phoneNumber: '0241234567',
      method: 'Mobile Money (MTN)',
      fromAccount: 'Member Savings',
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

    expect(find.text('Provider fee'), findsNothing);
    expect(find.text('GH₵ 100.00'), findsNWidgets(2));
    expect(
      find.text(
        'At least GH₵50.00 will remain in your account after this withdrawal.',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.info_outline_rounded), findsNothing);
    final authorize = find.text('Authorize Withdrawal');
    await tester.ensureVisible(authorize);
    await tester.tap(authorize);
    await tester.pumpAndSettle();

    expect(find.byType(AuthenticateWithdrawalScreen), findsOneWidget);
    expect(find.text('Enter your PIN'), findsOneWidget);
  });
}
