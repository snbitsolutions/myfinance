import 'package:flutter_test/flutter_test.dart';
import 'package:adepa_teachers/core/constants/app_constants.dart';
import 'package:adepa_teachers/core/models/auth_state.dart';
import 'package:adepa_teachers/core/models/auth_session.dart';
import 'package:adepa_teachers/core/services/api_service.dart';

void main() {
  group('Auth API contract', () {
    test('uses the documented mobileapp-api auth routes', () {
      expect(
        ApiEndpoints.register,
        'https://adepaye.com/api/mobileapp-api/register',
      );
      expect(
        ApiEndpoints.confirmAccountNumber,
        'https://adepaye.com/api/mobileapp-api/confirmAccountNumber',
      );
      expect(ApiEndpoints.login, 'https://adepaye.com/api/mobileapp-api/login');
      expect(
        ApiEndpoints.createMember,
        'https://adepaye.com/api/mobileapp-api/create',
      );
      expect(
        ApiEndpoints.confirmPin,
        'https://adepaye.com/api/mobileapp-api/verifyPin',
      );
      expect(
        ApiEndpoints.sendLoginOtp,
        'https://adepaye.com/api/mobileapp-api/sendOtp',
      );
      expect(
        ApiEndpoints.verifyLoginOtp,
        'https://adepaye.com/api/mobileapp-api/verifyOtp',
      );
      expect(
        ApiEndpoints.setPin,
        'https://adepaye.com/api/mobileapp-api/setPin',
      );
      expect(
        ApiEndpoints.changePin,
        'https://adepaye.com/api/mobileapp-api/changePin',
      );
    });

    test('uses the public payment-service routes', () {
      expect(
        ApiEndpoints.paymentServiceBaseUrl,
        'https://adepaye.com/api/payment-services',
      );
      expect(ApiEndpoints.initiatePayment, '/initiate');
      expect(ApiEndpoints.verifyPayment, '/verify');
    });

    test('keeps the documented mobile API defaults for auth requests', () {
      expect(AppConstants.defaultMobileApiSKey, isNotEmpty);
    });

    test('accepts common success status values for OTP verification', () {
      expect(AuthSession.isSuccessStatus(1), isTrue);
      expect(AuthSession.isSuccessStatus(200), isTrue);
      expect(AuthSession.isSuccessStatus('success'), isTrue);
      expect(AuthSession.isSuccessStatus('SUCCESS'), isTrue);
      expect(AuthSession.isSuccessStatus('ok'), isTrue);
      expect(AuthSession.isSuccessStatus(0), isFalse);
    });

    test('treats the documented invalid-PIN login response as a failure', () {
      final service = AuthService();

      expect(
        service.hasExplicitFailure({'status': 0, 'message': 'Invalid Pin'}),
        isTrue,
      );
      expect(
        service.hasExplicitFailure({'status': 1, 'message': 'Valid Pin'}),
        isFalse,
      );
    });

    test('detects legacy empty payloads from STCCU OTP endpoints', () {
      final service = AuthService();
      expect(service.isBackendEmptyPayload(''), isTrue);
      expect(service.isBackendEmptyPayload('""'), isTrue);
      expect(service.normalizeResponsePayload('')['data'], isEmpty);
    });

    test('extracts tokens from nested data payloads', () {
      final session = AuthSession.fromResponse({
        'data': {
          'result': {'auth_token': 'abc123', 'refresh_token': 'refresh456'},
        },
      });

      expect(session?.accessToken, 'abc123');
      expect(session?.refreshToken, 'refresh456');
    });

    test(
      'supports documented verification without an issued session token',
      () {
        final state = AuthState.authenticated(
          userId: '10600000040752',
          userEmail: '233241952608',
        );

        expect(state.isAuthenticated, isTrue);
        expect(state.authToken, isNull);
      },
    );
  });
}
