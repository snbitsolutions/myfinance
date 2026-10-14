import 'dart:typed_data';

import 'package:adepa_teachers/core/services/api_service.dart';
import 'package:adepa_teachers/core/services/http_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _SharesResponseAdapter implements HttpClientAdapter {
  _SharesResponseAdapter(this.body);

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
  late _SharesResponseAdapter adapter;

  setUp(() {
    dio = HttpClient.instance.dio;
    originalAdapter = dio.httpClientAdapter;
    adapter = _SharesResponseAdapter(
      '{"status":1,"shares":[{"id":"share-4","name":"Ordinary Shares","shares_owned":"12"}]}',
    );
    dio.httpClientAdapter = adapter;
  });

  tearDown(() {
    dio.httpClientAdapter = originalAdapter;
  });

  test(
    'requests member shares and returns the documented holdings payload',
    () async {
      final result = await SharesService().getShares(
        phoneNumber: '0241234567',
        accountNumber: '0010100000144795',
        pin: '1234',
        imeiNumber: 100000000000001,
      );

      final request = adapter.request!;
      final body = request.data as Map<String, dynamic>;
      expect(request.method, 'POST');
      expect(request.uri.path, endsWith('/getMemShares'));
      expect(request.contentType, Headers.jsonContentType);
      expect(body['account_number'], '0010100000144795');
      expect(body['imei_number'], 100000000000001);
      expect(body['s_key'], isNotEmpty);
      expect(body.containsKey('pin'), isFalse);
      expect(result['status'], 'success');
      expect(result['data'], [
        {'id': 'share-4', 'name': 'Ordinary Shares', 'shares_owned': '12'},
      ]);
    },
  );
}
