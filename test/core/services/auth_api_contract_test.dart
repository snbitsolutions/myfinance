import 'package:flutter_test/flutter_test.dart';
import 'package:adepa_teachers/core/constants/app_constants.dart';
import 'package:adepa_teachers/core/models/auth_session.dart';

void main() {
  group('Auth API contract', () {
    test('uses the documented mobileapp-api auth routes', () {
      expect(ApiEndpoints.register, '/mobileapp-api/register');
      expect(ApiEndpoints.confirmPin, '/mobileapp-api/verifyPin');
      expect(ApiEndpoints.setPin, '/mobileapp-api/setPin');
      expect(ApiEndpoints.changePin, '/mobileapp-api/changePin');
    });

    test('uses the public payment-service routes', () {
      expect(
        ApiEndpoints.paymentServiceBaseUrl,
        'https://adepaye.com/api/payment-services',
      );
      expect(ApiEndpoints.initiatePayment, '/api/payment-services/initiate');
      expect(ApiEndpoints.verifyPayment, '/api/payment-services/verify');
    });

    test('keeps a default shared secret for the documented API requests', () {
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

    test('extracts tokens from nested data payloads', () {
      final session = AuthSession.fromResponse({
        'data': {
          'result': {'auth_token': 'abc123', 'refresh_token': 'refresh456'},
        },
      });

      expect(session?.accessToken, 'abc123');
      expect(session?.refreshToken, 'refresh456');
    });
  });
}
