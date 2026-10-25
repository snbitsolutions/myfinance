import 'package:adepa_teachers/screens/payment/payment_receipt_screen.dart';
import 'package:adepa_teachers/screens/payment/payment_success_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget _testApp(Widget child) {
  return MaterialApp.router(
    routerConfig: GoRouter(
      routes: [GoRoute(path: '/', builder: (context, state) => child)],
    ),
  );
}

void main() {
  testWidgets('completed deposit status matches its receipt wording', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        const PaymentSuccessScreen(
          amount: 25,
          title: 'Provider reported completion',
          message: 'The provider reported that the deposit request completed.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Deposit Status'), findsOneWidget);
    expect(find.text('Provider reported completion'), findsOneWidget);
    expect(find.text('Amount Deposited'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    final appBarTheme = Theme.of(tester.element(find.byType(AppBar)));
    expect(appBar.backgroundColor, appBarTheme.colorScheme.surface);
    expect(appBar.foregroundColor, appBarTheme.colorScheme.primary);

    await tester.pumpWidget(_testApp(const PaymentReceiptScreen(amount: 25)));
    await tester.pumpAndSettle();

    expect(find.text('Provider reported completion'), findsOneWidget);
    expect(find.text('Amount Deposited'), findsOneWidget);
  });

  testWidgets('pending deposit status matches its receipt wording', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        const PaymentSuccessScreen(
          amount: 25,
          title: 'Deposit Pending',
          message: 'Your deposit request is awaiting provider confirmation.',
          isPending: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Deposit Status'), findsOneWidget);
    expect(find.text('Deposit Pending'), findsOneWidget);
    expect(find.text('Amount Requested'), findsOneWidget);
    expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);

    await tester.pumpWidget(
      _testApp(const PaymentReceiptScreen(amount: 25, isPending: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Amount Requested'), findsOneWidget);
  });
}
