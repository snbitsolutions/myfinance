import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:adepa_teachers/screens/savings/savings_types_screen.dart';

void main() {
  testWidgets('type picker bottom sheet is scroll-safe on small screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = GoRouter(
      initialLocation: '/types',
      routes: [
        GoRoute(
          path: '/types',
          builder: (context, state) => const SavingsTypesScreen(),
        ),
        GoRoute(
          path: '/savings/create',
          builder: (context, state) => const Scaffold(body: Text('Create')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Create New Savings'));
    await tester.pumpAndSettle();

    expect(
      find.text('Pick the type you want to create before continuing.'),
      findsOneWidget,
    );
    expect(find.byType(ListTile), findsWidgets);

    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -250),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
