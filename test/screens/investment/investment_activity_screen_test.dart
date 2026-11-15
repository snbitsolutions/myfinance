import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:adepa_teachers/screens/investment/investment_activity_screen.dart';
import 'package:adepa_teachers/screens/investment/investment_screen.dart';
import 'package:adepa_teachers/core/providers/app_providers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('legacy activity route does not fabricate account activity', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/investment/activity',
      routes: [
        GoRoute(
          path: '/investment/activity',
          builder: (context, state) => const InvestmentActivityScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [investmentsApiProvider.overrideWith((ref) async => [])],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Investments'), findsOneWidget);
    expect(find.text('You do not have any investment accounts yet.'), findsOneWidget);
  });

  testWidgets('view activity button navigates to investment activity route', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [investmentsApiProvider.overrideWith((ref) async => [])],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/investment',
      routes: [
        GoRoute(
          path: '/investment',
          builder: (context, state) => const InvestmentScreen(),
        ),
        GoRoute(
          path: '/investment/activity',
          builder: (context, state) => const InvestmentActivityScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Investments'), findsOneWidget);
    expect(find.text('You do not have any investment accounts yet.'), findsOneWidget);
  });

  testWidgets('activity route does not show locally fabricated investments', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [investmentsApiProvider.overrideWith((ref) async => [])],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/investment/activity',
      routes: [
        GoRoute(
          path: '/investment/activity',
          builder: (context, state) => const InvestmentActivityScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Starter Plan'), findsNothing);
    expect(find.textContaining('Ref: INV-'), findsNothing);
    expect(find.text('You do not have any investment accounts yet.'), findsOneWidget);
  });
}
