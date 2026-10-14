import 'dart:typed_data';

import 'package:adepa_teachers/core/exceptions/app_exceptions.dart';
import 'package:adepa_teachers/core/services/api_service.dart';
import 'package:adepa_teachers/core/services/http_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _LoanApplicationResponseAdapter implements HttpClientAdapter {
  _LoanApplicationResponseAdapter(this.body);

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
  late _LoanApplicationResponseAdapter adapter;

  setUp(() {
    dio = HttpClient.instance.dio;
    originalAdapter = dio.httpClientAdapter;
    adapter = _LoanApplicationResponseAdapter(
      '{"status":1,"message":"Application received","application_id":"APP-123"}',
    );
    dio.httpClientAdapter = adapter;
  });

  tearDown(() {
    dio.httpClientAdapter = originalAdapter;
  });

  test('posts the documented loan application payload', () async {
    final result = await LoanService().applyLoan(
      accountNumber: '0010600000040752',
      amount: 1000,
      purpose: 'Building Materials',
      imeiNumber: 100000000000001,
    );

    final request = adapter.request!;
    final body = request.data as Map<String, dynamic>;
    expect(request.method, 'POST');
    expect(request.uri.path, endsWith('/loanApplication'));
    expect(request.contentType, Headers.jsonContentType);
    expect(body, {
      'account_number': '0010600000040752',
      'product_id': 1,
      'amount': 1000,
      'purpose': 'Building Materials',
      'imei_number': 100000000000001,
      's_key': isNotEmpty,
    });
    expect(result['status'], 'success');
    expect(result['message'], 'Application received');
    expect(
      (result['data'] as Map<String, dynamic>)['application_id'],
      'APP-123',
    );
  });

  test('reports an explicit backend rejection', () async {
    adapter = _LoanApplicationResponseAdapter(
      '{"status":0,"message":"Loan product unavailable"}',
    );
    dio.httpClientAdapter = adapter;

    await expectLater(
      LoanService().applyLoan(
        accountNumber: '0010600000040752',
        amount: 1000,
        purpose: 'Building Materials',
        imeiNumber: 100000000000001,
      ),
      throwsA(
        isA<GenericException>().having(
          (error) => error.message,
          'message',
          'Loan product unavailable',
        ),
      ),
    );
  });
}
