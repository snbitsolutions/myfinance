import 'dart:typed_data';

import 'package:adepa_teachers/core/exceptions/app_exceptions.dart';
import 'package:adepa_teachers/core/services/api_service.dart';
import 'package:adepa_teachers/core/services/http_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _PinChangeResponseAdapter implements HttpClientAdapter {
  _PinChangeResponseAdapter(this.body);

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
  late _PinChangeResponseAdapter adapter;

  setUp(() {
    dio = HttpClient.instance.dio;
    originalAdapter = dio.httpClientAdapter;
    adapter = _PinChangeResponseAdapter(
      '{"status":1,"message":"Pin changed successfully"}',
    );
    dio.httpClientAdapter = adapter;
  });

  tearDown(() {
    dio.httpClientAdapter = originalAdapter;
  });

  test(
    'sends four-digit PIN values to the documented changePin route',
    () async {
      await AuthService().changePin(
        accountNumber: '0010100000144795',
        currentPin: '0123',
        newPin: '0456',
        imeiNumber: 100000000000001,
      );

      final request = adapter.request!;
      final body = request.data as Map<String, dynamic>;
      expect(request.method, 'POST');
      expect(request.uri.path, endsWith('/changePin'));
      expect(body['current_pin'], 123);
      expect(body['new_pin'], 456);
      expect(body['account_number'], 10100000144795);
      expect(body['imei_number'], 100000000000001);
      expect(body['s_key'], isNotEmpty);
    },
  );

  test('rejects non-numeric PINs before making a request', () async {
    await expectLater(
      AuthService().changePin(
        accountNumber: '0010100000144795',
        currentPin: 'a123',
        newPin: '0456',
        imeiNumber: 100000000000001,
      ),
      throwsA(isA<ValidationException>()),
    );

    expect(adapter.request, isNull);
  });
}
