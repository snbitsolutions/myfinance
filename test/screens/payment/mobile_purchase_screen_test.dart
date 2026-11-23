import 'package:adepa_teachers/screens/payment/mobile_purchase_screen.dart';
import 'package:adepa_teachers/core/exceptions/app_exceptions.dart';
import 'package:adepa_teachers/core/providers/app_providers.dart';
import 'package:adepa_teachers/core/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> openReviewStep(
    WidgetTester tester, {
    double? availableBalance,
    PaymentService? paymentService,
  }) async {
    final router = GoRouter(
      initialLocation: '/airtime',
      routes: [
        GoRoute(
          path: '/airtime',
          builder: (context, state) => const MobilePurchaseScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) =>
              const Scaffold(body: Text('Login screen')),
        ),
      ],
    );

    final app = MaterialApp.router(routerConfig: router);
    final overrides = <Override>[
      if (availableBalance != null)
        userProfileProvider.overrideWith(
          (ref) async => {'name': 'Test Member', 'balance': availableBalance},
        ),
      if (paymentService != null)
        paymentServiceProvider.overrideWith((ref) => paymentService),
    ];
    await tester.pumpWidget(
      overrides.isEmpty ? app : ProviderScope(overrides: overrides, child: app),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '0241952608');
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      '0241952608',
    );
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Continue'),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('How much Airtime do you want?'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '5');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Fee'), findsNothing);
    expect(find.textContaining('unquoted fee'), findsNothing);
  }

  testWidgets('accepts a 4-digit transaction PIN for purchase', (tester) async {
    await openReviewStep(tester);

    expect(find.text('Transaction PIN'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).last).obscureText,
      isTrue,
    );
    final buyButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Buy Airtime'),
    );
    expect(buyButton.onPressed, isNull);

    await tester.enterText(find.byType(TextField).last, '123');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Buy Airtime'),
          )
          .onPressed,
      isNull,
    );

    await tester.enterText(find.byType(TextField).last, '1234');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Buy Airtime'),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('stops an airtime purchase when the available balance is zero', (
    tester,
  ) async {
    await openReviewStep(tester, availableBalance: 0);
    await tester.enterText(find.byType(TextField).last, '1234');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buy Airtime'));
    await tester.pumpAndSettle();

    expect(
      find.text('Insufficient balance. Your available balance is GH₵ 0.00.'),
      findsOneWidget,
    );
    expect(find.text('Airtime Purchase Pending'), findsNothing);
  });

  testWidgets(
    'submits the entered transaction PIN for purchase authorization',
    (tester) async {
      final paymentService = _RejectingPaymentService();
      await openReviewStep(
        tester,
        availableBalance: 100,
        paymentService: paymentService,
      );

      await tester.enterText(find.byType(TextField).last, '9999');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buy Airtime'));
      await tester.pumpAndSettle();

      expect(paymentService.submittedPin, '9999');
      expect(find.text('Incorrect transaction PIN.'), findsOneWidget);
    },
  );
}

class _RejectingPaymentService extends PaymentService {
  String? submittedPin;

  @override
  Future<Map<String, dynamic>> buyAirtime({
    required String phoneNumber,
    required String channel,
    required double amount,
    required String username,
    required String productId,
    required String pin,
    String email = '',
  }) async {
    submittedPin = pin;
    throw AuthException(message: 'Incorrect transaction PIN.');
  }
}
