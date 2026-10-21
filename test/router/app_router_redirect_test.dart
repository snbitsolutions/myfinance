import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:adepa_teachers/core/constants/app_constants.dart';
import 'package:adepa_teachers/core/services/device_identity_service.dart';
import 'package:adepa_teachers/main.dart';
import 'package:adepa_teachers/router/app_router.dart';
import 'package:adepa_teachers/screens/auth/otp_screen.dart';
import 'package:adepa_teachers/screens/auth/signup_screen.dart';
import 'package:adepa_teachers/screens/dashboard/dashboard_screen.dart';
import 'package:adepa_teachers/screens/onboarding/onboarding_screen.dart';
import 'package:adepa_teachers/screens/auth/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  final secureStore = <String, String>{};

  Future<Object?> secureStorageHandler(MethodCall call) async {
    final args =
        (call.arguments as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final key = args['key'] as String?;

    switch (call.method) {
      case 'read':
        if (key == null) return null;
        return secureStore[key];
      case 'write':
        if (key != null) {
          final value = args['value'];
          secureStore[key] = value?.toString() ?? '';
        }
        return null;
      case 'delete':
        if (key != null) {
          secureStore.remove(key);
        }
        return null;
      case 'deleteAll':
        secureStore.clear();
        return null;
      case 'containsKey':
        if (key == null) return false;
        return secureStore.containsKey(key);
      case 'readAll':
        return Map<String, String>.from(secureStore);
      default:
        return null;
    }
  }

  setUp(() async {
    AppRouter.resetSessionCache();
    SharedPreferences.setMockInitialValues({
      AppConstants.sharedPrefKeyOnboarding: false,
    });
    secureStore.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, secureStorageHandler);
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  Future<void> pumpAt(
    WidgetTester tester,
    String path, {
    bool settle = true,
  }) async {
    AppRouter.router.go(path);
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: AppRouter.router)),
    );
    await tester.pump();
    if (settle) {
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
    } else {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('starts unauthenticated users on onboarding from root', (
    tester,
  ) async {
    await pumpAt(tester, '/', settle: false);
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(DashboardScreen), findsNothing);
  });

  testWidgets('redirects protected routes to login when onboarding not seen', (
    tester,
  ) async {
    await pumpAt(tester, '/home');
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(DashboardScreen), findsNothing);
  });

  testWidgets(
    'redirects protected routes to login when onboarding seen and session missing',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.sharedPrefKeyOnboarding, true);

      await pumpAt(tester, '/home');

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);
    },
  );

  testWidgets(
    'keeps the auth entry screen visible even when a valid session exists',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.sharedPrefKeyOnboarding, true);

      await prefs.setString(
        AppConstants.sharedPrefKeyDeviceInstallId,
        'test-install-id',
      );
      final fingerprint = await DeviceIdentityService()
          .getInstallationFingerprint();

      secureStore[AppConstants.secureStorageKeyUserToken] = 'test-token';
      secureStore[AppConstants.secureStorageKeySessionDeviceFingerprint] =
          fingerprint;

      await pumpAt(tester, '/login');

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);
    },
  );

  test('treats environment-based debug auth bypass as enabled', () {
    expect(
      AppRouter.isDebugAuthBypassEnabled(
        queryValue: null,
        savedPreferenceValue: false,
        environmentValue: true,
      ),
      isTrue,
    );
  });

  testWidgets('keeps startup on login even when debug auth bypass is enabled', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.sharedPrefKeyOnboarding, true);
    await prefs.setString(AppConstants.sharedPrefKeyUserId, '001060000004075');
    await prefs.setString(AppConstants.sharedPrefKeyUserEmail, '233501234567');

    await pumpAt(tester, '/?debugAuth=true');

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(DashboardScreen), findsNothing);
  });

  testWidgets(
    'keeps protected routes on login even when debug auth bypass is enabled',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.sharedPrefKeyOnboarding, true);
      await prefs.setBool(AppConstants.sharedPrefKeyDebugBypassAuth, true);
      await prefs.setString(
        AppConstants.sharedPrefKeyUserId,
        '001060000004075',
      );
      await prefs.setString(
        AppConstants.sharedPrefKeyUserEmail,
        '233501234567',
      );

      await pumpAt(tester, '/home?debugAuth=true');

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);
    },
  );

  testWidgets(
    'shows SignupScreen at /signup when onboarding seen and no session',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.sharedPrefKeyOnboarding, true);

      await pumpAt(tester, '/signup');

      expect(find.byType(SignupScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    },
  );

  testWidgets('shows OtpScreen at /otp when onboarding seen and no session', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.sharedPrefKeyOnboarding, true);

    AppRouter.router.go(
      '/otp',
      extra: {'phoneNumber': '233501234567', 'accountNumber': '12345678'},
    );
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: AppRouter.router)),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 50));

    expect(find.byType(OtpScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets(
    'clears session and redirects to login when device fingerprint mismatches',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.sharedPrefKeyOnboarding, true);

      // Seed a token bound to a fingerprint that won't match the test device.
      secureStore[AppConstants.secureStorageKeyUserToken] = 'stale-token';
      secureStore[AppConstants.secureStorageKeySessionDeviceFingerprint] =
          'fingerprint-from-a-different-device';

      await pumpAt(tester, '/home');

      // Guard should reject the mismatched session and redirect to login.
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);

      // Auth secrets must have been wiped so the user starts fresh.
      final tokenAfter = secureStore[AppConstants.secureStorageKeyUserToken];
      expect(tokenAfter, isNull);
    },
  );

  testWidgets('loading overlay does not swallow taps', (tester) async {
    var tapped = false;
    AppRouter.redirectLoading.value = true;
    addTearDown(() => AppRouter.redirectLoading.value = false);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RedirectLoadingOverlay(
            isLoading: true,
            child: SizedBox.expand(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => tapped = true,
                child: const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tapAt(const Offset(20, 20));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
