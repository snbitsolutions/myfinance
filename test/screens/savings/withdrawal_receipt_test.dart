import 'package:adepa_teachers/screens/savings/withdrawal_flow/receipt_withdrawal_screen.dart';
import 'package:adepa_teachers/screens/savings/withdrawal_flow/success_withdrawal_screen.dart';
import 'package:adepa_teachers/screens/savings/withdrawal_flow/withdrawal_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget _receiptApp(Widget child) {
  return MaterialApp.router(
    routerConfig: GoRouter(
      routes: [GoRoute(path: '/', builder: (context, state) => child)],
    ),
  );
}

WithdrawalData _withdrawalData({bool isPending = false}) {
  return WithdrawalData(
    savingsId: 'savings-1',
    amount: 25,
    phoneNumber: '0241234567',
    method: 'Mobile Money',
    fromAccount: 'Member Savings',
    isPending: isPending,
  );
}

void main() {
  testWidgets('withdrawal status and receipt contain no unavailable wording', (
    tester,
  ) async {
    await tester.pumpWidget(
      _receiptApp(SuccessWithdrawalScreen(data: _withdrawalData())),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('unavailable', skipOffstage: false),
      findsNothing,
    );
    expect(find.text('GH₵ 0.00'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);

    await tester.pumpWidget(
      _receiptApp(ReceiptWithdrawalScreen(data: _withdrawalData())),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('unavailable', skipOffstage: false),
      findsNothing,
    );
    expect(find.text('GH₵ 0.00'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(2));
  });

  testWidgets('pending withdrawal labels the balance as pending', (
    tester,
  ) async {
    await tester.pumpWidget(
      _receiptApp(
        ReceiptWithdrawalScreen(data: _withdrawalData(isPending: true)),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('unavailable', skipOffstage: false),
      findsNothing,
    );
    expect(find.text('Pending confirmation'), findsOneWidget);
  });
}
