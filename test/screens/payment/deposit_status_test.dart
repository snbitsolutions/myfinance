import 'package:adepa_teachers/screens/payment/payment_receipt_screen.dart';
import 'package:adepa_teachers/screens/payment/payment_success_screen.dart';
import 'package:adepa_teachers/core/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget _testApp(Widget child) {
  return ProviderScope(
    child: MaterialApp.router(
      routerConfig: GoRouter(
        routes: [GoRoute(path: '/', builder: (context, state) => child)],
      ),
    ),
  );
}

void main() {
  testWidgets('deposit receipt copies the transaction details', (tester) async {
    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText = (call.arguments as Map)['text'] as String?;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      _testApp(
        const PaymentReceiptScreen(
          amount: 25,
          reference: 'deposit-ref-123',
          account: 'Member Savings',
          paymentMethod: 'Telecel Cash',
          isPending: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Copy receipt'));
    await tester.tap(find.text('Copy receipt'));
    await tester.pumpAndSettle();

    expect(copiedText, contains('ADEPA - Deposit Receipt'));
    expect(copiedText, contains('Pending'));
    expect(copiedText, contains('deposit-ref-123'));
    expect(find.text('Receipt copied'), findsOneWidget);
  });

  testWidgets('completed deposit status matches its receipt wording', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        const PaymentSuccessScreen(
          amount: 25,
          title: 'Provider reported completion',
          message: 'The provider reported that the deposit request completed.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Deposit Status'), findsOneWidget);
    expect(find.text('Provider reported completion'), findsOneWidget);
    expect(find.text('Amount Deposited'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    final appBarTheme = Theme.of(tester.element(find.byType(AppBar)));
    expect(appBar.backgroundColor, appBarTheme.colorScheme.surface);
    expect(appBar.foregroundColor, appBarTheme.colorScheme.primary);

    await tester.pumpWidget(_testApp(const PaymentReceiptScreen(amount: 25)));
    await tester.pumpAndSettle();

    expect(find.text('Provider reported completion'), findsOneWidget);
    expect(find.text('Amount Deposited'), findsOneWidget);
  });

  testWidgets('pending deposit status matches its receipt wording', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        const PaymentSuccessScreen(
          amount: 25,
          title: 'Deposit Pending',
          message: 'Your deposit request is awaiting provider confirmation.',
          primaryActionLabel: 'Back to Savings',
          isPending: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Deposit Status'), findsOneWidget);
    expect(find.text('Deposit Pending'), findsOneWidget);
    expect(find.text('Amount Requested'), findsOneWidget);
    expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
    expect(find.text('Check transaction status'), findsOneWidget);
    expect(find.text('Back to Savings'), findsOneWidget);

    await tester.pumpWidget(
      _testApp(const PaymentReceiptScreen(amount: 25, isPending: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Amount Requested'), findsOneWidget);
  });

  testWidgets(
    'pending deposit changes to successful when history confirms it',
    (tester) async {
      const reference = 'deposit-reference-123';
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transactionsProvider.overrideWith(
              (ref) async => [
                {'transaction_id': reference, 'status': 'successful'},
              ],
            ),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const PaymentSuccessScreen(
                    amount: 25,
                    reference: reference,
                    title: 'Deposit Pending',
                    isPending: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Deposit Successful'), findsOneWidget);
      expect(find.text('Amount Deposited'), findsOneWidget);
      expect(find.text('Check transaction status'), findsNothing);
    },
  );

  testWidgets('pending deposit changes to failed when history reports failure', (
    tester,
  ) async {
    const reference = 'deposit-reference-failed';
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsProvider.overrideWith(
            (ref) async => [
              {'transaction_id': reference, 'status': 'failed'},
            ],
          ),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const PaymentSuccessScreen(
                  amount: 25,
                  reference: reference,
                  title: 'Deposit Pending',
                  isPending: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Deposit Failed'), findsOneWidget);
    expect(
      find.text(
        'The provider reported that your deposit failed. The amount was not deposited.',
      ),
      findsOneWidget,
    );
    expect(find.text('Amount Requested'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.text('Check transaction status'), findsNothing);
  });
}
