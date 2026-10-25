import 'package:adepa_teachers/core/providers/app_providers.dart';
import 'package:adepa_teachers/screens/shares/share_detail_screen.dart';
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
    expect(find.text('Total Shares'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('shows holding count when provider omits share unit totals', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharesProvider.overrideWith(
            (ref) async => [
              {'id': 'share-4', 'name': 'Ordinary Shares', 'balance': 891.03},
              {'id': 'share-5', 'name': 'Project Shares', 'balance': 2262.73},
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

    expect(find.text('Share Holdings'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(
      find.text('Share unit totals are not included in the provider data.'),
      findsOneWidget,
    );
    expect(find.text('Total Shares'), findsNothing);
  });

  testWidgets('shows available holding details from supported API fields', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharesProvider.overrideWith(
            (ref) async => [
              {
                'share_id': 'share-7',
                'company_name': 'Example Cooperative',
                'quantity': '15',
                'unit_price': '12.50',
                'market_value': '187.50',
                'amount_invested': '150',
                'dividend': '0.75',
              },
            ],
          ),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/shares/share-7',
            routes: [
              GoRoute(
                path: '/shares/:id',
                builder: (context, state) =>
                    ShareDetailScreen(shareId: state.pathParameters['id']),
              ),
              GoRoute(
                path: '/shares/statement',
                builder: (context, state) =>
                    const Scaffold(body: Text('Statement placeholder')),
              ),
              GoRoute(
                path: '/shares/dividends',
                builder: (context, state) =>
                    const Scaffold(body: Text('Dividends placeholder')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Example Cooperative'), findsOneWidget);
    expect(find.text('GH₵ 187.50'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('GH₵ 12.50'), findsOneWidget);
    expect(find.text('GH₵ 150.00'), findsOneWidget);
    expect(find.text('GH₵ 0.75'), findsOneWidget);
    expect(find.text('Dividend history'), findsOneWidget);
  });

  testWidgets('share details back button returns to home when it can pop', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharesProvider.overrideWith((ref) async => const [])],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/home',
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () => context.push('/shares/share-7'),
                      child: const Text('Open share'),
                    ),
                  ),
                ),
              ),
              GoRoute(
                path: '/shares/:id',
                builder: (context, state) =>
                    ShareDetailScreen(shareId: state.pathParameters['id']),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open share'));
    await tester.pumpAndSettle();
    expect(find.text('Share Details'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Open share'), findsOneWidget);
    expect(find.text('Share Details'), findsNothing);
  });
}
