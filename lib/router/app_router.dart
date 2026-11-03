import 'dart:async';

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
import '../core/app_scaffold.dart';
import '../core/app_card.dart' as core_app_card;
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/legal/terms_of_service_screen.dart';

// Auth
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/existing_member_enrollment_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/auth/registration_success_screen.dart';
import '../screens/auth/set_pin_screen.dart';

// Starter app shell only. All feature code has been cleared to allow a clean rebuild.
import '../screens/error/app_error_screen.dart';
import '../screens/investment/investments_screen.dart';
import '../screens/investment/investment_detail_screen.dart';
import '../screens/loans/apply_loan_screen.dart';
import '../screens/loans/loan_detail_screen.dart';
import '../screens/loans/loan_status_screen.dart';
import '../screens/loans/loans_screen.dart' as loans_screen;
import '../screens/loans/repayment_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/payment/mobile_purchase_screen.dart';
import '../screens/payment/bills_payment_screen.dart';
import '../screens/payment/payment_failed_screen.dart';
import '../screens/payment/payment_receipt_screen.dart';
import '../screens/payment/payment_screen.dart';
import '../screens/payment/payment_success_screen.dart';
import '../screens/payment/payments_hub_screen.dart';
import '../screens/payment/payroll_deduction_adjustment_screen.dart';
import '../screens/profile/kyc_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/settings_screen.dart';
import '../screens/savings/create_savings_screen.dart';
import '../screens/savings/savings_deposit_screen.dart';
import '../screens/savings/savings_detail_screen.dart';
import '../screens/savings/products_screen.dart';
import '../screens/savings/savings_model.dart';
import '../screens/savings/savings_screen.dart';
import '../screens/savings/savings_success_screen.dart';
import '../screens/savings/savings_types_screen.dart';
import '../screens/savings/transfer_screen.dart';
import '../screens/savings/withdrawal_flow/withdrawal_screen.dart';
import '../screens/savings/withdrawal_flow/review_withdrawal_screen.dart';
import '../screens/savings/withdrawal_flow/authenticate_withdrawal_screen.dart';
import '../screens/savings/withdrawal_flow/processing_withdrawal_screen.dart';
import '../screens/savings/withdrawal_flow/success_withdrawal_screen.dart';
import '../screens/savings/withdrawal_flow/receipt_withdrawal_screen.dart';
import '../screens/savings/withdrawal_flow/withdrawal_model.dart';
import '../screens/savings/transfer_flow/transfer_destination_screen.dart';
import '../screens/savings/transfer_flow/select_recipient_screen.dart';
import '../screens/savings/transfer_flow/enter_recipient_details_screen.dart';
import '../screens/savings/transfer_flow/verify_recipient_screen.dart';
import '../screens/savings/transfer_flow/enter_transfer_amount_screen.dart';
import '../screens/savings/transfer_flow/review_transfer_screen.dart';
import '../screens/savings/transfer_flow/authenticate_transfer_screen.dart';
import '../screens/savings/transfer_flow/processing_transfer_screen.dart';
import '../screens/savings/transfer_flow/transfer_model.dart';
import '../screens/transactions/transactions_screen.dart';
import '../screens/shares/shares_screen.dart';
import '../screens/shares/share_detail_screen.dart';
import '../screens/shares/buy_shares_screen.dart';
import '../screens/shares/sell_shares_screen.dart';
import '../screens/shares/portfolio_statement_screen.dart';
import '../screens/shares/dividend_history_screen.dart';

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
    invalidateSessionCache();
  }

  /// Invalidates cached authentication results after a session is restored.
  static void invalidateSessionCache() {
    _cachedHasBoundSession = null;
    _cachedHasBoundSessionAt = null;
    _sessionCheckInFlight = null;
  }

  static const Set<String> _authRoutes = {
    '/login',
    '/signup',
    '/existing-member-enrollment',
    '/otp',
    '/set-pin',
  };

  static const Set<String> _preAuthRoutes = {
    '/',
    '/terms',
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

      final currentFingerprint = await DeviceIdentityService()
          .getInstallationFingerprint();
      if (await SecureAuthStorage.instance
          .hasAuthenticatedSessionBoundToFingerprint(currentFingerprint)) {
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
    final currentFingerprint = await DeviceIdentityService()
        .getInstallationFingerprint();
    final isBoundToCurrentDevice = await secureAuthStorage
        .hasAuthenticatedSessionBoundToFingerprint(currentFingerprint);

    if (isBoundToCurrentDevice) {
      final prefs = await SharedPreferences.getInstance();
      final accountNumber =
          prefs.getString(AppConstants.sharedPrefKeyUserId)?.trim() ?? '';
      final phoneNumber =
          prefs.getString(AppConstants.sharedPrefKeyUserEmail)?.trim() ?? '';
      if (accountNumber.isNotEmpty && phoneNumber.isNotEmpty) {
        return true;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await secureAuthStorage.clearAuthSecrets();
    await prefs.remove(AppConstants.sharedPrefKeyUserId);
    await prefs.remove(AppConstants.sharedPrefKeyUserEmail);
    return false;
  }

  static Future<bool> _hasUsableSession() async {
    return _hasBoundSession();
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

  // Keep the splash and normal authentication flow active on startup.
  static const bool _temporarilyBypassLoginForDev = false;

  static Future<String?> _computeRedirect(GoRouterState state) async {
    final path = state.uri.path;

    final prefs = await SharedPreferences.getInstance();
    final acceptedTermsVersion = prefs.getString(
      AppConstants.sharedPrefKeyAcceptedTermsVersion,
    );
    final requiresTermsAcceptance =
        path == '/onboarding' || _isInRouteSet(path, _authRoutes);
    if (path != '/' &&
        path != '/terms' &&
        requiresTermsAcceptance &&
        acceptedTermsVersion != AppConstants.termsOfServiceVersion) {
      return '/terms';
    }

    if (_temporarilyBypassLoginForDev) {
      if (path == '/' ||
          path == '/onboarding' ||
          _isInRouteSet(path, _authRoutes)) {
        return '/home';
      }
      return null;
    }

    final seenOnboarding =
        prefs.getBool(AppConstants.sharedPrefKeyOnboarding) ?? false;
    final debugBypassAuth = isDebugAuthBypassEnabled(
      queryValue: state.uri.queryParameters['debugAuth'],
      savedPreferenceValue: prefs.getBool(
        AppConstants.sharedPrefKeyDebugBypassAuth,
      ),
    );

    // Splash is the initial entry point. Users without onboarding complete must
    // continue through onboarding before they can reach the sign-in screen.
    if (path == '/') {
      return null;
    }

    if (path == '/onboarding') {
      return seenOnboarding ? '/login' : null;
    }

    if (_isInRouteSet(path, _preAuthRoutes)) {
      return null;
    }

    if (debugBypassAuth) {
      return '/login';
    }

    if (!seenOnboarding) {
      return '/login';
    }

    final hasSession = await _hasUsableSession();
    if (!hasSession) {
      return '/login';
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
          path: '/terms',
          builder: (context, state) => const TermsOfServiceScreen(),
        ),
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
          path: '/existing-member-enrollment',
          builder: (context, state) {
            final memberType =
                state.uri.queryParameters['memberType'] ?? 'existing';
            return ExistingMemberEnrollmentScreen(memberType: memberType);
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
              isRegistration: extra?['isRegistration'] as bool? ?? false,
              transactionPin: extra?['transactionPin'] as String?,
              transactionPinAlreadyProvisioned:
                  extra?['transactionPinAlreadyProvisioned'] as bool? ?? false,
            );
          },
        ),
        GoRoute(
          path: '/registration-success',
          builder: (context, state) {
            final extra = state.extra is Map<String, dynamic>
                ? state.extra! as Map<String, dynamic>
                : const <String, dynamic>{};
            return RegistrationSuccessScreen(
              accountNumber: extra['accountNumber'] as String? ?? '',
              phoneNumber: extra['phoneNumber'] as String? ?? '',
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
          path: '/payments-hub',
          builder: (context, state) => const PaymentsHubScreen(),
        ),
        GoRoute(
          path: '/payroll-deduction-adjustment',
          builder: (context, state) => const PayrollDeductionAdjustmentScreen(),
        ),
        GoRoute(
          path: '/payment/bills',
          builder: (context, state) => const BillsPaymentScreen(),
        ),
        GoRoute(
          path: '/payment',
          builder: (context, state) {
            final query = state.uri.queryParameters;
            final type = query['type'];
            final extra = state.extra is Map<String, dynamic>
                ? state.extra! as Map<String, dynamic>
                : null;

            // Route to supported payment flows.
            if (type == 'bills') {
              return const BillsPaymentScreen();
            }
            if (type == 'airtime') {
              return const MobilePurchaseScreen();
            }
            if (type == 'data') {
              return const MobilePurchaseScreen(isData: true);
            }

            return PaymentScreen(
              sourceLabel:
                  extra?['sourceLabel'] as String? ?? query['sourceLabel'],
              returnRoute:
                  extra?['returnRoute'] as String? ?? query['returnRoute'],
              initialAmount: double.tryParse(query['amount'] ?? ''),
              initialMethod: query['method'],
              savingsId: query['savingsId'],
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
                if (query['savingsId']?.trim().isNotEmpty == true)
                  'savingsId': query['savingsId'],
              },
            ).toString();
          },
        ),
        GoRoute(
          path: '/payment/receive',
          redirect: (context, state) {
            final query = state.uri.queryParameters;
            final returnRoute = query['returnRoute'] ?? '/savings';
            return Uri(
              path: '/payment',
              queryParameters: {
                'sourceLabel': 'Receive Money',
                'returnRoute': returnRoute,
                if (query['savingsId']?.trim().isNotEmpty == true)
                  'savingsId': query['savingsId'],
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
              isPending: extra['isPending'] as bool? ?? false,
            );
          },
        ),
        GoRoute(
          path: '/payment-failed',
          builder: (context, state) {
            final query = state.uri.queryParameters;
            final extra = state.extra as Map<String, dynamic>? ?? const {};
            final returnRoute =
                extra['returnRoute'] as String? ??
                query['returnRoute'] ??
                '/home';
            final amount =
                (extra['amount'] as num?)?.toDouble() ??
                double.tryParse(query['amount'] ?? '') ??
                0;
            final reason = extra['message'] as String? ?? query['reason'];
            return PaymentFailedScreen(
              returnRoute: returnRoute,
              isDeposit:
                  extra['isDeposit'] as bool? ?? query['isDeposit'] == 'true',
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
              isPending: extra['isPending'] as bool? ?? false,
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
        GoRoute(path: '/kyc', builder: (context, state) => const KycScreen()),
        GoRoute(path: '/profile/edit', redirect: (context, state) => '/more'),
        GoRoute(
          path: '/investment',
          redirect: (context, state) => '/investments',
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
          builder: (context, state) {
            final loanId = state.uri.queryParameters['loanId'];
            return RepaymentScreen(loanId: loanId);
          },
        ),
        GoRoute(
          path: '/investments',
          builder: (context, state) => const InvestmentsScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final investmentId = state.pathParameters['id'];
                return InvestmentDetailScreen(investmentId: investmentId);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/investment/activity',
          redirect: (context, state) => '/investments',
        ),
        // Withdrawal flow routes
        GoRoute(
          path: '/withdrawal',
          builder: (context, state) {
            final savingsId = state.uri.queryParameters['savingsId'] ?? '';
            return WithdrawalScreen(savingsId: savingsId);
          },
        ),
        GoRoute(
          path: '/withdrawal/review',
          builder: (context, state) {
            final data = state.extra as WithdrawalData;
            return ReviewWithdrawalScreen(data: data);
          },
        ),
        GoRoute(
          path: '/withdrawal/authenticate',
          builder: (context, state) {
            final data = state.extra as WithdrawalData;
            return AuthenticateWithdrawalScreen(data: data);
          },
        ),
        GoRoute(
          path: '/withdrawal/processing',
          builder: (context, state) {
            final data = state.extra as WithdrawalData;
            return ProcessingWithdrawalScreen(data: data);
          },
        ),
        GoRoute(
          path: '/withdrawal/success',
          builder: (context, state) {
            final data = state.extra as WithdrawalData;
            return SuccessWithdrawalScreen(data: data);
          },
        ),
        GoRoute(
          path: '/withdrawal/receipt',
          builder: (context, state) {
            final data = state.extra as WithdrawalData;
            return ReceiptWithdrawalScreen(data: data);
          },
        ),
        // Transfer flow routes
        GoRoute(
          path: '/transfer',
          builder: (context, state) {
            final savingsId = state.uri.queryParameters['savingsId'] ?? '';
            return TransferDestinationScreen(
              initialData: TransferData(savingsId: savingsId),
            );
          },
        ),
        GoRoute(
          path: '/transfer/select-recipient',
          builder: (context, state) {
            final data = state.extra as TransferData;
            return SelectRecipientScreen(initialData: data);
          },
        ),
        GoRoute(
          path: '/transfer/enter-details',
          builder: (context, state) {
            final data = state.extra as TransferData;
            return EnterRecipientDetailsScreen(initialData: data);
          },
        ),
        GoRoute(
          path: '/transfer/verify-recipient',
          builder: (context, state) {
            final data = state.extra as TransferData;
            return VerifyRecipientScreen(initialData: data);
          },
        ),
        GoRoute(
          path: '/transfer/enter-amount',
          builder: (context, state) {
            final data = state.extra as TransferData;
            return EnterTransferAmountScreen(initialData: data);
          },
        ),
        GoRoute(
          path: '/transfer/review',
          builder: (context, state) {
            final data = state.extra as TransferData;
            return ReviewTransferScreen(initialData: data);
          },
        ),
        GoRoute(
          path: '/transfer/authenticate',
          builder: (context, state) => const AuthenticateTransferScreen(),
        ),
        GoRoute(
          path: '/transfer/processing',
          builder: (context, state) => ProcessingTransferScreen(
            initialData: state.extra as TransferData?,
          ),
        ),
        GoRoute(
          path: '/transfer/success',
          builder: (context, state) => ProcessingTransferScreen(
            initialData: state.extra as TransferData?,
          ),
        ),
        GoRoute(
          path: '/transfer/receipt',
          builder: (context, state) => ProcessingTransferScreen(
            initialData: state.extra as TransferData?,
          ),
        ),
        ShellRoute(
          builder: (context, state, child) {
            return MainShell(child: child);
          },
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const ProductsScreen(),
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
              name: 'savings-success',
              path: '/savings/success',
              builder: (context, state) {
                final savings = state.extra;
                if (savings is! Savings) {
                  return const SavingsScreen();
                }
                return SavingsSuccessScreen(savings: savings);
              },
            ),
            GoRoute(
              path: '/savings/withdraw',
              builder: (context, state) => const WithdrawalScreen(),
            ),
            GoRoute(
              path: '/savings/transfer',
              builder: (context, state) => const TransferScreen(),
            ),
            GoRoute(
              path: '/savings/:id',
              builder: (context, state) {
                final id = state.pathParameters['id'] ?? 'custom-savings';
                final savings = state.extra;
                return SavingsDetailScreen(
                  savingsId: id,
                  savings: savings is Savings ? savings : null,
                );
              },
            ),
            GoRoute(
              path: '/savings/:id/deposit',
              builder: (context, state) {
                final id = state.pathParameters['id'] ?? 'custom-savings';
                final savings = state.extra;
                return SavingsDepositScreen(
                  savingsId: id,
                  savings: savings is Savings ? savings : null,
                );
              },
            ),
            GoRoute(
              path: '/savings/:id/withdraw',
              builder: (context, state) {
                final id = state.pathParameters['id'] ?? 'custom-savings';
                return WithdrawalScreen(savingsId: id);
              },
              routes: [
                GoRoute(
                  path: 'review',
                  builder: (context, state) {
                    final data = state.extra as WithdrawalData;
                    return ReviewWithdrawalScreen(data: data);
                  },
                ),
                GoRoute(
                  path: 'authenticate',
                  builder: (context, state) {
                    final data = state.extra as WithdrawalData;
                    return AuthenticateWithdrawalScreen(data: data);
                  },
                ),
                GoRoute(
                  path: 'processing',
                  builder: (context, state) {
                    final data = state.extra as WithdrawalData;
                    return ProcessingWithdrawalScreen(data: data);
                  },
                ),
                GoRoute(
                  path: 'success',
                  builder: (context, state) {
                    final data = state.extra as WithdrawalData;
                    return SuccessWithdrawalScreen(data: data);
                  },
                ),
                GoRoute(
                  path: 'receipt',
                  builder: (context, state) {
                    final data = state.extra as WithdrawalData;
                    return ReceiptWithdrawalScreen(data: data);
                  },
                ),
              ],
            ),
            GoRoute(
              path: '/savings/:id/transfer',
              builder: (context, state) => const TransferScreen(),
            ),
            GoRoute(
              path: '/savings/:id/statement',
              builder: (context, state) {
                final id = state.pathParameters['id'] ?? 'custom-savings';
                final savings = state.extra;
                return SavingsDetailScreen(
                  savingsId: id,
                  savings: savings is Savings ? savings : null,
                );
              },
            ),
            GoRoute(
              path: '/savings/:id/edit',
              builder: (context, state) => const CreateSavingsScreen(),
            ),
            GoRoute(
              path: '/pay',
              builder: (context, state) => const PaymentsHubScreen(),
            ),
            GoRoute(
              path: '/activity',
              builder: (context, state) => const TransactionsScreen(),
            ),
            GoRoute(
              path: '/more',
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: '/loans',
              builder: (context, state) => const loans_screen.LoansScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) {
                    final loanId = state.pathParameters['id'];
                    return LoanDetailScreen(loanId: loanId);
                  },
                ),
              ],
            ),
            GoRoute(
              path: '/shares',
              builder: (context, state) => const SharesScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) {
                    final shareId = state.pathParameters['id'];
                    return ShareDetailScreen(shareId: shareId);
                  },
                ),
                GoRoute(
                  path: 'buy',
                  builder: (context, state) => const BuySharesScreen(),
                ),
                GoRoute(
                  path: 'buy/review',
                  builder: (context, state) {
                    final data = state.extra as Map<String, dynamic>;
                    return _ReviewBuySharesScreen(data: data);
                  },
                ),
                GoRoute(
                  path: 'sell',
                  builder: (context, state) => const SellSharesScreen(),
                ),
                GoRoute(
                  path: 'sell/review',
                  builder: (context, state) {
                    final data = state.extra as Map<String, dynamic>;
                    return _ReviewSellSharesScreen(data: data);
                  },
                ),
                GoRoute(
                  path: 'statement',
                  builder: (context, state) => const PortfolioStatementScreen(),
                ),
                GoRoute(
                  path: 'dividends',
                  builder: (context, state) => const DividendHistoryScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    NavigationHistory.instance.attach(configuredRouter);
    return configuredRouter;
  }
}

// Review Screens
class _ReviewBuySharesScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ReviewBuySharesScreen({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Review Purchase',
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              core_app_card.AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Summary',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SummaryRow(
                        label: 'Company',
                        value: data['company'] as String,
                        theme: theme,
                      ),
                      const SizedBox(height: 12),
                      _SummaryRow(
                        label: 'Quantity',
                        value: '${data['quantity']} shares',
                        theme: theme,
                      ),
                      const SizedBox(height: 12),
                      _SummaryRow(
                        label: 'Price per Share',
                        value:
                            'GH₵ ${(data['price'] as double).toStringAsFixed(2)}',
                        theme: theme,
                      ),
                      const SizedBox(height: 16),
                      Divider(color: theme.dividerColor),
                      const SizedBox(height: 16),
                      _SummaryRow(
                        label: 'Total Amount',
                        value:
                            'GH₵ ${(data['total'] as double).toStringAsFixed(2)}',
                        theme: theme,
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Purchase order placed successfully'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (context.mounted) {
                        context.go('/shares');
                      }
                    });
                  },
                  child: const Text('Confirm Purchase'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewSellSharesScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ReviewSellSharesScreen({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Review Sale',
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              core_app_card.AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sale Summary',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SummaryRow(
                        label: 'Company',
                        value: data['company'] as String,
                        theme: theme,
                      ),
                      const SizedBox(height: 12),
                      _SummaryRow(
                        label: 'Quantity',
                        value: '${data['quantity']} shares',
                        theme: theme,
                      ),
                      const SizedBox(height: 12),
                      _SummaryRow(
                        label: 'Price per Share',
                        value:
                            'GH₵ ${(data['price'] as double).toStringAsFixed(2)}',
                        theme: theme,
                      ),
                      const SizedBox(height: 16),
                      Divider(color: theme.dividerColor),
                      const SizedBox(height: 16),
                      _SummaryRow(
                        label: 'Net Proceeds',
                        value:
                            'GH₵ ${(data['proceeds'] as double).toStringAsFixed(2)}',
                        theme: theme,
                        isBold: true,
                        valueColor: Colors.green,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sale order placed successfully'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (context.mounted) {
                        context.go('/shares');
                      }
                    });
                  },
                  child: const Text('Confirm Sale'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final bool isBold;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.theme,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor ?? (isBold ? theme.colorScheme.primary : null),
          ),
        ),
      ],
    );
  }
}
