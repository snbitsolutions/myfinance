import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:adepa_teachers/core/providers/app_providers.dart';
import 'package:adepa_teachers/screens/savings/savings_model.dart';
import 'package:adepa_teachers/screens/savings/savings_screen.dart';
import 'package:adepa_teachers/screens/savings/savings_storage.dart';

void main() {
  testWidgets(
    'keeps savings accounts visible without showing saved goal cards',
    (tester) async {
      final persistedGoal = Savings(
        id: 'persisted-goal-42',
        title: 'Persisted Goal 42',
        balance: 125,
        target: 1000,
        type: SavingsType.currentSaving,
        createdAt: DateTime(2026, 4, 1),
      );

      SharedPreferences.setMockInitialValues({
        'user_created_savings_goals_v1': [jsonEncode(persistedGoal.toJson())],
      });

      GoRouter buildRouter() => GoRouter(
        initialLocation: '/savings',
        routes: [
          GoRoute(
            path: '/savings',
            builder: (context, state) => const SavingsScreen(),
          ),
          GoRoute(
            path: '/savings/:id',
            builder: (context, state) => const Scaffold(body: Text('Detail')),
          ),
          GoRoute(
            path: '/savings/types',
            builder: (context, state) => const Scaffold(body: Text('Types')),
          ),
          GoRoute(
            path: '/savings/create',
            builder: (context, state) => const Scaffold(body: Text('Create')),
          ),
        ],
      );

      Widget buildApp() => ProviderScope(
        overrides: [
          savingsProvider.overrideWith(
            (ref) async => [
              {
                'savings_id': 'account-1',
                'name': 'Member Savings',
                'balance': 125,
                'type': 'member',
              },
              {
                'savings_id': 'account-2',
                'name': 'Current Savings',
                'balance': 450,
                'type': 'current',
              },
            ],
          ),
        ],
        child: MaterialApp.router(routerConfig: buildRouter()),
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Your Savings'), findsNothing);
      expect(find.text('My Savings Accounts'), findsOneWidget);
      expect(find.text('Member Savings'), findsOneWidget);
      expect(find.text('Current Savings'), findsOneWidget);
      expect(find.text('Savings Goals'), findsNothing);
      expect(find.text('Persisted Goal 42'), findsNothing);
      expect(find.text('Account number unavailable'), findsNothing);
      expect(find.text('Open New Savings'), findsNothing);
      expect(find.text('New Goal'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Persisted Goal 42'), findsNothing);
      expect(
        (await SavingsStorage.loadGoals()).single.title,
        'Persisted Goal 42',
      );
    },
  );
}
