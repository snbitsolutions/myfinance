import 'package:adepa_teachers/core/constants/app_constants.dart';
import 'package:adepa_teachers/core/services/device_identity_service.dart';
import 'package:adepa_teachers/core/services/secure_auth_storage.dart';
import 'package:adepa_teachers/core/providers/app_providers.dart';
import 'package:adepa_teachers/main.dart';
import 'package:adepa_teachers/router/app_router.dart';
import 'package:adepa_teachers/screens/payment/payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final secureStore = <String, dynamic>{};

  void installSecureStorageMock() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          switch (methodCall.method) {
            case 'write':
              final key = methodCall.arguments['key'] as String;
              final value = methodCall.arguments['value'] as String?;
              secureStore[key] = value;
              return null;
            case 'read':
              final key = methodCall.arguments['key'] as String;
              return secureStore[key];
            case 'delete':
              final key = methodCall.arguments['key'] as String;
              secureStore.remove(key);
              return null;
            case 'deleteAll':
              secureStore.clear();
              return null;
            case 'readAll':
              return Map<String, dynamic>.from(secureStore);
            case 'containsKey':
              final key = methodCall.arguments['key'] as String;
              return secureStore.containsKey(key);
            default:
              return null;
          }
        });
  }

  installSecureStorageMock();

  setUp(() async {
    secureStore.clear();
    SharedPreferences.setMockInitialValues({
      AppConstants.sharedPrefKeyOnboarding: true,
      AppConstants.sharedPrefKeyUserEmail: 'test@example.com',
      AppConstants.sharedPrefKeyUserId: '123456',
    });
    installSecureStorageMock();
    final fingerprint = await DeviceIdentityService()
        .getInstallationFingerprint();
    await SecureAuthStorage.instance.initialize();
    await SecureAuthStorage.instance.writeAuthToken('secure-token');
    await SecureAuthStorage.instance.writeSessionDeviceFingerprint(fingerprint);
    AppRouter.resetSessionCache();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets(
    'deposit flow opens payment screen without throwing layout errors',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            savingsProvider.overrideWith(
              (ref) async => [
                {'savings_id': '59656', 'name': 'Test Savings'},
              ],
            ),
            userProfileProvider.overrideWith(
              (ref) async => {'name': 'Test Member', 'phone': '0241234567'},
            ),
          ],
          child: const AdepaTeachersApp(),
        ),
      );
      await tester.pumpAndSettle();

      AppRouter.router.go(
        '/payment?sourceLabel=Deposit&returnRoute=/savings/custom-savings',
      );
      await tester.pumpAndSettle();

      expect(find.byType(PaymentScreen), findsOneWidget);
      expect(find.text('Deposit'), findsWidgets);
      expect(find.text('Secure Checkout'), findsOneWidget);
      expect(find.text('Test Savings'), findsOneWidget);
    },
  );

  testWidgets('receive money starts a savings MoMo deposit request', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savingsProvider.overrideWith(
            (ref) async => [
              {'savings_id': '59656', 'name': 'Test Savings'},
            ],
          ),
          userProfileProvider.overrideWith(
            (ref) async => {'name': 'Test Member', 'phone': '0241234567'},
          ),
        ],
        child: const AdepaTeachersApp(),
      ),
    );
    await tester.pumpAndSettle();

    AppRouter.router.go('/payments-hub');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Receive Money').first);
    await tester.pumpAndSettle();

    expect(find.byType(PaymentScreen), findsOneWidget);
    expect(find.text('Amount to Receive'), findsWidgets);
    expect(find.text('Payer’s MoMo Number'), findsOneWidget);
    expect(find.text('Test Savings'), findsOneWidget);
    expect(find.text('Request MoMo Deposit'), findsOneWidget);
  });

  testWidgets('data purchase uses the shared mobile purchase form', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith(
            (ref) async => {'name': 'Test Member', 'phone': '0241234567'},
          ),
        ],
        child: const AdepaTeachersApp(),
      ),
    );
    await tester.pumpAndSettle();

    AppRouter.router.go('/payment?type=data');
    await tester.pumpAndSettle();

    expect(find.text('Data Purchase'), findsOneWidget);
    expect(find.text('Network'), findsOneWidget);
    expect(find.text('Phone number'), findsOneWidget);
    expect(find.text('Enter an amount'), findsNothing);
  });

  testWidgets('deposit flow still works when sourceLabel is lowercase', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const PaymentScreen(
            sourceLabel: 'deposit',
            returnRoute: '/savings/custom-savings',
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PaymentScreen), findsOneWidget);
    expect(find.text('Deposit now'), findsOneWidget);
    expect(find.text('Deposit Amount'), findsOneWidget);
  });
}
