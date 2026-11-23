import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:adepa_teachers/core/providers/app_providers.dart';
import 'package:adepa_teachers/screens/savings/create_savings_screen.dart';
import 'package:adepa_teachers/screens/savings/savings_detail_screen.dart';
import 'package:adepa_teachers/screens/savings/savings_model.dart';

Widget _detailApp(Savings savings) {
  final router = GoRouter(
    initialLocation: '/savings/${savings.id}',
    routes: [
      GoRoute(
        path: '/savings/:id',
        builder: (context, state) => SavingsDetailScreen(
          savingsId: state.pathParameters['id']!,
          savings: savings,
        ),
      ),
    ],
  );

  return MaterialApp.router(routerConfig: router);
}

void main() {
  testWidgets('savings creation is disabled without a backend endpoint', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/create',
      routes: [
        GoRoute(
          path: '/create',
          builder: (context, state) => const CreateSavingsScreen(),
        ),
        GoRoute(
          path: '/savings',
          builder: (context, state) =>
              const Scaffold(body: Text('Savings Accounts')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(
      find.text('New savings account opening is temporarily unavailable'),
      findsOneWidget,
    );
    expect(
      find.textContaining('does not currently expose an account-creation endpoint'),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Create Member Saving Goal'), findsNothing);

    await tester.tap(find.text('View Savings Accounts'));
    await tester.pumpAndSettle();
    expect(find.text('Savings Accounts'), findsOneWidget);
  });

  testWidgets('local savings goals show a warning before deposit action', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) async => <String, dynamic>{}),
          savingsProvider.overrideWith((ref) async => []),
        ],
        child: _detailApp(
          Savings(
            id: 'local-goal-1',
            title: 'Weekend Escape',
            balance: 0,
            target: 1500,
            type: SavingsType.memberSaving,
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
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) async => <String, dynamic>{}),
          savingsProvider.overrideWith((ref) async => []),
        ],
        child: _detailApp(
          Savings(
            id: 'local-goal-2',
            title: 'School Fees',
            balance: 1000,
            target: 2000,
            type: SavingsType.currentSaving,
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

  testWidgets('transfer action explains its backend limitation', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) async => <String, dynamic>{}),
          savingsProvider.overrideWith((ref) async => []),
        ],
        child: _detailApp(
          Savings(
            id: 'local-goal-3',
            title: 'Emergency Fund',
            balance: 500,
            target: 3000,
            type: SavingsType.fixedDeposit,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Transfer'));
    await tester.pump();

    expect(
      find.text(
        'Savings transfers are unavailable until recipient verification and transfer processing are connected to the backend.',
      ),
      findsOneWidget,
    );
  });
}
