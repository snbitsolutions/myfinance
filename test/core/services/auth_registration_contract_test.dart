import 'dart:typed_data';

import 'package:adepa_teachers/core/exceptions/app_exceptions.dart';
import 'package:adepa_teachers/core/services/api_service.dart';
import 'package:adepa_teachers/core/services/http_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _RegistrationResponseAdapter implements HttpClientAdapter {
  _RegistrationResponseAdapter([
    this.responseBody = '{"status":1,"message":"Registration Successful"}',
  ]);

  final String responseBody;
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      responseBody,
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
  late _RegistrationResponseAdapter adapter;

  setUp(() {
    dio = HttpClient.instance.dio;
    originalAdapter = dio.httpClientAdapter;
    adapter = _RegistrationResponseAdapter();
    dio.httpClientAdapter = adapter;
  });

  tearDown(() {
    dio.httpClientAdapter = originalAdapter;
  });

  test(
    'sends existing-member registration details including login password',
    () async {
      final response = await AuthService().register(
        accountNumber: '0010600000040752',
        phoneNumber: '0241234567',
        birthDate: '1989-10-07',
        password: 'member-pass-123',
        pin: '1357',
        transactionPin: '2468',
        imeiNumber: 100200300,
        phoneMake: 'Flutter mobile app',
      );

      final request = adapter.request!;
      final body = request.data as Map<String, dynamic>;
      expect(request.method, 'POST');
      expect(
        request.uri.toString(),
        'https://adepaye.com/api/mobileapp-api/register',
      );
      expect(body['acc_number'], 10600000040752);
      expect(body['phone_number'], 233241234567);
      expect(body['birth_date'], '1989-10-07');
      expect(body['password'], 'member-pass-123');
      expect(body['pin'], 1357);
      expect(body['trans_pin'], 2468);
      expect(body['imei_number'], 100200300);
      expect(body['phone_make'], 'Flutter mobile app');
      expect(response['status'], 1);
    },
  );

  test('sends date of birth and accepts an explicit confirmation', () async {
    adapter = _RegistrationResponseAdapter(
      '{"status":1,"message":"Registration Successful"}',
    );
    dio.httpClientAdapter = adapter;

    await AuthService().confirmAccountNumber(
      accountNumber: '0010600000040752',
      phoneNumber: '0241234567',
      birthDate: '1989-10-07',
    );

    final request = adapter.request!;
    expect(
      request.uri.toString(),
      'https://adepaye.com/api/mobileapp-api/confirmAccountNumber',
    );
    expect(request.contentType, Headers.formUrlEncodedContentType);
    final body = request.data as Map<String, dynamic>;
    expect(body['account_number'], '0010600000040752');
    expect(body['phone_number'], '0241234567');
    expect(body['birth_date'], '1989-10-07');
    expect(body['s_key'], isNotEmpty);
    expect(body, isNot(contains('imei_number')));
    expect(body, isNot(contains('phone_make')));
  });

  test('rejects registration without a transaction PIN before sending', () async {
    await expectLater(
      AuthService().register(
        accountNumber: '0010600000040752',
        phoneNumber: '0241234567',
        birthDate: '1989-10-07',
        password: 'member-pass-123',
        imeiNumber: 100200300,
        phoneMake: 'iPhone',
      ),
      throwsA(isA<ValidationException>()),
    );
    expect(adapter.request, isNull);
  });

  test('accepts empty membership confirmation responses', () async {
    adapter = _RegistrationResponseAdapter('');
    dio.httpClientAdapter = adapter;

    await AuthService().confirmAccountNumber(
      accountNumber: '0010600000040752',
      phoneNumber: '0241234567',
      birthDate: '1989-10-07',
    );

    expect(
      adapter.request!.uri.toString(),
      'https://adepaye.com/api/mobileapp-api/confirmAccountNumber',
    );
  });

  test('rejects explicit membership confirmation failures', () async {
    adapter = _RegistrationResponseAdapter(
      '{"status":0,"message":"Account number was not found"}',
    );
    dio.httpClientAdapter = adapter;

    await expectLater(
      AuthService().confirmAccountNumber(
        accountNumber: '0010600000040752',
        phoneNumber: '0241234567',
        birthDate: '1989-10-07',
      ),
      throwsA(isA<AuthException>()),
    );
    expect(
      adapter.request!.uri.toString(),
      'https://adepaye.com/api/mobileapp-api/confirmAccountNumber',
    );
  });

  test(
    'sends new-member account creation details in documented format',
    () async {
      adapter = _RegistrationResponseAdapter(
        '{"status":1,"account_number":"0010100000144795",'
        '"message":"Registration Successful"}',
      );
      dio.httpClientAdapter = adapter;

      final response = await AuthService().createMember(
        fullName: 'Maximus Alves',
        ghanaCard: 'GHA-10000075-2',
        phoneNumber: '233241952608',
        birthDate: '1985-12-25',
        gender: 'Male',
        address: '266 Butare Street',
        email: 'member@example.com',
        savingsProduct: 1,
        sharesProduct: 5,
        password: '12345',
        transactionPin: '1010',
        imeiNumber: 100000000000001,
        phoneMake: 'Flutter mobile app',
      );

      final request = adapter.request!;
      final body = request.data as Map<String, dynamic>;
      expect(request.method, 'POST');
      expect(
        request.uri.toString(),
        'https://adepaye.com/api/mobileapp-api/create',
      );
      expect(body['full_name'], 'Maximus Alves');
      expect(body['ghana_card'], 'GHA-10000075-2');
      expect(body['phone_number'], 233241952608);
      expect(body['birth_date'], '1985-12-25');
      expect(body['gender'], 'Male');
      expect(body['address'], '266 Butare Street');
      expect(body['email'], 'member@example.com');
      expect(body['savings_product'], 1);
      expect(body['shares_product'], 5);
      expect(body['password'], '12345');
      expect(body['trans_pin'], 1010);
      expect(body['imei_number'], 100000000000001);
      expect(body['phone_make'], 'Flutter mobile app');
      expect(body['s_key'], isNotEmpty);
      expect(response['account_number'], '0010100000144795');
    },
  );

  test(
    'normalizes Ghana local phone numbers before account creation',
    () async {
      await AuthService().createMember(
        fullName: 'Maximus Alves',
        ghanaCard: 'GHA-10000075-2',
        phoneNumber: '0241952608',
        birthDate: '1985-12-25',
        gender: 'Male',
        address: '266 Butare Street',
        email: 'member@example.com',
        savingsProduct: 1,
        sharesProduct: 5,
        password: 'strong-password',
        transactionPin: '1010',
        imeiNumber: 100000000000001,
        phoneMake: 'Flutter mobile app',
      );

      final body = adapter.request!.data as Map<String, dynamic>;
      expect(body['phone_number'], 233241952608);
    },
  );
}
