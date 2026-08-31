import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'navigation_history.dart';
import '../core/constants/app_constants.dart';
import '../core/services/device_identity_service.dart';
import '../core/services/secure_auth_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Core

// Splash & Onboarding
import '../core/layout/main_shell.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';

// Auth
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/account_number_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/auth/set_pin_screen.dart';

// Starter app shell only. All feature code has been cleared to allow a clean rebuild.
import '../screens/error/app_error_screen.dart';
import '../screens/investment/investment_activity_screen.dart';
import '../screens/investment/investment_screen.dart';
import '../screens/loans/apply_loan_screen.dart';
import '../screens/loans/loan_detail_screen.dart';
import '../screens/loans/loan_status_screen.dart';
import '../screens/loans/loans_screen.dart';
import '../screens/loans/repayment_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/payment/payment_failed_screen.dart';
import '../screens/payment/payment_home_screen.dart';
import '../screens/payment/payment_receipt_screen.dart';
import '../screens/payment/payment_screen.dart';
import '../screens/payment/payment_success_screen.dart';
import '../screens/profile/kyc_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/settings_screen.dart';
import '../screens/savings/create_savings_screen.dart';
import '../screens/savings/products_screen.dart';
import '../screens/savings/savings_deposit_screen.dart';
import '../screens/savings/savings_detail_screen.dart';
import '../screens/savings/savings_model.dart';
import '../screens/savings/savings_screen.dart';
import '../screens/savings/savings_types_screen.dart';
import '../screens/savings/transfer_screen.dart';
import '../screens/savings/withdraw_savings_screen.dart';
import '../screens/transactions/transactions_screen.dart';

class AppRouter {
  static final GoRouter router = _createRouter();

  /// True while the async redirect guard is resolving.
  static final redirectLoading = ValueNotifier<bool>(false);

  static const Duration _loadingIndicatorDelay = Duration(milliseconds: 180);
  static const Duration _sessionCacheTtl = Duration(seconds: 2);

  static Future<bool>? _sessionCheckInFlight;
  static bool? _cachedHasBoundSession;
  static DateTime? _cachedHasBoundSessionAt;

  /// Resets the session cache. Intended for use in tests only.
  @visibleForTesting
  static void resetSessionCache() {
    _cachedHasBoundSession = null;
    _cachedHasBoundSessionAt = null;
    _sessionCheckInFlight = null;
  }

  static const Set<String> _authRoutes = {
    '/login',
    '/signup',
    '/account-number',
    '/otp',
    '/set-pin',
  };

  static const Set<String> _preAuthRoutes = {
    '/',
    '/onboarding',
    ..._authRoutes,
  };

  static bool _matchesRoute(String path, String route) {
    return path == route || path.startsWith('$route/');
  }

  static bool _isInRouteSet(String path, Set<String> routeSet) {
    for (final route in routeSet) {
      if (_matchesRoute(path, route)) {
        return true;
      }
    }
    return false;
  }

  static bool isDebugAuthBypassEnabled({
    String? queryValue,
    bool? savedPreferenceValue,
    bool? environmentValue,
  }) {
    final effectiveEnvironmentValue =
        environmentValue ??
        const bool.fromEnvironment('DEBUG_AUTH_BYPASS', defaultValue: false);

    return (queryValue == 'true') ||
        (savedPreferenceValue ?? false) ||
        effectiveEnvironmentValue;
  }

  static Future<bool> _hasBoundSession() async {
    final now = DateTime.now();
    final cachedHasSession = _cachedHasBoundSession;
    final cachedAt = _cachedHasBoundSessionAt;

    if (cachedHasSession != null &&
        cachedAt != null &&
        now.difference(cachedAt) <= _sessionCacheTtl) {
      if (!cachedHasSession) {
        return false;
      }

      final token = await SecureAuthStorage.instance.readAuthToken() ?? '';
      if (token.isNotEmpty) {
        return true;
      }

      _cachedHasBoundSession = false;
      _cachedHasBoundSessionAt = DateTime.now();
      return false;
    }

    final inFlight = _sessionCheckInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final check = _computeHasBoundSession();
    _sessionCheckInFlight = check;

    try {
      final result = await check;
      _cachedHasBoundSession = result;
      _cachedHasBoundSessionAt = DateTime.now();
      return result;
    } finally {
      _sessionCheckInFlight = null;
    }
  }

