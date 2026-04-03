import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/services/device_identity_service.dart';
import 'core/services/http_client.dart';
import 'core/services/network_service.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize core services
  await HttpClient.instance.initializePreferences();
  await NetworkService.instance.initialize();
  await DeviceIdentityService().primeInstallationId();

  runApp(const ProviderScope(child: AdepaTeachersApp()));
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
