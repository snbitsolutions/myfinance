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
    adapter = _LoginResponseAdapter('{"status":1,"message":"Valid Password"}');
    dio.httpClientAdapter = adapter;
  });

  tearDown(() {
    dio.httpClientAdapter = originalAdapter;
  });

  test(
    'posts the login password as a string and accepts a valid response',
    () async {
      final result = await AuthService().login(
        phoneNumber: '0241234567',
        password: 'account-pass-1040',
        imeiNumber: 100200300,
      );

      final request = adapter.request!;
      final body = request.data as Map<String, dynamic>;
      expect(request.method, 'POST');
      expect(request.uri.path, endsWith('/login'));
      expect(request.contentType, Headers.jsonContentType);
      expect(body['phone_number'], 233241234567);
      expect(body['password'], 'account-pass-1040');
      expect(body['s_key'], isNotEmpty);
      expect(body['imei_number'], 100200300);
      expect(body.containsKey('device_id'), isFalse);
      expect(body.containsKey('device_fingerprint'), isFalse);
      expect(result['status'], 1);
      expect(result['message'], 'Valid Password');
    },
  );

  test('preserves leading zeros in numeric-looking login passwords', () async {
    await AuthService().login(
      phoneNumber: '0241234567',
      password: '00123456',
      imeiNumber: 100200300,
    );

    final body = adapter.request!.data as Map<String, dynamic>;
    expect(body['password'], '00123456');
  });

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

  test(
    'verifies a linked member PIN with the account verification endpoint',
    () async {
      final result = await AuthService().confirmPin(
        phoneNumber: '233241234567',
        accountNumber: '0010100000144795',
        pin: '0104',
      );

      final request = adapter.request!;
      final body = request.data as Map<String, dynamic>;
      expect(request.method, 'POST');
      expect(request.uri.path, endsWith('/verifyPin'));
      expect(body['phone_number'], '233241234567');
      expect(body['account_number'], '0010100000144795');
      expect(body['pin'], '0104');
      expect(body['s_key'], isNotEmpty);
      expect(result['status'], 1);
    },
  );
}
