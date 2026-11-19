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

  test('loads fixed deposits from the documented products response', () async {
    adapter = _DepositResponseAdapter(
      '{"status":1,"message":"Product found","products":['
      '{"id":"5293","pro_name":"91 days","pro_status":"Approved",'
      '"principal":"16000.00","interest_rate":"9.50","duration":"91",'
      '"maturity_amount":"16378.96","start_date":"2026-10-16",'
      '"maturity_date":"2027-01-16"}]}',
    );
    savingsDio.httpClientAdapter = adapter;

    final result = await SavingsService().getFixedDeposits(
      accountNumber: '0010500000133848',
      imeiNumber: 100200300,
    );

    expect(result['data'], [
      {
        'id': '5293',
        'pro_name': '91 days',
        'pro_status': 'Approved',
        'principal': '16000.00',
        'interest_rate': '9.50',
        'duration': '91',
        'maturity_amount': '16378.96',
        'start_date': '2026-10-16',
        'maturity_date': '2027-01-16',
        'savings_id': '5293',
        'name': '91 days',
        'balance': '16000.00',
        'type': 'fixed_deposit',
      },
    ]);
  });

  test(
    'returns an empty list when the fixed deposit API has no records',
    () async {
      adapter = _DepositResponseAdapter(
        '{"status":0,"message":"No Record Found"}',
      );
      savingsDio.httpClientAdapter = adapter;

      final result = await SavingsService().getFixedDeposits(
        accountNumber: '0010500000133848',
        imeiNumber: 100200300,
      );

      expect(result['status'], 'success');
      expect(result['data'], isEmpty);
    },
  );

  test(
    'identifies share products returned by the member savings endpoint',
    () async {
      adapter = _DepositResponseAdapter(
        '{"status":1,"data":['
        '{"id":"1436","name":"PROJECT SHARES","balance":"891.03"},'
        '{"id":"1437","product_name":"ORDINARY SHARES","balance":"2262.73"},'
        '{"id":"1438","name":"Member Investment","type":"member",'
        '"product_type":"shares","balance":"100"},'
        '{"id":"9656","name":"SAVINGS","balance":"324.95"}]}',
      );
      savingsDio.httpClientAdapter = adapter;

      final result = await SavingsService().getSavingsList(
        phoneNumber: '0241234567',
        accountNumber: '0010600000040752',
        pin: '',
        imeiNumber: 100200300,
      );

      final products = result['data'] as List<Map<String, dynamic>>;
      expect(products.map((product) => product['name']), [
        'PROJECT SHARES',
        'ORDINARY SHARES',
        'Member Investment',
        'SAVINGS',
      ]);
      expect(products.map(SavingsService.isShareProduct), [
        true,
        true,
        true,
        false,
      ]);
    },
  );

  test('keeps share products available through the shares endpoint', () async {
    adapter = _DepositResponseAdapter(
      '{"status":1,"shares":['
      '{"id":"1436","name":"PROJECT SHARES","balance":"891.03"},'
      '{"id":"1437","name":"ORDINARY SHARES","balance":"2262.73"}]}',
    );
    savingsDio.httpClientAdapter = adapter;

    final result = await SharesService().getShares(
      phoneNumber: '0241234567',
      accountNumber: '0010600000040752',
      pin: '',
      imeiNumber: 100200300,
    );

    expect((result['data'] as List).map((share) => share['name']), [
      'PROJECT SHARES',
      'ORDINARY SHARES',
    ]);
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
      expect(result['is_pending'], isFalse);
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
    'treats an unrecognized successful HTTP response as pending, not failed',
    () async {
      adapter = _DepositResponseAdapter(
        '{"status":0,"message":"Request accepted","transaction_id":"deposit-456"}',
      );
      dio.httpClientAdapter = adapter;

      final result = await SavingsService().depositSavings(
        phoneNumber: '233241234567',
        amount: 10,
        savingsId: '59656',
      );

      expect(result['status'], 'pending');
      expect(result['is_pending'], isTrue);
      expect(result['transaction_id'], 'deposit-456');
      expect(result['reference'], 'deposit-456');
      expect(
        result['message'],
        contains('Request accepted Do not submit another deposit'),
      );
    },
  );

  test(
    'keeps an accepted response pending when the provider omits its reference',
    () async {
      adapter = _DepositResponseAdapter(
        '{"status":"processing","message":"Deposit request received"}',
      );
      dio.httpClientAdapter = adapter;

      final result = await SavingsService().depositSavings(
        phoneNumber: '233241234567',
        amount: 10,
        savingsId: '59656',
      );

      expect(result['status'], 'pending');
      expect(result['is_pending'], isTrue);
      expect(result['transaction_id'], startsWith('ATCCU-'));
      expect(result['reference'], result['transaction_id']);
    },
  );

  test('continues to reject an explicitly failed savings deposit', () async {
    adapter = _DepositResponseAdapter(
      '{"status":"failed","message":"Payment declined"}',
    );
    dio.httpClientAdapter = adapter;

    await expectLater(
      SavingsService().depositSavings(
        phoneNumber: '233241234567',
        amount: 10,
        savingsId: '59656',
      ),
      throwsA(isA<GenericException>()),
    );
  });

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
        productId: '51437',
        pin: '1234',
      );

      final request = adapter.request!;
      final body = request.data as Map<String, dynamic>;
      expect(request.method, 'POST');
      expect(request.uri.path, endsWith('/airtime'));
      expect(request.contentType, Headers.jsonContentType);
      expect(body['phone_number'], '233241234567');
      expect(body['channel'], 'mtn-gh');
      expect(body['amount'], 10);
      expect(body['description'], 'Edeposit');
      expect(body['email'], '');
      expect(body['username'], 'Test Member');
      expect(body['product_id'], '51437');
      expect(body['pin'], 1234);
      expect(body['s_key'], isNotEmpty);
      expect(result['status'], 'success');
      expect(result['is_pending'], isTrue);
    },
  );

  test('requires a PIN before posting an airtime purchase', () async {
    await expectLater(
      PaymentService().buyAirtime(
        phoneNumber: '233241234567',
        channel: 'mtn-gh',
        amount: 10,
        username: 'Test Member',
        productId: '51437',
        pin: '',
      ),
      throwsA(isA<ValidationException>()),
    );

    expect(adapter.request, isNull);
  });

  test('sends data bundle purchases through the airtime endpoint', () async {
    adapter = _DepositResponseAdapter('');
    dio.httpClientAdapter = adapter;

    final result = await PaymentService().buyDataBundle(
      phoneNumber: '233241234567',
      channel: 'mtn-gh',
      amount: 10,
      username: 'Test Member',
      productId: '59656',
      pin: '1234',
    );

    final request = adapter.request!;
    final body = request.data as Map<String, dynamic>;
    expect(request.method, 'POST');
    expect(request.uri.path, endsWith('/airtime'));
    expect(body['phone_number'], '233241234567');
    expect(body['channel'], 'mtn-gh');
    expect(body['amount'], 10);
    expect(body['username'], 'Test Member');
    expect(body['product_id'], '59656');
    expect(body['pin'], 1234);
    expect(result['status'], 'success');
    expect(result['is_pending'], isTrue);
  });

  test('requires a PIN before posting a data bundle purchase', () async {
    await expectLater(
      PaymentService().buyDataBundle(
        phoneNumber: '233241234567',
        channel: 'mtn-gh',
        amount: 10,
        username: 'Test Member',
        productId: '59656',
        pin: '',
      ),
      throwsA(isA<ValidationException>()),
    );

    expect(adapter.request, isNull);
  });

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
      pin: '1234',
    );

    expect(result['status'], 'pending');
    expect(result['is_pending'], isTrue);
    expect(result['transaction_id'], 'airtime-123');
  });

  test(
    'treats an accepted processing response as pending instead of failing',
    () async {
      adapter = _DepositResponseAdapter(
        '{"status":"processing","message":"Airtime request received"}',
      );
      dio.httpClientAdapter = adapter;

      final result = await PaymentService().buyAirtime(
        phoneNumber: '233241234567',
        channel: 'mtn-gh',
        amount: 10,
        username: 'Test Member',
        productId: '59656',
        pin: '1234',
      );

      expect(result['status'], 'pending');
      expect(result['is_pending'], isTrue);
      expect(result['message'], 'Airtime request received');
    },
  );

  test('treats Hubtel ResponseCode 0001 as pending', () async {
    adapter = _DepositResponseAdapter(
      '{"Message":"Transaction pending. Expect callback request for final state.",'
      '"ResponseCode":"0001","Data":{"TransactionId":"hubtel-123",'
      '"ClientReference":"ATCCU-123","Amount":1.01}}',
    );
    dio.httpClientAdapter = adapter;

    final result = await PaymentService().buyAirtime(
      phoneNumber: '233241234567',
      channel: 'mtn-gh',
      amount: 10,
      username: 'Test Member',
      productId: '59656',
      pin: '1234',
    );

    expect(result['status'], 'pending');
    expect(result['is_pending'], isTrue);
    expect(result['message'], contains('Transaction pending'));
    expect(result['transaction_id'], 'hubtel-123');
    expect(result['reference'], 'ATCCU-123');
  });

  test('treats an unknown successful HTTP response as pending', () async {
    adapter = _DepositResponseAdapter('{"message":"Airtime request accepted"}');
    dio.httpClientAdapter = adapter;

    final result = await PaymentService().buyAirtime(
      phoneNumber: '233241234567',
      channel: 'mtn-gh',
      amount: 10,
      username: 'Test Member',
      productId: '59656',
      pin: '1234',
    );

    expect(result['status'], 'pending');
    expect(result['is_pending'], isTrue);
    expect(result['message'], 'Airtime request accepted');
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
        pin: '1234',
      ),
      throwsA(isA<GenericException>()),
    );
  });

  test('rejects documented non-success airtime status', () async {
    adapter = _DepositResponseAdapter(
      '{"status":"0","message":"Amount per transaction exceeded"}',
    );
    dio.httpClientAdapter = adapter;

    await expectLater(
      PaymentService().buyAirtime(
        phoneNumber: '233241234567',
        channel: 'mtn-gh',
        amount: 10,
        username: 'Test Member',
        productId: '51437',
        pin: '1234',
      ),
      throwsA(
        isA<GenericException>().having(
          (error) => error.message,
          'message',
          'Amount per transaction exceeded',
        ),
      ),
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
        currentBalance: 500,
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
      currentBalance: 500,
      imeiNumber: 123456,
      savingsId: '59656',
    );

    expect(result['status'], 'pending');
    expect(result['is_pending'], isTrue);
    expect(result['transaction_id'], isNotEmpty);
    expect(result['reference'], result['transaction_id']);
  });

  test(
    'keeps a success response without a provider reference pending',
    () async {
      adapter = _DepositResponseAdapter('{"status":1,"message":"Accepted"}');
      dio.httpClientAdapter = adapter;

      final result = await SavingsService().withdrawSavings(
        phoneNumber: '233241234567',
        accountNumber: '1234567890',
        pin: '1234',
        amount: 20,
        currentBalance: 500,
        imeiNumber: 123456,
        savingsId: '59656',
      );

      expect(result['status'], 'pending');
      expect(result['is_pending'], isTrue);
      expect(result['message'], 'Accepted');
      expect(result['transaction_id'], startsWith('ATCCU-W-'));
    },
  );

  test('rejects non-positive withdrawal amounts before posting', () async {
    await expectLater(
      SavingsService().withdrawSavings(
        phoneNumber: '233241234567',
        accountNumber: '1234567890',
        pin: '1234',
        amount: 0,
        currentBalance: 500,
        imeiNumber: 123456,
      ),
      throwsA(isA<Exception>()),
    );

    expect(adapter.request, isNull);
  });

  test('withdrawal cannot reduce balance below GH₵50', () async {
    await expectLater(
      SavingsService().withdrawSavings(
        phoneNumber: '233241234567',
        accountNumber: '1234567890',
        pin: '1234',
        amount: 451,
        currentBalance: 500,
        imeiNumber: 123456,
      ),
      throwsA(isA<ValidationException>()),
    );

    expect(adapter.request, isNull);
  });

  test('allows withdrawal that leaves exactly GH₵50', () async {
    adapter = _DepositResponseAdapter(
      '{"status":1,"transaction_id":"withdraw-boundary"}',
    );
    dio.httpClientAdapter = adapter;

    await SavingsService().withdrawSavings(
      phoneNumber: '233241234567',
      accountNumber: '1234567890',
      pin: '1234',
      amount: 450,
      currentBalance: 500,
      imeiNumber: 123456,
    );

    expect(adapter.request, isNotNull);
  });
}
