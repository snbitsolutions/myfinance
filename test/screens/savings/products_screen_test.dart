import 'package:adepa_teachers/core/providers/app_providers.dart';
import 'package:adepa_teachers/screens/savings/products_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('keeps all product cards in a single row on narrow screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith(
            (ref) async => {'name': 'Test Member'},
          ),
          savingsProvider.overrideWith((ref) async => const []),
          sharesProvider.overrideWith((ref) async => const []),
          investmentsApiProvider.overrideWith((ref) async => const []),
          loansProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: const ProductsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final titleText in ['Savings', 'Shares', 'Investments', 'Loans']) {
      final titleFinder = find.text(titleText);
      final title = tester.widget<Text>(titleFinder);
      expect(title.maxLines, 1);
      expect(title.softWrap, isFalse);

      final card = find
          .ancestor(of: titleFinder, matching: find.byType(InkWell))
          .first;
      final subtitleFinder = find.descendant(
        of: card,
        matching: find.text(
          titleText == 'Savings'
              ? 'All your savings accounts'
              : titleText == 'Shares'
              ? 'Your equity portfolio'
              : titleText == 'Investments'
              ? 'Fixed deposits and more'
              : 'Active loans and repayments',
        ),
      );
      final subtitle = tester.widget<Text>(subtitleFinder);
      expect(subtitle.maxLines, 1);
      expect(subtitle.softWrap, isFalse);

      final amount = find.descendant(of: card, matching: find.text('GH₵ 0.00'));
      expect(amount, findsOneWidget);
      expect(
        find
            .ancestor(of: titleFinder, matching: find.byType(Row))
            .first
            .evaluate()
            .single,
        same(
          find
              .ancestor(of: amount, matching: find.byType(Row))
              .first
              .evaluate()
              .single,
        ),
      );
    }
    expect(tester.takeException(), isNull);
  });

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
