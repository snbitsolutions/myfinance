import 'dart:typed_data';

import 'package:adepa_teachers/core/exceptions/app_exceptions.dart';
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
  late Dio savingsDio;
  late HttpClientAdapter originalAdapter;
  late HttpClientAdapter originalSavingsAdapter;
  late _DepositResponseAdapter adapter;

  setUp(() {
    dio = HttpClient.paymentInstance.dio;
    savingsDio = HttpClient.instance.dio;
    originalAdapter = dio.httpClientAdapter;
    originalSavingsAdapter = savingsDio.httpClientAdapter;
    adapter = _DepositResponseAdapter(
      '{"status":1,"transaction_id":"deposit-123"}',
    );
    dio.httpClientAdapter = adapter;
  });

  tearDown(() {
    dio.httpClientAdapter = originalAdapter;
    savingsDio.httpClientAdapter = originalSavingsAdapter;
  });

  test(
    'loads fixed deposits using the documented account and device payload',
    () async {
      adapter = _DepositResponseAdapter(
        '{"status":1,"data":[{"fixed_deposit_id":"fd-123",'
        '"product_name":"90 Day Fixed Deposit","principal_amount":"250.00"}]}',
      );
      savingsDio.httpClientAdapter = adapter;

      final result = await SavingsService().getFixedDeposits(
        accountNumber: '0010500000133848',
        imeiNumber: 100200300,
      );

      final request = adapter.request!;
      final body = request.data as Map<String, dynamic>;
      expect(request.method, 'POST');
      expect(request.uri.path, endsWith('/getMemFixedDeposits'));
      expect(request.contentType, Headers.jsonContentType);
      expect(body['account_number'], '0010500000133848');
      expect(body['imei_number'], 100200300);
      expect(body['s_key'], isNotEmpty);
      expect(result['status'], 'success');
      expect(result['data'], [
        {
          'fixed_deposit_id': 'fd-123',
          'product_name': '90 Day Fixed Deposit',
          'principal_amount': '250.00',
          'savings_id': 'fd-123',
          'name': '90 Day Fixed Deposit',
          'balance': '250.00',
          'type': 'fixed_deposit',
        },
      ]);
    },
  );

  test('returns an empty list when the fixed deposit API has no records', () async {
    adapter = _DepositResponseAdapter('{"status":0,"message":"No Record Found"}');
    savingsDio.httpClientAdapter = adapter;

    final result = await SavingsService().getFixedDeposits(
      accountNumber: '0010500000133848',
      imeiNumber: 100200300,
    );

    expect(result['status'], 'success');
    expect(result['data'], isEmpty);
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

  test('treats an airtime authorization response as pending', () async {
    adapter = _DepositResponseAdapter(
      '{"status":"pending","message":"Please authorize the payment",'
      '"transaction_id":"airtime-123"}',
    );
    dio.httpClientAdapter = adapter;

    final result = await PaymentService().buyAirtime(
      phoneNumber: '233241234567',
      channel: 'mtn-gh',
      amount: 10,
      username: 'Test Member',
      productId: '59656',
    );

    expect(result['status'], 'pending');
    expect(result['is_pending'], isTrue);
    expect(result['transaction_id'], 'airtime-123');
  });

  test('continues to reject an explicitly failed airtime response', () async {
    adapter = _DepositResponseAdapter(
      '{"status":"failed","message":"Payment declined"}',
    );
    dio.httpClientAdapter = adapter;

    await expectLater(
      PaymentService().buyAirtime(
        phoneNumber: '233241234567',
        channel: 'mtn-gh',
        amount: 10,
        username: 'Test Member',
        productId: '59656',
      ),
      throwsA(isA<GenericException>()),
    );
  });

  test(
    'sends the documented withdrawal payload and returns its reference',
    () async {
      adapter = _DepositResponseAdapter(
        '{"status":1,"transaction_id":"withdraw-123"}',
      );
      dio.httpClientAdapter = adapter;

      final result = await SavingsService().withdrawSavings(
        phoneNumber: '233241234567',
        accountNumber: '1234567890',
        pin: '1234',
        amount: 20,
        imeiNumber: 123456,
        savingsId: '59656',
        username: 'Test Member',
      );

      final request = adapter.request!;
      final body = request.data as Map<String, dynamic>;
      expect(request.method, 'POST');
      expect(request.uri.path, endsWith('/withdraw'));
      expect(request.contentType, Headers.formUrlEncodedContentType);
      expect(body['phone_number'], '233241234567');
      expect(body['channel'], 'mtn-gh');
      expect(body['amount'], 20);
      expect(body['description'], 'EWithdrawal');
      expect(body['username'], 'Test Member');
      expect(body['product_id'], '59656');
      expect(body['account_number'], isNull);
      expect(body['pin'], 1234);
      expect(body['imei_number'], 123456);
      expect(body['ClientReference'], startsWith('ATCCU-W-'));
      expect(result['transaction_id'], 'withdraw-123');
      expect(result['is_pending'], isFalse);
    },
  );

  test('treats a successful empty withdrawal response as pending', () async {
    adapter = _DepositResponseAdapter('');
    dio.httpClientAdapter = adapter;

    final result = await SavingsService().withdrawSavings(
      phoneNumber: '233241234567',
      accountNumber: '1234567890',
      pin: '1234',
      amount: 20,
      imeiNumber: 123456,
      savingsId: '59656',
    );

    expect(result['status'], 'success');
    expect(result['is_pending'], isTrue);
    expect(result['transaction_id'], isNotEmpty);
    expect(result['reference'], result['transaction_id']);
  });

  test('rejects non-positive withdrawal amounts before posting', () async {
    await expectLater(
      SavingsService().withdrawSavings(
        phoneNumber: '233241234567',
        accountNumber: '1234567890',
        pin: '1234',
        amount: 0,
        imeiNumber: 123456,
      ),
      throwsA(isA<Exception>()),
    );

    expect(adapter.request, isNull);
  });
}
