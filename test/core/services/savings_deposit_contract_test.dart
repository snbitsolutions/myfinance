import 'dart:typed_data';

import 'package:adepa_teachers/core/services/api_service.dart';
import 'package:adepa_teachers/core/services/http_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _DepositResponseAdapter implements HttpClientAdapter {
  _DepositResponseAdapter(this.body);

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
  late _DepositResponseAdapter adapter;

  setUp(() {
    dio = HttpClient.paymentInstance.dio;
    originalAdapter = dio.httpClientAdapter;
    adapter = _DepositResponseAdapter(
      '{"status":1,"transaction_id":"deposit-123"}',
    );
    dio.httpClientAdapter = adapter;
  });

  tearDown(() {
    dio.httpClientAdapter = originalAdapter;
  });

  test(
    'sends the documented JSON savings deposit and returns its reference',
    () async {
      final result = await SavingsService().depositSavings(
        phoneNumber: '233241234567',
        channel: 'mtn-gh',
        amount: 12.5,
        savingsId: '59656',
        username: 'Test Member',
      );

      final request = adapter.request!;
      final body = request.data as Map<String, dynamic>;
      expect(request.method, 'POST');
      expect(request.uri.path, endsWith('/deposit'));
      expect(request.contentType, Headers.jsonContentType);
      expect(body['phone_number'], '233241234567');
      expect(body['channel'], 'mtn-gh');
      expect(body['amount'], 12.5);
      expect(body['description'], 'Edeposit');
      expect(body['product_id'], '59656');
      expect(body['username'], 'Test Member');
      expect(body['s_key'], isNotEmpty);
      expect(body['ExternalTransactionId'], isNotEmpty);
      expect(body['ClientReference'], startsWith('ATCCU-'));
      expect(body.containsKey('pin'), isFalse);
      expect(body.containsKey('account_number'), isFalse);
      expect(result['transaction_id'], 'deposit-123');
      expect(result['is_pending'], isNull);
    },
  );

  test(
    'treats a successful empty response as pending, not confirmed',
    () async {
      adapter = _DepositResponseAdapter('');
      dio.httpClientAdapter = adapter;

      final result = await SavingsService().depositSavings(
        phoneNumber: '233241234567',
        amount: 12.5,
        savingsId: '59656',
      );

      expect(result['status'], 'success');
      expect(result['is_pending'], isTrue);
      expect(result['transaction_id'], isNotEmpty);
      expect(result['reference'], result['transaction_id']);
    },
  );

  test(
    'sends documented airtime payload and reports empty response pending',
    () async {
      adapter = _DepositResponseAdapter('');
      dio.httpClientAdapter = adapter;

      final result = await PaymentService().buyAirtime(
        phoneNumber: '233241234567',
        channel: 'mtn-gh',
        amount: 10,
        username: 'Test Member',
        productId: '59656',
      );

      final request = adapter.request!;
      final body = request.data as Map<String, dynamic>;
      expect(request.method, 'POST');
      expect(request.uri.path, endsWith('/deposit'));
      expect(request.contentType, Headers.jsonContentType);
      expect(body['phone_number'], '233241234567');
      expect(body['channel'], 'mtn-gh');
      expect(body['amount'], 10);
      expect(body['description'], 'Edeposit');
      expect(body['email'], '');
      expect(body['username'], 'Test Member');
      expect(body['product_id'], '59656');
      expect(body['s_key'], isNotEmpty);
      expect(result['status'], 'success');
      expect(result['is_pending'], isTrue);
    },
  );
}
