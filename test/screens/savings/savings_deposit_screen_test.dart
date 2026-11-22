import 'package:adepa_teachers/core/providers/app_providers.dart';
import 'package:adepa_teachers/screens/savings/savings_deposit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Future<void> pumpDepositScreen(
    WidgetTester tester, {
    required Map<String, dynamic> account,
  }) async {
    final router = GoRouter(
      initialLocation: '/deposit',
      routes: [
        GoRoute(
          path: '/deposit',
          builder: (context, state) =>
              const SavingsDepositScreen(savingsId: 'savings-1'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savingsProvider.overrideWith((ref) async => [account]),
          userProfileProvider.overrideWith((ref) async => const {}),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('uses backend account details and enforces GH₵10 minimum', (
    tester,
  ) async {
    await pumpDepositScreen(
      tester,
      account: {
        'savings_id': 'savings-1',
        'name': 'Member Savings',
        'balance': 72.5,
      },
    );

    expect(find.text('Member Savings'), findsOneWidget);
    expect(find.text('GH₵ 72.50'), findsOneWidget);

    final amountField = find.byType(TextField);
    await tester.enterText(amountField, '9.99');
    await tester.pump();

    expect(find.text('The minimum deposit is GH₵ 10.00.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
          .onPressed,
      isNull,
    );

    await tester.enterText(amountField, '10');
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('shows zero balance in cedis when backend balance is missing', (
    tester,
  ) async {
    await pumpDepositScreen(
      tester,
      account: {'savings_id': 'savings-1', 'name': 'Member Savings'},
    );

    expect(find.text('GH₵ 0.00'), findsOneWidget);
    expect(find.textContaining('unavailable'), findsNothing);
    expect(find.text('—'), findsNothing);
  });

  testWidgets('missing savings account does not show unavailable wording', (
    tester,
  ) async {
    await pumpDepositScreen(tester, account: {});

    expect(find.text('Savings account not found'), findsOneWidget);
    expect(find.textContaining('unavailable'), findsNothing);
  });
}
