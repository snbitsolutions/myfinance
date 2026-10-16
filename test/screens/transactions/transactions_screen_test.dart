import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:adepa_teachers/core/providers/app_providers.dart';
import 'package:adepa_teachers/core/services/api_service.dart';
import 'package:adepa_teachers/core/services/device_identity_service.dart';
import 'package:adepa_teachers/screens/transactions/transactions_screen.dart';
import 'package:adepa_teachers/core/exceptions/app_exceptions.dart';

class ThrowingUserService extends UserService {
  @override
  Future<Map<String, dynamic>> getUserProfile({
    required String phoneNumber,
    required String accountNumber,
    required String pin,
  }) async {
    throw Exception('remote service should not be called');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sharedPreferencesChannel = MethodChannel(
    'plugins.flutter.io/shared_preferences',
  );
  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(sharedPreferencesChannel, (call) async {
        if (call.method == 'getAll') {
          return <String, Object>{};
        }
        if (call.method == 'setBool') {
          return true;
        }
        if (call.method == 'setString') {
          return true;
        }
        if (call.method == 'remove') {
          return true;
        }
        return null;
      });
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(secureStorageChannel, (call) async {
        if (call.method == 'read') {
          return null;
        }
        if (call.method == 'containsKey') {
          return false;
        }
        if (call.method == 'readAll') {
          return <String, String>{};
        }
        return null;
      });

  test('transactions provider rejects an incomplete session', () async {
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(
          (ref) => AuthNotifier(
            authService: AuthService(),
            userService: UserService(),
            deviceIdentityService: DeviceIdentityService(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(transactionsProvider.future),
      throwsA(isA<ValidationException>()),
    );
  });

  test('user profile provider rejects an incomplete session', () async {
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(
          (ref) => AuthNotifier(
            authService: AuthService(),
            userService: UserService(),
            deviceIdentityService: DeviceIdentityService(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(userProfileProvider.future),
      throwsA(isA<ValidationException>()),
    );
  });

  test('user profile provider does not fabricate debug session data', () async {
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(
          (ref) => AuthNotifier(
            authService: AuthService(),
            userService: ThrowingUserService(),
            deviceIdentityService: DeviceIdentityService(),
          ),
        ),
        userServiceProvider.overrideWithValue(ThrowingUserService()),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(userProfileProvider.future),
      throwsA(isA<ValidationException>()),
    );
  });

  testWidgets('transactions screen is overflow-safe on small screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 560);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = GoRouter(
      initialLocation: '/transactions',
      routes: [
        GoRoute(
          path: '/transactions',
          builder: (context, state) => const TransactionsScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsProvider.overrideWith(
            (ref) async => <Map<String, dynamic>>[],
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Activity'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Drag if any scrollable is present (empty state may not have ListView)
    final scrollables = find.byType(Scrollable);
    if (tester.widgetList(scrollables).isNotEmpty) {
      await tester.drag(scrollables.first, const Offset(0, -300));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('transactions screen applies the selected statement period', (
    tester,
  ) async {
    final now = DateTime.now();
    final currentMonthDate = DateTime(now.year, now.month, 2, 12);
    final previousMonthDate = DateTime(now.year, now.month - 1, 2, 12);
    final router = GoRouter(
      initialLocation: '/transactions',
      routes: [
        GoRoute(
          path: '/transactions',
          builder: (context, state) => const TransactionsScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsProvider.overrideWith(
            (ref) async => [
              {
                'transaction_id': 'current-month',
                'type': 'credit',
                'amount': 25,
                'description': 'Current month transaction',
                'date': currentMonthDate.toIso8601String(),
              },
              {
                'transaction_id': 'previous-month',
                'type': 'debit',
                'amount': 10,
                'description': 'Previous month transaction',
                'date': previousMonthDate.toIso8601String(),
              },
            ],
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Current month transaction'), findsNWidgets(2));
    expect(find.text('Previous month transaction'), findsNothing);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All Time').last);
    await tester.pumpAndSettle();

    expect(find.text('Previous month transaction'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
