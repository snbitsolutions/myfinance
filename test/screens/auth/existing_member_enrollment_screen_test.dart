import 'package:adepa_teachers/core/exceptions/app_exceptions.dart';
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
  String? confirmedPhoneNumber;
  String? confirmedAccountNumber;
  String? confirmedBirthDate;
  int? registrationDeviceNumber;
  String? registrationPhoneMake;

  @override
  Future<Map<String, dynamic>> register({
    required String accountNumber,
    required String phoneNumber,
    required String birthDate,
    String? password,
    String? pin,
    String? transactionPin,
    required int imeiNumber,
    required String phoneMake,
  }) async {
    registration = {
      'accountNumber': accountNumber,
      'phoneNumber': phoneNumber,
      'birthDate': birthDate,
      'password': password,
      'pin': pin,
      'transactionPin': transactionPin,
      'imeiNumber': imeiNumber,
      'phoneMake': phoneMake,
    };
    registrationDeviceNumber = imeiNumber;
    registrationPhoneMake = phoneMake;
    return {'status': 1, 'message': 'Enrollment accepted'};
  }

  @override
  Future<void> confirmAccountNumber({
    required String phoneNumber,
    required String accountNumber,
    required String birthDate,
  }) async {
    confirmedPhoneNumber = phoneNumber;
    confirmedAccountNumber = accountNumber;
    confirmedBirthDate = birthDate;
    if (birthDate != '1989-10-07') {
      throw AuthException(message: 'Member details do not match.');
    }
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
  Future<int> getBackendDeviceNumber() async => 123456789012345;

  @override
  Future<String> getBackendDeviceMake() async => 'Apple iPhone 17 Pro';
}

