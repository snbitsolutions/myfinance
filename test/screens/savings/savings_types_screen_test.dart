import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:adepa_teachers/screens/savings/savings_types_screen.dart';

void main() {
  testWidgets('savings type catalog shows creation-unavailable guidance', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/types',
      routes: [
        GoRoute(
          path: '/types',
          builder: (context, state) => const SavingsTypesScreen(),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(
      find.text('New savings account opening is temporarily unavailable'),
      findsOneWidget,
    );
    expect(find.byType(ListTile), findsNothing);
    expect(find.byType(TextField), findsNothing);
  });
}
