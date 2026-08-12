import 'package:flutter_test/flutter_test.dart';
import 'package:adepa_teachers/core/models/auth_session.dart';

void main() {
  group('AuthSession', () {
    test('extracts nested access and refresh tokens from session payload', () {
      final session = AuthSession.fromResponse({
        'status': 1,
        'data': {
          'session': {
            'accessToken': 'access-123',
            'refreshToken': 'refresh-456',
          },
        },
      });

      expect(session?.accessToken, 'access-123');
      expect(session?.refreshToken, 'refresh-456');
    });
  });
}
