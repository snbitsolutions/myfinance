import 'dart:typed_data';

import 'package:adepa_teachers/core/services/api_service.dart';
import 'package:adepa_teachers/core/services/http_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _ResetResponseAdapter implements HttpClientAdapter {
  _ResetResponseAdapter(this.body);

  final String body;
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late HttpClientAdapter originalAdapter;
  late _ResetResponseAdapter adapter;

  setUp(() {
    dio = HttpClient.instance.dio;
    originalAdapter = dio.httpClientAdapter;
  });

  tearDown(() {
    dio.httpClientAdapter = originalAdapter;
  });

  test(
    'requests a reset code with account number string and device number',
    () async {
      adapter = _ResetResponseAdapter(
        '{"status":1,"request_id":"reset-123","message":"Code sent"}',
      );
      dio.httpClientAdapter = adapter;

      await AuthService().requestPasswordReset(
        accountNumber: '0010600000040752',
        imeiNumber: 114797038167467,
      );

      final request = adapter.request!;
      final body = request.data as Map<String, dynamic>;
      expect(request.method, 'POST');
      expect(request.uri.path, endsWith('/requestPasswordReset'));
      expect(body['account_number'], '0010600000040752');
      expect(body['imei_number'], 114797038167467);
      expect(body['s_key'], isNotEmpty);
    },
  );

  test('uses the documented password-reset endpoint and payload', () async {
    adapter = _ResetResponseAdapter('{"status":1,"message":"Password reset"}');
    dio.httpClientAdapter = adapter;

    await AuthService().passwordReset(
      requestId: 'reset-123',
      newPassword: 'new-password-123',
      imeiNumber: 114797038167467,
    );

    final request = adapter.request!;
    final body = request.data as Map<String, dynamic>;
    expect(request.method, 'POST');
    expect(request.uri.path, endsWith('/passwordRest'));
    expect(body['imei_number'], 114797038167467);
    expect(body['password'], 'new-password-123');
    expect(body['request_id'], 'reset-123');
    expect(body['s_key'], isNotEmpty);
  });
}
