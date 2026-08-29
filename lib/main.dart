import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/services/device_identity_service.dart';
import 'core/services/http_client.dart';
import 'core/services/network_service.dart';
import 'core/services/secure_auth_storage.dart';
import 'core/layout/responsive.dart';
import 'router/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeCoreServices();

  final prefs = await SharedPreferences.getInstance();
  final savedDebugBypass = prefs.getBool(
    AppConstants.sharedPrefKeyDebugBypassAuth,
  );

  if (kDebugMode) {
    final hasSeededIdentity =
        AppConstants.debugApiPhoneNumber.trim().isNotEmpty &&
        AppConstants.debugApiAccountNumber.trim().isNotEmpty;

    // Keep debug bypass opt-in only. Do not silently auto-enable it just
    // because a test identity is present; otherwise the app skips the login flow
    // and starts on the home screen.
    if (!hasSeededIdentity && savedDebugBypass == true) {
      await prefs.setBool(AppConstants.sharedPrefKeyDebugBypassAuth, false);
    }
  }

  if (kDebugMode) {
    await _seedDebugBypassIdentity(prefs);
  }

  runApp(const ProviderScope(child: AdepaTeachersApp()));
}

Future<void> _initializeCoreServices() async {
  try {
    await _initializeCoreServicesSequentially().timeout(
      const Duration(seconds: 8),
    );
  } on TimeoutException {
    debugPrint('Core service initialization timed out; starting the app.');
  } catch (error, stackTrace) {
    debugPrint('Core service initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

Future<void> _initializeCoreServicesSequentially() async {
  await SecureAuthStorage.instance.initialize();
  await HttpClient.instance.initializePreferences();
  await NetworkService.instance.initialize();
  await DeviceIdentityService().primeInstallationId();
}

Future<void> _seedDebugBypassIdentity(SharedPreferences prefs) async {
  final debugPhone = AppConstants.debugApiPhoneNumber.trim();
  final debugAccount = AppConstants.debugApiAccountNumber.trim();
  final debugPin = AppConstants.debugApiPin.trim();

  if (debugPhone.isNotEmpty) {
    await prefs.setString(AppConstants.sharedPrefKeyUserEmail, debugPhone);
  }

  if (debugAccount.isNotEmpty) {
    await prefs.setString(AppConstants.sharedPrefKeyUserId, debugAccount);
  }

  if (debugPin.isNotEmpty) {
    await SecureAuthStorage.instance.storePin(debugPin);
  }
}

class RedirectLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const RedirectLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned(
          left: 0,
          right: 0,
          bottom: 32,
          child: IgnorePointer(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.6),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AdepaTeachersApp extends StatelessWidget {
  const AdepaTeachersApp({super.key});

  @override
  Widget build(BuildContext context) {
    const appColorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF2E8B57),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFD8F0EA),
      onPrimaryContainer: Color(0xFF0B1F1A),
      secondary: Color(0xFF1F5F3F),
      onSecondary: Colors.white,
      tertiary: Color(0xFF6C5CE7),
      error: Color(0xFFE74C3C),
      onError: Colors.white,
      surface: Color(0xFFFBFCFB),
      onSurface: Color(0xFF1B1B1B),
      outline: Color(0xFFD0D5D0),
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      routerConfig: AppRouter.router,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();

        final media = MediaQuery.of(context);
        final maxContentWidth = Responsive.maxContentWidth(context);
        final horizontalPadding = Responsive.horizontalGutter(context);

        final constrainedChild = MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.15,
            ),
          ),
          child: ColoredBox(
            color: appColorScheme.surface,
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: child,
                ),
              ),
            ),
          ),
        );

        return ValueListenableBuilder<bool>(
          valueListenable: AppRouter.redirectLoading,
          builder: (_, isLoading, inner) {
            return RedirectLoadingOverlay(isLoading: isLoading, child: inner!);
          },
          child: constrainedChild,
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: appColorScheme,
        scaffoldBackgroundColor: appColorScheme.surface,
        appBarTheme: AppBarTheme(
          backgroundColor: appColorScheme.secondary,
          elevation: 0,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: appColorScheme.primary,
          unselectedItemColor: Color(0xFFB0B0B0),
          elevation: 8,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: appColorScheme.primary,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B1B1B),
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B1B1B),
          ),
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B1B1B),
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B1B1B),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF404040),
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF606060),
          ),
        ),
      ),
    );
  }
}
