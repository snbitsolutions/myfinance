import 'package:adepa_teachers/core/providers/app_providers.dart';
import 'package:adepa_teachers/core/services/api_service.dart';
import 'package:adepa_teachers/screens/shares/portfolio_statement_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _StatementService extends TransactionService {
  String? requestedProductId;

  @override
  Future<List<Map<String, dynamic>>> getProductStatement({
    required String productId,
  }) async {
    requestedProductId = productId;
    return [
      {
        'transaction_id': 'ATCCU-123',
        'description': 'Mobile App Deposit',
        'amount': 2.0,
        'type': 'Deposit',
        'date': '2026-10-27',
      },
      {
        'transaction_id': 'ATCCU-124',
        'description': 'Mobile App withdrawal',
        'amount': 1.0,
        'type': 'Withdrawal',
        'date': '2026-10-26',
      },
    ];
  }
}

void main() {
  testWidgets('loads statement for selected share product', (tester) async {
    final service = _StatementService();
    final router = GoRouter(
      initialLocation: '/shares/statement',
      routes: [
        GoRoute(
          path: '/shares/statement',
          builder: (context, state) =>
              const PortfolioStatementScreen(isShares: true),
        ),
        GoRoute(
          path: '/shares',
          builder: (context, state) => const Scaffold(body: Text('Shares')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharesProvider.overrideWith(
            (ref) async => [
              {
                'product_id': 'share-product-42',
                'product_name': 'Ordinary Shares',
              },
            ],
          ),
          transactionServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(service.requestedProductId, 'share-product-42');
    expect(find.text('Portfolio Statement'), findsOneWidget);
    expect(find.text('Mobile App Deposit'), findsOneWidget);
    expect(find.text('Deposit • 2026-10-27'), findsOneWidget);
    expect(find.text('GH₵ 2.00'), findsOneWidget);
    expect(find.text('Mobile App withdrawal'), findsOneWidget);
    expect(find.byIcon(Icons.call_received_rounded), findsOneWidget);
    expect(find.byIcon(Icons.call_made_rounded), findsOneWidget);

    final theme = Theme.of(
      tester.element(find.byType(PortfolioStatementScreen)),
    );
    expect(
      tester.widget<Text>(find.text('GH₵ 2.00')).style?.color,
      theme.colorScheme.primary,
    );
    expect(
      tester.widget<Text>(find.text('GH₵ 1.00')).style?.color,
      theme.colorScheme.error,
    );
  });
}
