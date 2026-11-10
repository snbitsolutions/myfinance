import 'dart:typed_data';

import 'package:adepa_teachers/core/services/api_service.dart';
import 'package:adepa_teachers/core/services/http_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _StatementResponseAdapter implements HttpClientAdapter {
  _StatementResponseAdapter(this.body);

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
  late _StatementResponseAdapter adapter;

  setUp(() {
    dio = HttpClient.instance.dio;
    originalAdapter = dio.httpClientAdapter;
    adapter = _StatementResponseAdapter(
      '{"status":1,"transactions":[{"trans_id":"ATCCU-123",'
      '"description":"Mobile App Deposit","amount":"2.00",'
      '"trans_type":"Deposit","entry_date":"2026-10-27"}]}',
    );
    dio.httpClientAdapter = adapter;
  });

  tearDown(() {
    dio.httpClientAdapter = originalAdapter;
  });

  test('posts product ID and parses the savings statement response', () async {
    final transactions = await TransactionService().getProductStatement(
      productId: '59656',
    );

    final request = adapter.request!;
    expect(request.method, 'POST');
    expect(request.uri.path, endsWith('/savingsStatement'));
    expect(request.contentType, Headers.jsonContentType);
    expect(request.data, {'product_id': 59656, 's_key': isNotEmpty});
    expect(transactions, hasLength(1));
    expect(transactions.single['transaction_id'], 'ATCCU-123');
    expect(transactions.single['description'], 'Mobile App Deposit');
    expect(transactions.single['amount'], 2.0);
    expect(transactions.single['type'], 'Deposit');
    expect(transactions.single['date'], '2026-10-27');
  });

  test(
    'returns an empty list when a successful response has no transactions',
    () async {
      adapter = _StatementResponseAdapter('{"status":1,"transactions":[]}');
      dio.httpClientAdapter = adapter;

      final transactions = await TransactionService().getProductStatement(
        productId: '59656',
      );

      expect(transactions, isEmpty);
    },
  );
}
