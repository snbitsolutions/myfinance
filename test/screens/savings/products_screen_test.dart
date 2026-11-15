import 'package:adepa_teachers/core/providers/app_providers.dart';
import 'package:adepa_teachers/screens/savings/products_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('portfolio overview totals savings, shares, and investments', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith(
            (ref) async => {'name': 'Test Member', 'balance': 100},
          ),
          savingsProvider.overrideWith(
            (ref) async => [
              {'balance': 100},
            ],
          ),
          sharesProvider.overrideWith(
            (ref) async => [
              {'market_value': 50},
            ],
          ),
          investmentsApiProvider.overrideWith(
            (ref) async => [
              {'current_value': 150},
            ],
          ),
          loansProvider.overrideWith(
            (ref) async => [
              {'outstanding_balance': 25},
            ],
          ),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const ProductsScreen(),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('GH₵ 300.00'), findsOneWidget);
    expect(find.text('GH₵ 100.00'), findsWidgets);
  });
}