Future<void> _selectBirthDate(
  WidgetTester tester,
  Finder field, {
  String date = '10/07/1989',
}) async {
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Switch to input'));
  await tester.pumpAndSettle();

  final datePicker = find.byType(DatePickerDialog);
  final dateInput = find.descendant(
    of: datePicker,
    matching: find.byType(TextField),
  );
  await tester.enterText(dateInput, date);
  await tester.tap(find.descendant(of: datePicker, matching: find.text('OK')));
  await tester.pumpAndSettle();
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

  testWidgets('normalizes member type casing for the enrollment flow', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ExistingMemberEnrollmentScreen(memberType: ' NEW '),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('New member registration'), findsOneWidget);
    expect(find.text('Existing member registration'), findsNothing);
  });

  testWidgets('requires valid Ghana Card and picks birth date from calendar', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/enrollment',
      routes: [
        GoRoute(
          path: '/enrollment',
          builder: (context, state) =>
              const ExistingMemberEnrollmentScreen(memberType: 'new'),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            (ref) => AuthNotifier(
              authService: _EnrollmentAuthService(),
              userService: UserService(),
              deviceIdentityService: _EnrollmentDeviceIdentityService(),
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final fullNameField = find.byKey(const ValueKey('new-member-full-name'));
    final phoneField = find.byKey(const ValueKey('new-member-phone-number'));
    await tester.enterText(fullNameField, 'Test Member');
    await tester.enterText(phoneField, '0241234567');
    expect(
      tester.widget<TextField>(fullNameField).controller!.text,
      'Test Member',
    );
    expect(tester.widget<TextField>(phoneField).controller!.text, '0241234567');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Verify Identity (KYC)'), findsOneWidget);

    final ghanaCardField = find.byKey(const ValueKey('ghana-card-number'));
    final birthDateField = find.byKey(
      const ValueKey('new-member-date-of-birth'),
    );
    await tester.enterText(ghanaCardField, '123456789');
    expect(
      tester.widget<TextField>(ghanaCardField).controller!.text,
      'GHA-123456789',
    );
    expect(tester.widget<TextField>(birthDateField).readOnly, isTrue);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pump();
    expect(
      find.text(
        'Enter a valid Ghana Card number in the format GHA-XXXXXXXXX-X.',
      ),
      findsOneWidget,
    );
    expect(find.text('Verify Identity (KYC)'), findsOneWidget);

    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
        .hideCurrentSnackBar();
    await tester.pumpAndSettle();
    await tester.enterText(ghanaCardField, '1234567890');
    await _selectBirthDate(tester, birthDateField);
    expect(
      tester.widget<TextField>(ghanaCardField).controller!.text,
      'GHA-123456789-0',
    );
    expect(
      tester.widget<TextField>(birthDateField).controller!.text,
      '1989-10-07',
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Additional Information'), findsNWidgets(2));
  });

  testWidgets('existing-member flow verifies before registering', (
    tester,
  ) async {
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
    await tester.enterText(membershipFields.at(0), '0010 6000-0004 0752');
    await tester.enterText(membershipFields.at(1), '02412345');
    await _selectBirthDate(tester, membershipFields.at(2));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Verify Membership'), findsNWidgets(2));
    expect(
      find.text(
        'Enter the registered Ghana phone number as 0XXXXXXXXX or '
        '233XXXXXXXXX.',
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.enterText(membershipFields.at(1), '0241234567');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Create Login Credentials'), findsNWidgets(2));
    expect(authService.confirmedPhoneNumber, '0241234567');
    expect(authService.confirmedAccountNumber, '0010600000040752');
    expect(authService.confirmedBirthDate, '1989-10-07');
    expect(find.text('Username'), findsNothing);
    final credentialFields = find.byType(TextField);
    expect(
      tester.widget<TextField>(credentialFields.at(0)).obscureText,
      isTrue,
    );
    expect(
      tester.widget<TextField>(credentialFields.at(1)).obscureText,
      isTrue,
    );
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(
      tester.widget<TextField>(credentialFields.at(0)).obscureText,
      isFalse,
    );
    expect(
      tester.widget<TextField>(credentialFields.at(1)).obscureText,
      isTrue,
    );
    await tester.tap(find.byTooltip('Hide password'));
    await tester.pump();
    await tester.tap(find.byTooltip('Show confirmation password'));
    await tester.pump();
    expect(
      tester.widget<TextField>(credentialFields.at(0)).obscureText,
      isTrue,
    );
    expect(
      tester.widget<TextField>(credentialFields.at(1)).obscureText,
      isFalse,
    );
    await tester.tap(find.byTooltip('Hide confirmation password'));
    await tester.pump();
    await tester.enterText(credentialFields.at(0), 'member-pass-123');
    await tester.enterText(credentialFields.at(1), 'member-pass-123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();

    final pinFields = find.byType(TextField);
    expect(find.text('Set Transfer PIN'), findsNWidgets(2));
    expect(find.text('Set App & Transfer PINs'), findsNothing);
    expect(find.text('App PIN'), findsNothing);
    await tester.enterText(pinFields.at(0), '1357');
    await tester.enterText(pinFields.at(1), '1357');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Review & Confirm'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm & Continue'));
    await tester.pumpAndSettle();
    expect(find.text('OTP verification'), findsOneWidget);
    expect(find.text('OTP verification'), findsOneWidget);
    expect(find.text('Set Transaction PIN'), findsNothing);
    expect(authService.registration?['password'], 'member-pass-123');
    expect(authService.registration?['pin'], isNull);
    expect(authService.registration?['transactionPin'], '1357');
    expect(authService.registrationDeviceNumber, 123456789012345);
    expect(authService.registrationPhoneMake, 'Apple iPhone 17 Pro');
    expect(authService.otpPhoneNumber, '0241234567');
    expect(authService.otpAccountNumber, '0010600000040752');
    expect(otpRouteExtra?['isRegistration'], isTrue);
    expect(otpRouteExtra?['transactionPin'], isNull);
    expect(otpRouteExtra?['transactionPinAlreadyProvisioned'], isTrue);
    expect(otpRouteExtra?['requiresPinSetup'], isFalse);
    expect(find.text('Verify Identity (OTP)'), findsNothing);
    expect(find.text('Verify Final Authentication'), findsNothing);
  });

  testWidgets('wrong birth date does not show credentials', (tester) async {
    final authService = _EnrollmentAuthService();
    final router = GoRouter(
      initialLocation: '/existing-member-enrollment',
      routes: [
        GoRoute(
          path: '/existing-member-enrollment',
          builder: (context, state) => const ExistingMemberEnrollmentScreen(),
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
              deviceIdentityService: _EnrollmentDeviceIdentityService(),
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();
    final membershipFields = find.byType(TextField);
    await tester.enterText(membershipFields.at(0), '0010600000040752');
    await tester.enterText(membershipFields.at(1), '0241234567');
    await _selectBirthDate(tester, membershipFields.at(2), date: '10/08/1989');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Member details do not match.'), findsOneWidget);
    expect(find.text('Verify Membership'), findsNWidgets(2));
    expect(find.text('Create Login Credentials'), findsNothing);
  });
}
