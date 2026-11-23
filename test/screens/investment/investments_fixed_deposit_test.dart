import 'package:adepa_teachers/core/providers/app_providers.dart';
import 'package:adepa_teachers/screens/investment/investments_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('shows fixed deposits under investments', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const InvestmentsScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          investmentsApiProvider.overrideWith(
            (ref) async => [
              {
                'id': '5293',
                'type': 'Fixed Deposit',
                'plan': '91 days',
                'principal': 16000.0,
                'current_value': 16378.96,
                'total_interest': 378.96,
                'maturity_date': '2027-01-16',
                'icon': Icons.lock_clock_rounded,
              },
            ],
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fixed Deposits'), findsOneWidget);
    expect(find.text('91 days'), findsOneWidget);
  });
}
