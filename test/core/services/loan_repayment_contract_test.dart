import 'dart:typed_data';

import 'package:adepa_teachers/core/exceptions/app_exceptions.dart';
import 'package:adepa_teachers/core/services/api_service.dart';
import 'package:adepa_teachers/core/services/http_client.dart';
import 'package:adepa_teachers/screens/loans/repayment_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _LoanRepaymentResponseAdapter implements HttpClientAdapter {
  _LoanRepaymentResponseAdapter(this.body);

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
  late _LoanRepaymentResponseAdapter adapter;

  setUp(() {
    dio = HttpClient.paymentInstance.dio;
    originalAdapter = dio.httpClientAdapter;
    adapter = _LoanRepaymentResponseAdapter('');
    dio.httpClientAdapter = adapter;
  });

  tearDown(() {
    dio.httpClientAdapter = originalAdapter;
  });

  test('posts the documented repayment payload and returns pending', () async {
    final result = await PaymentService().repayLoan(
      phoneNumber: '233241952608',
      channel: 'mtn-gh',
      amount: 100,
      currentOutstanding: 500,
      username: 'Test Member',
      productId: '59656',
    );

    final request = adapter.request!;
    final body = request.data as Map<String, dynamic>;
    expect(request.method, 'POST');
    expect(request.uri.path, endsWith('/deposit'));
    expect(request.contentType, Headers.jsonContentType);
    expect(body['phone_number'], '233241952608');
    expect(body['channel'], 'mtn-gh');
    expect(body['amount'], 100);
    expect(body['description'], 'Edeposit');
    expect(body['email'], '');
    expect(body['username'], 'Test Member');
    expect(body['product_id'], '59656');
    expect(body['s_key'], isNotEmpty);
    expect(body['ExternalTransactionId'], isNotEmpty);
    expect(body['ClientReference'], startsWith('ATCCU-LR-'));
    expect(result['is_pending'], isTrue);
    expect(result['transaction_id'], result['reference']);
  });

  for (final channel in ['mtn-gh', 'tigo-gh', 'vodafone-gh']) {
    test('posts the selected repayment channel: $channel', () async {
      await PaymentService().repayLoan(
        phoneNumber: '233241952608',
        channel: channel,
        amount: 100,
        currentOutstanding: 500,
        username: 'Test Member',
        productId: '59656',
      );

      final body = adapter.request!.data as Map<String, dynamic>;
      expect(body['channel'], channel);
    });
  }

  test(
    'rejects repayment above the outstanding balance before posting',
    () async {
      await expectLater(
        PaymentService().repayLoan(
          phoneNumber: '233241952608',
          channel: 'mtn-gh',
          amount: 600,
          currentOutstanding: 500,
          username: 'Test Member',
          productId: '59656',
        ),
        throwsA(isA<ValidationException>()),
      );

      expect(adapter.request, isNull);
    },
  );

  test(
    'normalizes backend loan identifiers before selecting a repayable loan',
    () {
      final loans = [
        {
          'loan_id': ' 12345 ',
          'name': 'Micro Loan',
          'outstanding_balance': 420,
        },
        {'id': '98765', 'name': 'Business Loan', 'outstanding_balance': 1500},
      ];

      expect(RepaymentScreen.normalizeLoanId(' 12345 '), '12345');
      final firstLoan = RepaymentScreen.findLoanForRepayment(loans, '12345');
      final secondLoan = RepaymentScreen.findLoanForRepayment(loans, '98765');
      expect(firstLoan, isNotNull);
      expect(firstLoan!['name'], 'Micro Loan');
      expect(secondLoan, isNotNull);
      expect(secondLoan!['name'], 'Business Loan');
      expect(RepaymentScreen.findLoanForRepayment(loans, 'draft-99'), isNull);
    },
  );
}
