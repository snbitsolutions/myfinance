import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:adepa_teachers/screens/investment/investment_screen.dart';
import 'package:adepa_teachers/core/providers/app_providers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'investment screen does not offer unsupported investment start actions',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/investment',
        routes: [
          GoRoute(
            path: '/investment',
            builder: (context, state) => const InvestmentScreen(),
          ),
          GoRoute(
            path: '/investment/activity',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Activity Placeholder')),
            ),
          ),
          GoRoute(
            path: '/payment',
            builder: (context, state) {
              final source = state.uri.queryParameters['source'] ?? '';
              return Scaffold(
                body: Center(child: Text('Payment Source: $source')),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            investmentsApiProvider.overrideWith((ref) async => []),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Investments'), findsOneWidget);
      expect(find.text('Investment actions will be available when the investment service is connected.'), findsOneWidget);
      expect(find.text('Starter Plan'), findsNothing);
    },
  );
}