  static Future<bool> _computeHasBoundSession() async {
    final secureAuthStorage = SecureAuthStorage.instance;
    final token = await secureAuthStorage.readAuthToken() ?? '';
    if (token.isEmpty) {
      return false;
    }

    final currentFingerprint = await DeviceIdentityService()
        .getInstallationFingerprint();
    final isBoundToCurrentDevice = await secureAuthStorage
        .hasSessionBoundToFingerprint(currentFingerprint);

    if (isBoundToCurrentDevice) {
      return true;
    }

    final prefs = await SharedPreferences.getInstance();
    await secureAuthStorage.clearAuthSecrets();
    await prefs.remove(AppConstants.sharedPrefKeyUserId);
    await prefs.remove(AppConstants.sharedPrefKeyUserEmail);
    return false;
  }

  static Future<String?> _handleRedirect(GoRouterState state) async {
    Timer? loadingTimer;
    loadingTimer = Timer(_loadingIndicatorDelay, () {
      _setRedirectLoading(true);
    });

    try {
      return await _computeRedirect(state);
    } finally {
      loadingTimer.cancel();
      _setRedirectLoading(false);
    }
  }

  static void _setRedirectLoading(bool isLoading) {
    if (redirectLoading.value == isLoading) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (redirectLoading.value != isLoading) {
        redirectLoading.value = isLoading;
      }
    });
  }

  static Future<String?> _computeRedirect(GoRouterState state) async {
    final path = state.uri.path;

    final prefs = await SharedPreferences.getInstance();
    final storedUserId =
        prefs.getString(AppConstants.sharedPrefKeyUserId)?.trim() ?? '';
    final storedUserEmail =
        prefs.getString(AppConstants.sharedPrefKeyUserEmail)?.trim() ?? '';
    final seededUserId = AppConstants.debugApiAccountNumber.trim();
    final seededUserEmail = AppConstants.debugApiPhoneNumber.trim();
    final hasDebugIdentity =
        (storedUserId.isNotEmpty && storedUserEmail.isNotEmpty) ||
        (seededUserId.isNotEmpty && seededUserEmail.isNotEmpty);
    final seenOnboarding =
        prefs.getBool(AppConstants.sharedPrefKeyOnboarding) ?? false;
    final debugBypassAuth = isDebugAuthBypassEnabled(
      queryValue: state.uri.queryParameters['debugAuth'],
      savedPreferenceValue: prefs.getBool(
        AppConstants.sharedPrefKeyDebugBypassAuth,
      ),
    );

    // Keep splash navigation behavior intact for normal runs, but let the
    // debug bypass skip directly to the home screen.
    if (path == '/') {
      if (debugBypassAuth) {
        return hasDebugIdentity ? '/home' : '/login';
      }
      return null;
    }

    if (debugBypassAuth) {
      // Allow auth flow when debug identity is not configured yet.
      if (!hasDebugIdentity) {
        if (!_isInRouteSet(path, _preAuthRoutes)) {
          return '/login';
        }
        return null;
      }

      if (_isInRouteSet(path, _preAuthRoutes)) {
        return '/home';
      }
      return null;
    }

    if (!seenOnboarding) {
      return path == '/onboarding' ? null : '/onboarding';
    }

    final hasSession = await _hasBoundSession();
    final isPreAuthRoute = _isInRouteSet(path, _preAuthRoutes);
    final isAuthRoute = _isInRouteSet(path, _authRoutes);

    if (!hasSession) {
      if (!isPreAuthRoute) {
        return '/login';
      }
      if (path == '/onboarding') {
        return '/login';
      }
      return null;
    }

    if (isAuthRoute || path == '/onboarding') {
      return '/home';
    }

    return null;
  }

  static GoRouter _createRouter() {
    final configuredRouter = GoRouter(
      initialLocation: '/',
      redirect: (context, state) => _handleRedirect(state),
      errorBuilder: (context, state) {
        final errorMessage = state.error?.toString();
        return AppErrorScreen(message: errorMessage);
      },
      routes: [
        // ===================
        // Splash & Onboarding
        // ===================
        GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),

        // ==========
        // Auth Flow
        // ==========
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) =>
              SignupScreen(reason: state.uri.queryParameters['reason']),
        ),
        GoRoute(
          path: '/account-number',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return AccountNumberScreen(
              phoneNumber: extra?['phoneNumber'] as String? ?? '',
            );
          },
        ),
        GoRoute(
          path: '/otp',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final query = state.uri.queryParameters;
            return OtpScreen(
              phoneNumber:
                  extra?['phoneNumber'] as String? ??
                  query['phoneNumber'] ??
                  '',
              accountNumber:
                  extra?['accountNumber'] as String? ??
                  query['accountNumber'] ??
                  '',
            );
          },
        ),
        GoRoute(
          path: '/set-pin',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final query = state.uri.queryParameters;
            final resolvedPhone =
                extra?['phoneNumber'] as String? ?? query['phoneNumber'] ?? '';
            final resolvedAccount =
                extra?['accountNumber'] as String? ??
                query['accountNumber'] ??
                '';
            final resolvedMode =
                extra?['mode'] as String? ?? query['mode'] ?? 'manage';
            return SetPinScreen(
              phoneNumber: resolvedPhone,
              accountNumber: resolvedAccount,
              mode: resolvedMode,
            );
          },
        ),

        GoRoute(
          path: '/payment',
          builder: (context, state) {
            final query = state.uri.queryParameters;
            final extra = state.extra as Map<String, dynamic>?;
            return PaymentScreen(
              sourceLabel: extra?['sourceLabel'] as String? ??
                  query['sourceLabel'],
              returnRoute: extra?['returnRoute'] as String? ??
                  query['returnRoute'],
            );
          },
        ),
        GoRoute(
          path: '/payment/deposit',
          redirect: (context, state) {
            final query = state.uri.queryParameters;
            final returnRoute = query['returnRoute'] ?? '/savings';
            return Uri(
              path: '/payment',
              queryParameters: {
                'sourceLabel': 'Deposit',
                'returnRoute': returnRoute,
              },
            ).toString();
          },
        ),
        GoRoute(
          path: '/payment-success',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? const {};
            return PaymentSuccessScreen(
              amount: (extra['amount'] as num?)?.toDouble(),
              processedAt: extra['processedAt'] != null
                  ? DateTime.tryParse(extra['processedAt'] as String? ?? '')
                  : null,
              reference: extra['reference'] as String?,
              title: extra['title'] as String?,
              message: extra['message'] as String?,
              primaryActionLabel: extra['primaryActionLabel'] as String?,
              primaryActionRoute: extra['primaryActionRoute'] as String?,
              secondaryActionLabel: extra['secondaryActionLabel'] as String?,
              secondaryActionRoute: extra['secondaryActionRoute'] as String?,
              account: extra['account'] as String?,
              paymentMethod: extra['paymentMethod'] as String?,
              newBalance: (extra['newBalance'] as num?)?.toDouble(),
            );
          },
        ),
        GoRoute(
          path: '/payment-failed',
          builder: (context, state) {
            final query = state.uri.queryParameters;
            final extra = state.extra as Map<String, dynamic>? ?? const {};
            final returnRoute = extra['returnRoute'] as String? ??
                query['returnRoute'] ??
                '/home';
            final amount = (extra['amount'] as num?)?.toDouble() ??
                double.tryParse(query['amount'] ?? '') ??
                0;
            final reason = extra['message'] as String? ?? query['reason'];
            return PaymentFailedScreen(
              returnRoute: returnRoute,
              isDeposit: extra['isDeposit'] as bool? ??
                  query['isDeposit'] == 'true',
              amount: amount,
              reason: reason,
            );
          },
        ),
        GoRoute(
          path: '/payment-receipt',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? const {};
            return PaymentReceiptScreen(
              amount: (extra['amount'] as num?)?.toDouble(),
              processedAt: extra['processedAt'] != null
                  ? DateTime.tryParse(extra['processedAt'] as String? ?? '')
                  : null,
              reference: extra['reference'] as String?,
              account: extra['account'] as String?,
              paymentMethod: extra['paymentMethod'] as String?,
              newBalance: (extra['newBalance'] as num?)?.toDouble(),
            );
          },
        ),
        GoRoute(
          path: '/transactions',
          builder: (context, state) => const TransactionsScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/kyc',
          builder: (context, state) => const KycScreen(),
        ),
        GoRoute(
          path: '/profile/edit',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/loans',
          builder: (context, state) => const LoansScreen(),
        ),
        GoRoute(
          path: '/apply-loan',
          builder: (context, state) => const ApplyLoanScreen(),
        ),
        GoRoute(
          path: '/loan-status',
          builder: (context, state) => const LoanStatusScreen(),
        ),
        GoRoute(
          path: '/loan-detail',
          builder: (context, state) => const LoanDetailScreen(),
        ),
        GoRoute(
          path: '/repayment',
          builder: (context, state) => const RepaymentScreen(),
        ),
        GoRoute(
          path: '/investment',
          builder: (context, state) => const InvestmentScreen(),
        ),
        GoRoute(
          path: '/investment/activity',
          builder: (context, state) => const InvestmentActivityScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) {
            return MainShell(child: child);
          },
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const PaymentHomeScreen(),
            ),
            GoRoute(
              path: '/savings',
              builder: (context, state) => const SavingsScreen(),
            ),
            GoRoute(
              path: '/savings/create',
              builder: (context, state) {
                final type = state.uri.queryParameters['type'];
                final selectedType = switch (type) {
                  'current' => SavingsType.currentSaving,
                  'kiddy' => SavingsType.kiddySaving,
                  'fixed' => SavingsType.fixedDeposit,
                  _ => SavingsType.memberSaving,
                };
                return CreateSavingsScreen(initialType: selectedType);
              },
            ),
            GoRoute(
              path: '/savings/types',
              builder: (context, state) => const SavingsTypesScreen(),
            ),
            GoRoute(
              path: '/savings/withdraw',
              builder: (context, state) => const WithdrawSavingsScreen(),
            ),
            GoRoute(
              path: '/savings/transfer',
              builder: (context, state) => const TransferScreen(),
            ),
            GoRoute(
              path: '/savings/products',
              builder: (context, state) => const ProductsScreen(),
            ),
            GoRoute(
              path: '/savings/:id',
              builder: (context, state) {
                final id = state.pathParameters['id'] ?? 'custom-savings';
                return SavingsDetailScreen(savingsId: id);
              },
            ),
            GoRoute(
              path: '/savings/:id/deposit',
              builder: (context, state) {
                final id = state.pathParameters['id'] ?? 'custom-savings';
                return SavingsDepositScreen(savingsId: id);
              },
            ),
            GoRoute(
              path: '/savings/:id/withdraw',
              builder: (context, state) {
                final id = state.pathParameters['id'] ?? 'custom-savings';
                return WithdrawSavingsScreen(savingsId: id);
              },
            ),
            GoRoute(
              path: '/savings/:id/transfer',
              builder: (context, state) => const TransferScreen(),
            ),
            GoRoute(
              path: '/savings/:id/statement',
              builder: (context, state) {
                final id = state.pathParameters['id'] ?? 'custom-savings';
                return SavingsDetailScreen(savingsId: id);
              },
            ),
            GoRoute(
              path: '/savings/:id/edit',
              builder: (context, state) => const CreateSavingsScreen(),
            ),
            GoRoute(
              path: '/products',
              builder: (context, state) => const ProductsScreen(),
            ),
            GoRoute(
              path: '/pay',
              builder: (context, state) => const PaymentScreen(),
            ),
            GoRoute(
              path: '/activity',
              builder: (context, state) => const TransactionsScreen(),
            ),
            GoRoute(
              path: '/more',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    );

    NavigationHistory.instance.attach(configuredRouter);
    return configuredRouter;
  }
}
