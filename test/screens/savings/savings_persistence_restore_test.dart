import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:adepa_teachers/screens/savings/savings_model.dart';
import 'package:adepa_teachers/screens/savings/savings_screen.dart';

void main() {
  testWidgets('loads persisted user-created goals after screen recreation', (
    tester,
  ) async {
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

    GoRouter buildRouter() {
      return GoRouter(
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
    }

    await tester.pumpWidget(MaterialApp.router(routerConfig: buildRouter()));
    await tester.pumpAndSettle();

    expect(find.text('Persisted Goal 42'), findsOneWidget);

    // Simulate screen/app recreation while using the same persisted storage.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await tester.pumpWidget(MaterialApp.router(routerConfig: buildRouter()));
    await tester.pumpAndSettle();

    expect(find.text('Persisted Goal 42'), findsOneWidget);
  });
}
