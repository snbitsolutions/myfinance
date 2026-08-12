import 'package:adepa_teachers/core/models/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthSession.fromResponse', () {
    test('reads server-issued tokens from the response body', () {
      final session = AuthSession.fromResponse({
        'access_token': 'access-token',
        'refresh_token': 'refresh-token',
      });

      expect(session?.accessToken, 'access-token');
      expect(session?.refreshToken, 'refresh-token');
    });

    test('reads server-issued tokens from a nested data payload', () {
      final session = AuthSession.fromResponse({
        'data': {'auth_token': 'access-token'},
      });

      expect(session?.accessToken, 'access-token');
      expect(session?.refreshToken, isNull);
    });

    test('extracts the inner payload from service-style envelopes', () {
      final payload = AuthSession.extractPayload({
        'status': 'success',
        'data': {'user_id': '12345', 'name': 'Ada Lovelace'},
      });

      expect(payload['user_id'], '12345');
      expect(payload['name'], 'Ada Lovelace');
    });

    test('does not create a session when the server did not issue a token', () {
      expect(AuthSession.fromResponse({'status': 1}), isNull);
    });
  });
}
