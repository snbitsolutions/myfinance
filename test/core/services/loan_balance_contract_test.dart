import 'dart:typed_data';

import 'package:adepa_teachers/core/services/api_service.dart';
import 'package:adepa_teachers/core/services/http_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _LoanBalanceResponseAdapter implements HttpClientAdapter {
  _LoanBalanceResponseAdapter(this.body);

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
  late _LoanBalanceResponseAdapter adapter;

  setUp(() {
    dio = HttpClient.instance.dio;
    originalAdapter = dio.httpClientAdapter;
    adapter = _LoanBalanceResponseAdapter(
      '{"status":1,"outstanding_balance":"1250.75"}',
    );
    dio.httpClientAdapter = adapter;
  });

  tearDown(() {
    dio.httpClientAdapter = originalAdapter;
  });

  test(
    'posts member and loan identifiers and parses outstanding balance',
    () async {
      final result = await LoanService().getLoanBalance(
        accountNumber: '0010100000144795',
        loanId: 'loan-123',
      );

      final request = adapter.request!;
      final body = request.data as Map<String, dynamic>;
      expect(request.method, 'POST');
      expect(request.uri.path, endsWith('/getLoanBalance'));
      expect(request.contentType, Headers.jsonContentType);
      expect(body['account_number'], '0010100000144795');
      expect(body['loan_id'], 'loan-123');
      expect(body['s_key'], isNotEmpty);
      expect(result['status'], 'success');
      expect(result['balance'], 1250.75);
    },
  );

  test(
    'returns a null balance when successful response omits balance fields',
    () async {
      adapter = _LoanBalanceResponseAdapter('{"status":1,"message":"OK"}');
      dio.httpClientAdapter = adapter;

      final result = await LoanService().getLoanBalance(
        accountNumber: '0010100000144795',
      );

      expect(result['status'], 'success');
      expect(result['balance'], isNull);
      expect(
        (adapter.request!.data as Map<String, dynamic>).containsKey('loan_id'),
        isFalse,
      );
    },
  );
}
