import 'package:adepa_teachers/screens/savings/withdrawal_flow/authenticate_withdrawal_screen.dart';
import 'package:adepa_teachers/screens/savings/withdrawal_flow/review_withdrawal_screen.dart';
import 'package:adepa_teachers/screens/savings/withdrawal_flow/withdrawal_model.dart';
import 'package:adepa_teachers/screens/savings/withdrawal_flow/withdrawal_screen.dart';
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
  final secureValues = <String, String>{};
  var failPinRead = false;

  setUp(() async {
    secureValues.clear();
    failPinRead = false;
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
          final key = call.arguments is Map
              ? (call.arguments as Map)['key'] as String?
              : null;
          switch (call.method) {
            case 'read':
              if (failPinRead && key == AppConstants.secureStorageKeyUserPin) {
                throw PlatformException(code: 'secure_storage_unavailable');
              }
              return key == null ? null : secureValues[key];
            case 'write':
              if (key != null) {
                secureValues[key] = (call.arguments as Map)['value'] as String;
              }
              return null;
            case 'delete':
              if (key != null) secureValues.remove(key);
              return null;
            case 'deleteAll':
              secureValues.clear();
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

  testWidgets('withdraw back button returns to the savings account safely', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/savings/savings-1/withdraw',
      routes: [
        GoRoute(
          path: '/savings/:id',
          builder: (context, state) =>
              Text('Savings ${state.pathParameters['id']}'),
        ),
        GoRoute(
          path: '/savings/:id/withdraw',
          builder: (context, state) =>
              WithdrawalScreen(savingsId: state.pathParameters['id']),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          withdrawalAccountProvider('savings-1').overrideWith(
            (ref) async => {
              'savings_id': 'savings-1',
              'name': 'Member Savings',
              'balance': 500.0,
            },
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Withdraw from savings'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Savings savings-1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing withdrawal balance is shown as GH₵0.00', (tester) async {
    final router = GoRouter(
      initialLocation: '/savings/savings-1/withdraw',
      routes: [
        GoRoute(
          path: '/savings/:id/withdraw',
          builder: (context, state) =>
              WithdrawalScreen(savingsId: state.pathParameters['id']),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          withdrawalAccountProvider('savings-1').overrideWith(
            (ref) async => {
              'savings_id': 'savings-1',
              'name': 'Member Savings',
            },
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('GH₵ 0.00'), findsOneWidget);
    expect(find.textContaining('unavailable'), findsNothing);
  });

  testWidgets(
    'shows insufficient balance before reviewing an over-limit withdrawal',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/savings/savings-1/withdraw',
        routes: [
          GoRoute(
            path: '/savings/:id/withdraw',
            builder: (context, state) =>
                WithdrawalScreen(savingsId: state.pathParameters['id']),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            withdrawalAccountProvider('savings-1').overrideWith(
              (ref) async => {
                'savings_id': 'savings-1',
                'name': 'Member Savings',
                'balance': 50.0,
              },
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '10');
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Insufficient balance', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed,
        isNull,
      );
    },
  );

  test('withdrawal amount leaves at least GH₵50 in savings', () {
    expect(WithdrawalScreen.canWithdraw(amount: 450, balance: 500), isTrue);
    expect(WithdrawalScreen.canWithdraw(amount: 450.01, balance: 500), isFalse);
    expect(WithdrawalScreen.canWithdraw(amount: 1, balance: 50), isFalse);
  });

  testWidgets('review authorizes and opens withdrawal PIN authentication', (
    tester,
  ) async {
    final data = WithdrawalData(
      savingsId: 'savings-1',
      amount: 100,
      phoneNumber: '0241234567',
      method: 'Mobile Money (MTN)',
      fromAccount: 'Member Savings',
      availableBalance: 500,
    );
    final router = GoRouter(
      initialLocation: '/review',
      routes: [
        GoRoute(
          path: '/review',
          builder: (context, state) => ReviewWithdrawalScreen(data: data),
        ),
        GoRoute(
          path: '/withdrawal/authenticate',
          builder: (context, state) => AuthenticateWithdrawalScreen(
            data: state.extra! as WithdrawalData,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Provider fee'), findsNothing);
    expect(find.text('GH₵ 100.00'), findsNWidgets(2));
    expect(
      find.text(
        'At least GH₵50.00 will remain in your account after this withdrawal.',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.info_outline_rounded), findsNothing);
    final authorize = find.text('Authorize Withdrawal');
    await tester.ensureVisible(authorize);
    await tester.tap(authorize);
    await tester.pumpAndSettle();

    expect(find.byType(AuthenticateWithdrawalScreen), findsOneWidget);
    expect(find.text('Enter your PIN'), findsOneWidget);
  });

  testWidgets('missing secure PIN offers sign-in instead of PIN entry', (
    tester,
  ) async {
    final router = _authenticationRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'No securely saved PIN is available. Sign in again to continue.',
      ),
      findsOneWidget,
    );
    expect(find.text('Sign in again'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    await tester.tap(find.text('Sign in again'));
    await tester.pumpAndSettle();
    expect(find.text('Login screen'), findsOneWidget);
  });

  testWidgets('secure PIN is rechecked and keypad is shown when present', (
    tester,
  ) async {
    secureValues[AppConstants.secureStorageKeyUserPin] = '1234';
    final router = _authenticationRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Sign in again'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('unreadable secure PIN offers sign-in recovery', (tester) async {
    failPinRead = true;
    final router = _authenticationRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(
      find.text('Your saved PIN could not be read. Sign in again to continue.'),
      findsOneWidget,
    );
    expect(find.text('Sign in again'), findsOneWidget);
    expect(find.text('1'), findsNothing);
  });
}

GoRouter _authenticationRouter() {
  final data = WithdrawalData(
    savingsId: 'savings-1',
    amount: 100,
    phoneNumber: '0241234567',
    method: 'Mobile Money (MTN)',
    fromAccount: 'Member Savings',
    availableBalance: 500,
  );
  return GoRouter(
    initialLocation: '/auth',
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => AuthenticateWithdrawalScreen(data: data),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const Text('Login screen'),
      ),
    ],
  );
}
