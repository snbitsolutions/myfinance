import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:adepa_teachers/screens/savings/create_savings_screen.dart';
import 'package:adepa_teachers/screens/savings/savings_model.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('create flow enables submit and navigates to success', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/create',
      routes: [
        GoRoute(
          path: '/create',
          builder: (context, state) =>
              const CreateSavingsScreen(initialType: SavingsType.memberSaving),
        ),
        GoRoute(
          name: 'savings-success',
          path: '/success',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Savings Success Placeholder')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final goalField = find.widgetWithText(TextField, 'e.g., Emergency Fund');
    final targetField = find.widgetWithText(TextField, 'e.g., 2000');
    expect(goalField, findsOneWidget);
    expect(targetField, findsOneWidget);

    await tester.enterText(goalField, 'Laptop Upgrade Fund');
    await tester.enterText(targetField, '3000');
    await tester.pumpAndSettle();

    final createButton = find.widgetWithText(
      ElevatedButton,
      'Create Member Saving Goal',
    );
    expect(createButton, findsOneWidget);
    final onPressed = tester.widget<ElevatedButton>(createButton).onPressed;
    expect(onPressed, isNotNull);

    onPressed!.call();
    await tester.pumpAndSettle();

    expect(find.text('Savings Success Placeholder'), findsOneWidget);
  });
}
