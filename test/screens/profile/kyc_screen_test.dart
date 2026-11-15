import 'package:adepa_teachers/screens/profile/kyc_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('date of birth is selected using the calendar picker', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/kyc',
      routes: [
        GoRoute(path: '/kyc', builder: (context, state) => const KycScreen()),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );

    final dateField = find.byKey(const ValueKey('kyc-date-of-birth'));

    await tester.tap(dateField);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Switch to input'));
    await tester.pumpAndSettle();

    final datePicker = find.byType(DatePickerDialog);
    final dateInput = find.descendant(
      of: datePicker,
      matching: find.byType(TextField),
    );
    await tester.enterText(dateInput, '10/07/1989');
    await tester.tap(
      find.descendant(of: datePicker, matching: find.text('OK')),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextFormField>(dateField).controller!.text,
      '1989-10-07',
    );
  });
}
