import 'package:adepa_teachers/screens/payment/payroll_deduction_adjustment_screen.dart';
import 'package:adepa_teachers/screens/payment/payments_hub_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget _app() {
  return MaterialApp.router(
    routerConfig: GoRouter(
      initialLocation: '/payroll-deduction-adjustment',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) =>
              const Scaffold(body: Text('Home placeholder')),
        ),
        GoRoute(
          path: '/payroll-deduction-adjustment',
          builder: (context, state) => const PayrollDeductionAdjustmentScreen(),
        ),
      ],
    ),
  );
}

Widget _hubApp() {
  return MaterialApp.router(
    routerConfig: GoRouter(
      initialLocation: '/payments-hub',
      routes: [
        GoRoute(
          path: '/payments-hub',
          builder: (context, state) => const PaymentsHubScreen(),
        ),
        GoRoute(
          path: '/payroll-deduction-adjustment',
          builder: (context, state) => const PayrollDeductionAdjustmentScreen(),
        ),
        GoRoute(
          path: '/repayment',
          builder: (context, state) =>
              const Scaffold(body: Text('Loan repayment destination')),
        ),
      ],
    ),
  );
}

void main() {
  testWidgets('Loan Payment in Payments Hub opens the loan repayment flow', (
    tester,
  ) async {
    await tester.pumpWidget(_hubApp());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Loan Payment'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Loan Payment'));
    await tester.pumpAndSettle();

    expect(find.text('Loan repayment destination'), findsOneWidget);
  });

  testWidgets('Payments Hub exposes the named payroll adjustment preview', (
    tester,
  ) async {
    await tester.pumpWidget(_hubApp());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Payroll Deduction'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    final donationsPosition = tester.getCenter(find.text('Donations'));
    final payrollPosition = tester.getCenter(find.text('Payroll Deduction'));
    expect((donationsPosition.dy - payrollPosition.dy).abs(), lessThan(1));
    expect(donationsPosition.dx, lessThan(payrollPosition.dx));

    await tester.tap(find.text('Payroll Deduction'));
    await tester.pumpAndSettle();

    expect(
      find.text('Preview only — not an authorized payroll service'),
      findsOneWidget,
    );
  });

  testWidgets('preview clearly discloses unavailable backend features', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(
      find.text('Preview only — not an authorized payroll service'),
      findsOneWidget,
    );
    expect(find.text('My requests'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Workflow status labels'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Workflow status labels'), findsOneWidget);
  });

  testWidgets('my requests does not display fabricated employee records', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('My requests'));
    await tester.pumpAndSettle();

    expect(find.text('No live requests available'), findsOneWidget);
    expect(
      find.textContaining('does not load, save, or display employee'),
      findsOneWidget,
    );
  });

  testWidgets('adjustment form requires consent and effective month', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start an adjustment request'));
    await tester.pumpAndSettle();

    expect(find.text('Current amount'), findsOneWidget);
    expect(
      find.textContaining('no verified payroll data connected'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Supporting document'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Supporting document'), findsOneWidget);
    expect(
      find.textContaining('Document upload is not available'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Review request'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Review request'), findsOneWidget);

    await tester.tap(find.text('Review request'));
    await tester.pumpAndSettle();

    expect(
      find.text('Choose an effective month and provide consent to continue.'),
      findsOneWidget,
    );
    expect(find.text('Review your request'), findsNothing);
  });

  testWidgets('discontinue action does not require a requested amount', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start an adjustment request'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Increase deduction'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discontinue deduction').last);
    await tester.pumpAndSettle();

    expect(find.text('Requested new amount'), findsNothing);
    expect(find.text('Requested reduced amount'), findsNothing);
  });

  testWidgets('confirming the preview does not create a request', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start an adjustment request'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('payroll-deduction-code')),
      'Union dues',
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('payroll-requested-amount')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const ValueKey('payroll-requested-amount')),
      '75.00',
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('payroll-request-reason')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const ValueKey('payroll-request-reason')),
      'Update my deduction',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Choose effective month'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Choose effective month'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Review request'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Review request'));
    await tester.pumpAndSettle();
    expect(find.text('Review your request'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Confirm preview'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Confirm preview'));
    await tester.pumpAndSettle();

    expect(find.text('Preview complete'), findsOneWidget);
    expect(
      find.textContaining('No request was created, saved, or sent'),
      findsOneWidget,
    );
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My requests'));
    await tester.pumpAndSettle();

    expect(find.text('No live requests available'), findsOneWidget);
  });
}
