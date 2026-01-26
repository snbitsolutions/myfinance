import 'package:go_router/go_router.dart';

// Core

// Splash & Onboarding
import '../core/layout/main_shell.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';

// Auth
import '../screens/auth/login_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/auth/set_pin_screen.dart';

// Dashboard Tabs
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/savings/savings_screen.dart';
import '../screens/transactions/transactions_screen.dart';
import '../screens/profile/profile_screen.dart';

// Loans & Savings (non-tab screens)
import '../screens/loans/apply_loan_screen.dart';
import '../screens/loans/loan_detail_screen.dart';
import '../screens/loans/loan_status_screen.dart';
import '../screens/loans/repayment_screen.dart';
// Payments
import '../screens/payment/payment_screen.dart';
import '../screens/payment/payment_success_screen.dart';
import '../screens/payment/payment_failed_screen.dart';
import '../screens/savings/create_savings_screen.dart';
import '../screens/savings/savings_detail_screen.dart';
import '../screens/profile/kyc_screen.dart';
import '../screens/profile/settings_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
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
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/otp', builder: (context, state) => const OtpScreen()),
      GoRoute(
        path: '/set-pin',
        builder: (context, state) => const SetPinScreen(),
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
            builder: (context, state) => const SavingsScreen(),
          ),
          GoRoute(
            path: '/transactions',
            builder: (context, state) => const TransactionsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),

          // Sub-pages (still keep bottom nav)
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
            builder: (context, state) => const PaymentScreen(),
          ),
          GoRoute(
            path: '/payment-success',
            builder: (context, state) => const PaymentSuccessScreen(),
          ),
          GoRoute(
            path: '/payment-failed',
            builder: (context, state) => const PaymentFailedScreen(),
          ),
          GoRoute(
            path: '/savings/create',
            builder: (context, state) => const CreateSavingsScreen(),
          ),
          GoRoute(
            path: '/savings/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return SavingsDetailScreen(savingsId: id);
            },
          ),
          GoRoute(path: '/kyc', builder: (context, state) => const KycScreen()),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}
