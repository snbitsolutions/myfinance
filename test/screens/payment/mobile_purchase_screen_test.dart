import 'package:adepa_teachers/screens/payment/mobile_purchase_screen.dart';
import 'package:adepa_teachers/core/constants/app_constants.dart';
import 'package:adepa_teachers/core/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final secureStore = <String, String>{};

  setUp(() {
    secureStore.clear();
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
          final arguments =
              (call.arguments as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{};
          final key = arguments['key'] as String?;
          switch (call.method) {
            case 'read':
              return key == null ? null : secureStore[key];
            case 'write':
              if (key != null) {
                secureStore[key] = arguments['value']?.toString() ?? '';
              }
              return null;
            case 'delete':
              if (key != null) secureStore.remove(key);
              return null;
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  Future<void> openReviewStep(
    WidgetTester tester, {
    double? availableBalance,
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
    await tester.pumpWidget(
      availableBalance == null
          ? app
          : ProviderScope(
              overrides: [
                userProfileProvider.overrideWith(
                  (ref) async => {
                    'name': 'Test Member',
                    'balance': availableBalance,
                  },
                ),
              ],
              child: app,
            ),
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

  testWidgets('authorizes airtime with the existing mobile banking PIN', (
    tester,
  ) async {
    await openReviewStep(tester);

    expect(find.text('Mobile banking PIN'), findsOneWidget);
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

  testWidgets('rejects a wrong PIN before submitting airtime', (tester) async {
    secureStore[AppConstants.secureStorageKeyUserPin] = '1234';
    await openReviewStep(tester, availableBalance: 100);

    await tester.enterText(find.byType(TextField).last, '9999');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buy Airtime'));
    await tester.pumpAndSettle();

    expect(
      find.text('Incorrect PIN. Enter your mobile banking PIN.'),
      findsOneWidget,
    );
  });
}
