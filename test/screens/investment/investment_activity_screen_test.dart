import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:adepa_teachers/screens/investment/investment_activity_screen.dart';
import 'package:adepa_teachers/screens/investment/investment_screen.dart';
import 'package:adepa_teachers/screens/investment/investment_state_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('activity screen shows empty state when no activity exists', (
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
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    expect(find.text('No investment activity yet'), findsOneWidget);
  });

  testWidgets('view activity button navigates to investment activity route', (
    tester,
  ) async {
    final container = ProviderContainer();
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

    final activityLabel = find.text('View Investment Activity');
    await tester.scrollUntilVisible(
      activityLabel,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(activityLabel, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Investment Activity'), findsOneWidget);
    expect(find.text('No investment activity yet'), findsOneWidget);
  });

  testWidgets('activity timeline shows started investment entries', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container
        .read(investmentProvider.notifier)
        .recordStart(planName: 'Starter Plan', amount: 100);

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

    expect(find.text('Starter Plan'), findsOneWidget);
    expect(find.textContaining('Ref: INV-'), findsOneWidget);
    expect(find.text('GH₵100.00'), findsWidgets);
  });
}
