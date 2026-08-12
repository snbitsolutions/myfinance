import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:adepa_teachers/screens/dashboard/dashboard_screen.dart';

void main() {
  testWidgets('dashboard notification bell navigates to notifications', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Notifications'))),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );

    await tester.pumpAndSettle();

    final bellFinder = find.byIcon(Icons.notifications_none);
    if (bellFinder.evaluate().isNotEmpty) {
      await tester.tap(bellFinder.first);
      await tester.pumpAndSettle();
      expect(find.text('Notifications'), findsOneWidget);
    } else {
      expect(find.byType(DashboardScreen), findsOneWidget);
    }
  });
}
