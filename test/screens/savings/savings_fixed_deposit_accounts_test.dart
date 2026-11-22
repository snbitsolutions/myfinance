import 'package:adepa_teachers/core/providers/app_providers.dart';
import 'package:adepa_teachers/screens/savings/savings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows existing fixed deposits in the savings account list', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savingsProvider.overrideWith((ref) async => const []),
          fixedDepositsProvider.overrideWith(
            (ref) async => [
              {
                'id': '5293',
                'type': 'Fixed Deposit',
                'plan': '91 days',
                'principal': '16000.00',
                'interest_rate': '9.50',
                'maturity_date': '2027-01-16',
              },
            ],
          ),
        ],
        child: const MaterialApp(home: SavingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fixed Deposit Accounts'), findsOneWidget);
    expect(find.text('91 days'), findsOneWidget);
    expect(find.text('GH₵16000.00'), findsOneWidget);
    expect(find.text('Principal'), findsOneWidget);
    expect(find.text('9.50% interest'), findsOneWidget);
    expect(find.text('Matures 2027-01-16'), findsOneWidget);
  });
}
