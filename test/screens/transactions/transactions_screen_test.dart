import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:adepa_teachers/core/providers/app_providers.dart';
import 'package:adepa_teachers/screens/transactions/transactions_screen.dart';

void main() {
  testWidgets('transactions screen is overflow-safe on small screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 560);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = GoRouter(
      initialLocation: '/transactions',
      routes: [
        GoRoute(
          path: '/transactions',
          builder: (context, state) => const TransactionsScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsProvider.overrideWith(
            (ref) async => <Map<String, dynamic>>[],
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Transactions'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Drag if any scrollable is present (empty state may not have ListView)
    final scrollables = find.byType(Scrollable);
    if (tester.widgetList(scrollables).isNotEmpty) {
      await tester.drag(scrollables.first, const Offset(0, -300));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });
}
