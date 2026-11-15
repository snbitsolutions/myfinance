import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:adepa_teachers/core/models/auth_state.dart';
import 'package:adepa_teachers/core/providers/app_providers.dart';
import 'package:adepa_teachers/core/services/api_service.dart';
import 'package:adepa_teachers/core/services/device_identity_service.dart';
import 'package:adepa_teachers/screens/loans/apply_loan_screen.dart';

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier()
    : super(
        authService: AuthService(),
        userService: UserService(),
        deviceIdentityService: DeviceIdentityService(),
      ) {
    state = AuthState.authenticated(
      userId: '0010600000040752',
      userEmail: 'member@example.com',
    );
  }
}

class _TestDeviceIdentityService extends DeviceIdentityService {
  @override
  Future<int> getBackendDeviceNumber() async => 100000000000001;
}

class _LoanServiceStub extends LoanService {
  String? accountNumber;
  double? amount;
  String? purpose;

  @override
  Future<Map<String, dynamic>> applyLoan({
    required String accountNumber,
    required double amount,
    required String purpose,
    required int imeiNumber,
    int productId = 1,
  }) async {
    this.accountNumber = accountNumber;
    this.amount = amount;
    this.purpose = purpose;
    return {
      'status': 'success',
      'message': 'Application received',
      'data': const <String, dynamic>{},
    };
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('submits valid loan application and navigates to status', (
    tester,
  ) async {
    final loanService = _LoanServiceStub();
    final router = GoRouter(
      initialLocation: '/apply-loan',
      routes: [
        GoRoute(
          path: '/apply-loan',
          builder: (context, state) => const ApplyLoanScreen(),
        ),
        GoRoute(
          path: '/loan-status',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Loan Status Placeholder')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _TestAuthNotifier()),
          deviceIdentityServiceProvider.overrideWithValue(
            _TestDeviceIdentityService(),
          ),
          loanServiceProvider.overrideWithValue(loanService),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final amountField = find.widgetWithText(
      TextField,
      'e.g., 1,000 (Ghana cedis)',
    );
    final purposeField = find.widgetWithText(
      TextField,
      'e.g., school fees, rent, business stock',
    );

    expect(amountField, findsOneWidget);
    expect(purposeField, findsOneWidget);

    await tester.enterText(amountField, '2500');
    await tester.enterText(purposeField, 'Business expansion');
    await tester.pumpAndSettle();

    final submitButton = find.widgetWithText(
      ElevatedButton,
      'Submit Application',
    );
    expect(submitButton, findsOneWidget);
    final onPressed = tester.widget<ElevatedButton>(submitButton).onPressed;
    expect(onPressed, isNotNull);

    onPressed!();
    await tester.pumpAndSettle();

    expect(find.text('Loan Status Placeholder'), findsOneWidget);
    expect(loanService.accountNumber, '0010600000040752');
    expect(loanService.amount, 2500);
    expect(loanService.purpose, 'Business expansion');
  });
}
