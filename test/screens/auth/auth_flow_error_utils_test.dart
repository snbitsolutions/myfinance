import 'package:adepa_teachers/screens/auth/auth_flow_error_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldRedirectToSignup', () {
    test('redirects account-specific not-found errors', () {
      expect(shouldRedirectToSignup('Account not found.'), isTrue);
      expect(shouldRedirectToSignup('Member not found.'), isTrue);
      expect(shouldRedirectToSignup('Phone number not found.'), isTrue);
    });

    test('does not redirect generic resource-not-found errors', () {
      expect(shouldRedirectToSignup('Resource not found.'), isFalse);
    });
  });
}
