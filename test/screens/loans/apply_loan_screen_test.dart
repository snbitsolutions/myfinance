import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:adepa_teachers/screens/loans/apply_loan_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('submit valid loan application navigates to status', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/apply-loan',
      routes: [
        GoRoute(
          path: '/apply-loan',
          builder: (context, state) => const ApplyLoanScreen(),
        ),
        GoRoute(
          path: '/loan-status',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Loan Status Placeholder')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    final amountField = find.widgetWithText(
      TextField,
      'e.g., 1,000 (Ghana cedis)',
    );
    final purposeField = find.widgetWithText(
      TextField,
      'What is the loan for?',
    );

    expect(amountField, findsOneWidget);
    expect(purposeField, findsOneWidget);

    await tester.enterText(amountField, '2500');
    await tester.enterText(purposeField, 'Business expansion');
    await tester.pumpAndSettle();

    final submitButton = find.widgetWithText(
      ElevatedButton,
      'Submit Application',
    );
    expect(submitButton, findsOneWidget);
    final onPressed = tester.widget<ElevatedButton>(submitButton).onPressed;
    expect(onPressed, isNotNull);

    onPressed!.call();
    await tester.pumpAndSettle();

    expect(find.text('Loan Status Placeholder'), findsOneWidget);
  });
}
