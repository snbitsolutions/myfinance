import 'dart:typed_data';

import 'package:adepa_teachers/core/services/api_service.dart';
import 'package:adepa_teachers/core/services/http_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _LoginResponseAdapter implements HttpClientAdapter {
  _LoginResponseAdapter(this.body);

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
  late _LoginResponseAdapter adapter;

  setUp(() {
    dio = HttpClient.instance.dio;
    originalAdapter = dio.httpClientAdapter;
    adapter = _LoginResponseAdapter('{"status":1,"message":"Valid Pin"}');
    dio.httpClientAdapter = adapter;
  });

  tearDown(() {
    dio.httpClientAdapter = originalAdapter;
  });

  test(
    'posts the documented login payload and accepts valid PIN response',
    () async {
      final result = await AuthService().login(
        phoneNumber: '0241234567',
        pin: '1040',
        imeiNumber: 100200300,
      );

      final request = adapter.request!;
      final body = request.data as Map<String, dynamic>;
      expect(request.method, 'POST');
      expect(request.uri.path, endsWith('/login'));
      expect(request.contentType, Headers.jsonContentType);
      expect(body['phone_number'], 233241234567);
      expect(body['password'], 1040);
      expect(body['s_key'], isNotEmpty);
      expect(body['imei_number'], 100200300);
      expect(body.containsKey('device_id'), isFalse);
      expect(body.containsKey('device_fingerprint'), isFalse);
      expect(result['status'], 1);
      expect(result['message'], 'Valid Pin');
    },
  );

  test('includes the device binding in phone and PIN login requests', () async {
    await AuthService().loginWithPhonePin(
      phoneNumber: '0241234567',
      pin: '1040',
      imeiNumber: 100200300,
    );

    final body = adapter.request!.data as Map<String, dynamic>;
    expect(body['imei_number'], 100200300);
    expect(body.containsKey('device_id'), isFalse);
    expect(body.containsKey('device_fingerprint'), isFalse);
  });
}
