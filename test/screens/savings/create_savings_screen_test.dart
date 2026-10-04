import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:adepa_teachers/screens/savings/create_savings_screen.dart';
import 'package:adepa_teachers/screens/savings/savings_detail_screen.dart';
import 'package:adepa_teachers/screens/savings/savings_model.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('create flow enables submit after valid input', (tester) async {
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
    expect(tester.widget<ElevatedButton>(createButton).onPressed, isNotNull);

    expect(tester.widget<ElevatedButton>(createButton).onPressed, isNotNull);
  });

  testWidgets('invalid targets are blocked before submission', (tester) async {
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

    await tester.enterText(goalField, 'Emergency Fund');
    await tester.enterText(targetField, 'abc');
    await tester.pumpAndSettle();

    expect(find.text('Please enter a valid amount'), findsOneWidget);

    final button = find.widgetWithText(
      ElevatedButton,
      'Create Member Saving Goal',
    );
    expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
  });

  testWidgets(
    'fixed deposit submit is disabled until maturity date is selected',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/create',
        routes: [
          GoRoute(
            path: '/create',
            builder: (context, state) => const CreateSavingsScreen(
              initialType: SavingsType.fixedDeposit,
            ),
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

      await tester.enterText(goalField, 'School Fees');
      await tester.enterText(targetField, '5000');
      await tester.pumpAndSettle();

      final button = find.widgetWithText(
        ElevatedButton,
        'Create Fixed Deposit Goal',
      );
      expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
    },
  );

  testWidgets('local savings goals show a warning before deposit action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SavingsDetailScreen(
            savingsId: 'local-goal-1',
            savings: Savings(
              id: 'local-goal-1',
              title: 'Weekend Escape',
              balance: 0,
              target: 1500,
              type: SavingsType.memberSaving,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Deposit'));
    await tester.pump();

    expect(
      find.text(
        'This local goal is not a backend account. Deposit and withdrawal require a customer savings account.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('local savings goals show a warning before withdraw action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SavingsDetailScreen(
            savingsId: 'local-goal-2',
            savings: Savings(
              id: 'local-goal-2',
              title: 'School Fees',
              balance: 1000,
              target: 2000,
              type: SavingsType.currentSaving,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Withdraw'));
    await tester.pump();

    expect(
      find.text(
        'This local goal is not a backend account. Deposit and withdrawal require a customer savings account.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('local savings goals show a warning before transfer action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SavingsDetailScreen(
            savingsId: 'local-goal-3',
            savings: Savings(
              id: 'local-goal-3',
              title: 'Emergency Fund',
              balance: 500,
              target: 3000,
              type: SavingsType.fixedDeposit,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Transfer'));
    await tester.pump();

    expect(
      find.text(
        'This local goal is not a backend account. Deposit and withdrawal require a customer savings account.',
      ),
      findsOneWidget,
    );
  });
}
