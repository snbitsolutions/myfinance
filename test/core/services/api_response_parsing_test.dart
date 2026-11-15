import 'package:adepa_teachers/core/models/auth_session.dart';
import 'package:adepa_teachers/core/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('API response parsing', () {
    test('preserves nested data, status and pagination fields', () {
      final service = LoanService();
      final raw = {
        'status': 'success',
        'message': 'ok',
        'pagination': {'page': 1, 'total': 2},
        'data': {
          'loans': [
            {'id': 'L1', 'amount': 100.0},
          ],
          'summary': {'count': 1},
        },
      };

      final normalized = service.normalizeResponsePayload(raw);

      expect(normalized['status'], 'success');
      expect(normalized['message'], 'ok');
      expect(normalized['pagination'], {'page': 1, 'total': 2});
      expect(normalized['loans'], isA<List>());
      expect((normalized['loans'] as List).length, 1);
      expect(normalized['summary'], {'count': 1});
      expect(normalized['data'], isA<Map>());
    });

    test('extractPayload unwraps nested data while keeping metadata available', () {
      final response = {
        'status': 1,
        'data': {
          'data': {
            'token': 'abc123',
            'refresh_token': 'refresh-123',
          },
        },
      };

      final payload = AuthSession.extractPayload(response);
      expect(payload['token'], 'abc123');
      expect(payload['refresh_token'], 'refresh-123');
    });
  });
}
