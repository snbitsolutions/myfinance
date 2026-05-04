import 'dart:async';

import 'package:flutter/widgets.dart';
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

// Dashboard Tabs
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/savings/savings_screen.dart';
import '../screens/savings/savings_types_screen.dart';
import '../screens/transactions/transactions_screen.dart';
import '../screens/profile/profile_screen.dart';

// Loans & Savings (non-tab screens)
import '../screens/loans/apply_loan_screen.dart';
import '../screens/loans/loan_detail_screen.dart';
import '../screens/loans/loans_screen.dart';
import '../screens/loans/loan_status_screen.dart';
import '../screens/loans/repayment_screen.dart';
// Payments
import '../screens/payment/payment_screen.dart';
import '../screens/payment/payment_success_screen.dart';
import '../screens/payment/payment_failed_screen.dart';
import '../screens/savings/create_savings_screen.dart';
import '../screens/savings/savings_detail_screen.dart';
import '../screens/savings/savings_model.dart';
import '../screens/savings/savings_success_screen.dart';
import '../screens/savings/transfer_screen.dart';
import '../screens/savings/withdraw_savings_screen.dart';
import '../screens/profile/kyc_screen.dart';
import '../screens/profile/settings_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/shares/shares_screen.dart';
import '../screens/investment/investment_activity_screen.dart';
import '../screens/investment/investment_screen.dart';
import '../screens/error/app_error_screen.dart';

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

    // Keep splash navigation behavior intact.
    if (path == '/') {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding =
        prefs.getBool(AppConstants.sharedPrefKeyOnboarding) ?? false;

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
          builder: (context, state) => SignupScreen(
            reason: state.uri.queryParameters['reason'],
          ),
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
            return OtpScreen(
              phoneNumber: extra?['phoneNumber'] as String? ?? '',
              accountNumber: extra?['accountNumber'] as String? ?? '',
            );
          },
        ),
        GoRoute(
          path: '/set-pin',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return SetPinScreen(
              phoneNumber: extra?['phoneNumber'] as String? ?? '',
              accountNumber: extra?['accountNumber'] as String? ?? '',
              mode: extra?['mode'] as String? ?? 'manage',
            );
          },
        ),

        // =========================
        // MAIN APP (Bottom Nav)
        // =========================
        ShellRoute(
          builder: (context, state, child) {
            return MainShell(child: child);
          },
          routes: [
            // Tabs
            GoRoute(
              path: '/home',
              builder: (context, state) => const DashboardScreen(),
            ),
            GoRoute(
              path: '/savings',
              builder: (context, state) {
                // if a type query parameter is provided we could filter inside
                // the savings screen; currently ignored.
                return const SavingsScreen();
              },
            ),
            GoRoute(
              path: '/savings/types',
              builder: (context, state) => const SavingsTypesScreen(),
            ),
            GoRoute(
              path: '/transactions',
              builder: (context, state) {
                List<Map<String, dynamic>>? savingsTransactions;
                final extra = state.extra;
                if (extra is Map<String, dynamic>) {
                  final raw = extra['savingsTransactions'];
                  if (raw is List) {
                    savingsTransactions = raw
                        .whereType<Map>()
                        .map((item) => Map<String, dynamic>.from(item))
                        .toList();
                  }
                }

                return TransactionsScreen(
                  savingsId: state.uri.queryParameters['savingsId'],
                  savingsTitle: state.uri.queryParameters['savingsTitle'],
                  savingsTransactions: savingsTransactions,
                );
              },
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),

            // Sub-pages (still keep bottom nav)
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
              path: '/payment',
              builder: (context, state) {
                final source = state.uri.queryParameters['source'];
                return PaymentScreen(
                  sourceLabel: source == 'existing_account'
                      ? 'Existing account'
                      : source == 'investment'
                      ? 'Investment'
                      : null,
                );
              },
            ),
            GoRoute(
              path: '/payment-success',
              builder: (context, state) {
                final extra = state.extra;
                if (extra is Map<String, dynamic>) {
                  final rawAmount = extra['amount'];
                  final rawProcessedAt = extra['processedAt'];
                  final rawReference = extra['reference'];
                  final rawTitle = extra['title'];
                  final rawMessage = extra['message'];
                  final rawPrimaryActionLabel = extra['primaryActionLabel'];
                  final rawPrimaryActionRoute = extra['primaryActionRoute'];
                  final rawSecondaryActionLabel = extra['secondaryActionLabel'];
                  final rawSecondaryActionRoute = extra['secondaryActionRoute'];

                  final amount = rawAmount is num ? rawAmount.toDouble() : null;
                  final processedAt = rawProcessedAt is String
                      ? DateTime.tryParse(rawProcessedAt)
                      : null;
                  final reference = rawReference is String
                      ? rawReference
                      : null;
                  final title = rawTitle is String
                      ? rawTitle
                      : 'Payment Successful';
                  final message = rawMessage is String
                      ? rawMessage
                      : 'Your transaction was completed successfully.';
                  final primaryActionLabel = rawPrimaryActionLabel is String
                      ? rawPrimaryActionLabel
                      : null;
                  final primaryActionRoute = rawPrimaryActionRoute is String
                      ? rawPrimaryActionRoute
                      : null;
                  final secondaryActionLabel = rawSecondaryActionLabel is String
                      ? rawSecondaryActionLabel
                      : null;
                  final secondaryActionRoute = rawSecondaryActionRoute is String
                      ? rawSecondaryActionRoute
                      : null;

                  return PaymentSuccessScreen(
                    amount: amount,
                    processedAt: processedAt,
                    reference: reference,
                    title: title,
                    message: message,
                    primaryActionLabel: primaryActionLabel,
                    primaryActionRoute: primaryActionRoute,
                    secondaryActionLabel: secondaryActionLabel,
                    secondaryActionRoute: secondaryActionRoute,
                  );
                }
                return const PaymentSuccessScreen();
              },
            ),
            GoRoute(
              path: '/payment-failed',
              builder: (context, state) => const PaymentFailedScreen(),
            ),
            GoRoute(
              path: '/savings/create',
              builder: (context, state) {
                final typeParam = state.uri.queryParameters['type'];
                SavingsType? initialType;
                switch (typeParam) {
                  case 'member':
                    initialType = SavingsType.memberSaving;
                    break;
                  case 'current':
                    initialType = SavingsType.currentSaving;
                    break;
                  case 'kiddy':
                    initialType = SavingsType.kiddySaving;
                    break;
                  case 'fixed':
                    initialType = SavingsType.fixedDeposit;
                    break;
                }
                return CreateSavingsScreen(initialType: initialType);
              },
            ),
            GoRoute(
              name: 'savings-success',
              path: '/savings/success',
              builder: (context, state) {
                final savings = state.extra as Savings;
                return SavingsSuccessScreen(savings: savings);
              },
            ),
            GoRoute(
              path: '/savings/transfer',
              builder: (context, state) => const TransferScreen(),
            ),
            GoRoute(
              path: '/savings/withdraw',
              builder: (context, state) => const WithdrawSavingsScreen(),
            ),
            GoRoute(
              path: '/savings/:id/withdraw',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return WithdrawSavingsScreen(savingsId: id);
              },
            ),
            GoRoute(
              path: '/savings/:id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                final extra = state.extra;
                return SavingsDetailScreen(
                  savingsId: id,
                  savings: extra is Savings ? extra : null,
                );
              },
            ),
            GoRoute(
              path: '/kyc',
              builder: (context, state) => const KycScreen(),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
            GoRoute(
              path: '/notifications',
              builder: (context, state) => const NotificationsScreen(),
            ),
            GoRoute(
              path: '/shares',
              builder: (context, state) => const SharesScreen(),
            ),
            GoRoute(
              path: '/investment',
              builder: (context, state) => const InvestmentScreen(),
            ),
            GoRoute(
              path: '/investment/activity',
              builder: (context, state) => const InvestmentActivityScreen(),
            ),
          ],
        ),
      ],
    );

    NavigationHistory.instance.attach(configuredRouter);
    return configuredRouter;
  }
}
