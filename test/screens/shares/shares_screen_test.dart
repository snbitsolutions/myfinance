import 'package:adepa_teachers/core/providers/app_providers.dart';
import 'package:adepa_teachers/screens/shares/shares_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('renders member shares when market data is not returned', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharesProvider.overrideWith(
            (ref) async => [
              {
                'id': 'share-4',
                'name': 'Ordinary Shares',
                'shares_owned': '12',
              },
            ],
          ),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/shares',
            routes: [
              GoRoute(
                path: '/shares',
                builder: (context, state) => const SharesScreen(),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ordinary Shares'), findsOneWidget);
    expect(find.text('Value unavailable'), findsOneWidget);
    expect(find.textContaining('12 shares'), findsOneWidget);
  });
}
