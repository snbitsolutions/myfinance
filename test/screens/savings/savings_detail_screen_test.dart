import 'package:adepa_teachers/core/providers/app_providers.dart';
import 'package:adepa_teachers/screens/savings/savings_detail_screen.dart';
import 'package:adepa_teachers/screens/savings/savings_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('shows goal creation date and omits next interest payout', (
    tester,
  ) async {
    final goal = Savings(
      id: 'goal-1',
      title: 'Holiday fund',
      balance: 0,
      target: 1000,
      type: SavingsType.fixedDeposit,
      createdAt: DateTime(2026, 1, 7),
    );

    final router = GoRouter(
      initialLocation: '/savings/${goal.id}',
      routes: [
        GoRoute(
          path: '/savings/:id',
          builder: (context, state) => SavingsDetailScreen(
            savingsId: state.pathParameters['id']!,
            savings: goal,
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savingsProvider.overrideWith((ref) async => const []),
          userProfileProvider.overrideWith((ref) async => <String, dynamic>{}),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Account Details'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('07/01/2026'), findsOneWidget);
    expect(find.text('Local goal'), findsOneWidget);
    expect(find.text('Next Interest Payout'), findsNothing);
  });
}
