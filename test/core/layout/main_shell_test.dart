import 'package:adepa_teachers/core/layout/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('keeps bottom navigation visible across section detail pages', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/savings',
      routes: [
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/savings',
              builder: (context, state) =>
                  const Scaffold(body: Text('Savings section')),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Savings details')),
                ),
              ],
            ),
            GoRoute(
              path: '/loans',
              builder: (context, state) =>
                  const Scaffold(body: Text('Loans section')),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Loan details')),
                ),
              ],
            ),
            GoRoute(
              path: '/investments',
              builder: (context, state) =>
                  const Scaffold(body: Text('Investments section')),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Investment details')),
                ),
              ],
            ),
            GoRoute(
              path: '/home',
              builder: (context, state) =>
                  const Scaffold(body: Text('Home section')),
            ),
            GoRoute(
              path: '/pay',
              builder: (context, state) =>
                  const Scaffold(body: Text('Pay section')),
            ),
            GoRoute(
              path: '/activity',
              builder: (context, state) =>
                  const Scaffold(body: Text('Activity section')),
            ),
            GoRoute(
              path: '/more',
              builder: (context, state) =>
                  const Scaffold(body: Text('More section')),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    router.go('/savings/123');
    await tester.pumpAndSettle();
    expect(find.text('Savings details'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    router.go('/loans/456');
    await tester.pumpAndSettle();
    expect(find.text('Loan details'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    router.go('/investments/5293');
    await tester.pumpAndSettle();
    expect(find.text('Investment details'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
