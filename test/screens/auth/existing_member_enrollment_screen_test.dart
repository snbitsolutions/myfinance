import 'package:adepa_teachers/core/providers/app_providers.dart';
import 'package:adepa_teachers/core/services/api_service.dart';
import 'package:adepa_teachers/core/services/device_identity_service.dart';
import 'package:adepa_teachers/screens/auth/existing_member_enrollment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _EnrollmentAuthService extends AuthService {
  Map<String, Object?>? registration;
  String? otpPhoneNumber;
  String? otpAccountNumber;

  @override
  Future<Map<String, dynamic>> register({
    required String accountNumber,
    required String phoneNumber,
    required String birthDate,
    String? password,
    String? transactionPin,
    required int imeiNumber,
    required String phoneMake,
  }) async {
    registration = {
      'accountNumber': accountNumber,
      'phoneNumber': phoneNumber,
      'birthDate': birthDate,
      'password': password,
      'transactionPin': transactionPin,
    };
    return {'status': 1, 'message': 'Enrollment accepted'};
  }

  @override
  Future<void> sendLoginOtp({
    required String phoneNumber,
    required String accountNumber,
  }) async {
    otpPhoneNumber = phoneNumber;
    otpAccountNumber = accountNumber;
  }
}

class _EnrollmentDeviceIdentityService extends DeviceIdentityService {
  @override
  Future<int> getBackendDeviceNumber() async => 100200300;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
          switch (call.method) {
            case 'read':
              return null;
            case 'readAll':
              return <String, String>{};
            case 'containsKey':
              return false;
            case 'write':
            case 'delete':
            case 'deleteAll':
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

  testWidgets(
    'existing-member enrollment sends password and PIN before OTP',
    (tester) async {
      final authService = _EnrollmentAuthService();
      final deviceIdentityService = _EnrollmentDeviceIdentityService();
      Map<String, dynamic>? otpRouteExtra;
      final router = GoRouter(
        initialLocation: '/existing-member-enrollment',
        routes: [
          GoRoute(
            path: '/existing-member-enrollment',
            builder: (context, state) => const ExistingMemberEnrollmentScreen(),
          ),
          GoRoute(
            path: '/otp',
            builder: (context, state) {
              otpRouteExtra = state.extra as Map<String, dynamic>?;
              return const Scaffold(body: Text('OTP verification'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (ref) => AuthNotifier(
                authService: authService,
                userService: UserService(),
                deviceIdentityService: deviceIdentityService,
              ),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Activate mobile banking'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Verify Membership'), findsNWidgets(2));
      final membershipFields = find.byType(TextField);
      await tester.enterText(membershipFields.at(0), '0010600000040752');
      await tester.enterText(membershipFields.at(1), '0241234567');
      await tester.enterText(membershipFields.at(2), '1989-10-07');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Create Login Credentials'), findsNWidgets(2));
      expect(find.text('Username'), findsNothing);
      final credentialFields = find.byType(TextField);
      await tester.enterText(credentialFields.at(0), 'member-pass-123');
      await tester.enterText(credentialFields.at(1), 'member-pass-123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      final pinFields = find.byType(TextField);
      await tester.enterText(pinFields.at(0), '2468');
      await tester.enterText(pinFields.at(1), '2468');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Review & Confirm'), findsOneWidget);
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Confirm & Continue'),
      );
      await tester.pumpAndSettle();

      expect(find.text('OTP verification'), findsOneWidget);
      expect(authService.registration?['password'], 'member-pass-123');
      expect(authService.registration?['transactionPin'], '2468');
      expect(authService.otpPhoneNumber, '0241234567');
      expect(authService.otpAccountNumber, '0010600000040752');
      expect(otpRouteExtra?['isRegistration'], isTrue);
      expect(otpRouteExtra?['transactionPin'], '2468');
      expect(otpRouteExtra?['transactionPinAlreadyProvisioned'], isTrue);
      expect(find.text('Verify Identity (OTP)'), findsNothing);
      expect(find.text('Verify Final Authentication'), findsNothing);
    },
  );
}
