import 'package:adepa_teachers/core/exceptions/app_exceptions.dart';
import 'package:adepa_teachers/core/constants/app_constants.dart';
import 'package:adepa_teachers/core/providers/app_providers.dart';
import 'package:adepa_teachers/core/services/api_service.dart';
import 'package:adepa_teachers/core/services/device_identity_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FixedDepositSavingsService extends SavingsService {
  int fixedDepositRequests = 0;

  @override
  Future<Map<String, dynamic>> getSavingsList({
    required String phoneNumber,
    required String accountNumber,
    required String pin,
    required int imeiNumber,
  }) async {
    return {
      'status': 'success',
      'data': [
        {
          'savings_id': 'saving-1',
          'name': 'Member Savings',
          'balance': 100,
          'type': 'member',
        },
        {
          'savings_id': 'share-1',
          'name': 'PROJECT SHARES',
          'balance': 891.03,
          'type': 'member',
        },
        {
          'savings_id': 'share-2',
          'name': 'ORDINARY SHARES',
          'balance': 2262.73,
          'type': 'member',
        },
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> getFixedDeposits({
    required String accountNumber,
    required int imeiNumber,
  }) async {
    fixedDepositRequests++;
    return {
      'status': 'success',
      'data': [
        {
          'fixed_deposit_id': 'fd-1',
          'product_name': '90 Day Fixed Deposit',
          'principal_amount': '250.00',
          'maturity_value': '265.00',
          'maturity_date': '2026-12-01',
        },
      ],
    };
  }
}

class _EmptySharesService extends SharesService {
  @override
  Future<Map<String, dynamic>> getShares({
    required String phoneNumber,
    required String accountNumber,
    required String pin,
    required int imeiNumber,
  }) async {
    return {'status': 'success', 'data': <Map<String, dynamic>>[]};
  }
}

class _UnavailableInvestmentService extends InvestmentService {
  @override
  Future<Map<String, dynamic>> getInvestments({
    required String phoneNumber,
    required String accountNumber,
    required String pin,
  }) async {
    throw GenericException(
      message: 'The investments endpoint is not available.',
    );
  }
}

class _FixedDepositDeviceIdentityService extends DeviceIdentityService {
  @override
  Future<int> getBackendDeviceNumber() async => 100200300;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final secureValues = <String, String>{
    AppConstants.secureStorageKeyUserPin: '2468',
  };
  late _FixedDepositSavingsService savingsService;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    secureValues
      ..clear()
      ..[AppConstants.secureStorageKeyUserPin] = '2468';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
          final arguments =
              (call.arguments as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{};
          final key = arguments['key'] as String?;
          switch (call.method) {
            case 'read':
              return key == null ? null : secureValues[key];
            case 'write':
              if (key != null) {
                secureValues[key] = arguments['value']?.toString() ?? '';
              }
              return null;
            case 'delete':
              if (key != null) secureValues.remove(key);
              return null;
            case 'deleteAll':
              secureValues.clear();
              return null;
            case 'containsKey':
              return key != null && secureValues.containsKey(key);
            case 'readAll':
              return Map<String, String>.from(secureValues);
            default:
              return null;
          }
        });
    savingsService = _FixedDepositSavingsService();
    container = ProviderContainer(
      overrides: [
        memberCredentialsProvider.overrideWithValue({
          'phone': '233241234567',
          'account': '0010500000133848',
        }),
        savingsServiceProvider.overrideWith((ref) => savingsService),
        sharesServiceProvider.overrideWith((ref) => _EmptySharesService()),
        investmentServiceProvider.overrideWith(
          (ref) => _UnavailableInvestmentService(),
        ),
        deviceIdentityServiceProvider.overrideWith(
          (ref) => _FixedDepositDeviceIdentityService(),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  test('savings list excludes fixed deposits', () async {
    final savings = await container.read(savingsProvider.future);

    expect(savings.map((record) => record['name']), ['Member Savings']);
    expect(savingsService.fixedDepositRequests, 0);
  });

  test(
    'shares from the member savings endpoint appear in the shares list',
    () async {
      final shares = await container.read(sharesProvider.future);

      expect(shares.map((record) => record['name']), [
        'PROJECT SHARES',
        'ORDINARY SHARES',
      ]);
      expect(shares.map((record) => record['savings_id']), [
        'share-1',
        'share-2',
      ]);
    },
  );

  test('fixed deposits appear in investment records', () async {
    final investments = await container.read(investmentsApiProvider.future);

    expect(savingsService.fixedDepositRequests, 1);
    expect(investments, hasLength(1));
    expect(investments.single['id'], 'fd-1');
    expect(investments.single['type'], 'Fixed Deposit');
    expect(investments.single['plan'], '90 Day Fixed Deposit');
    expect(investments.single['principal'], '250.00');
    expect(investments.single['current_value'], '265.00');
    expect(investments.single['maturity_date'], '2026-12-01');
  });
}
