import 'dart:typed_data';

import 'package:adepa_teachers/core/constants/app_constants.dart';
import 'package:adepa_teachers/core/services/api_service.dart';
import 'package:adepa_teachers/core/services/http_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _ProductCatalogResponseAdapter implements HttpClientAdapter {
  _ProductCatalogResponseAdapter(this.body);

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
  late _ProductCatalogResponseAdapter adapter;

  setUp(() {
    dio = HttpClient.instance.dio;
    originalAdapter = dio.httpClientAdapter;
    adapter = _ProductCatalogResponseAdapter(
      '{"status":1,"products":[{"id":"4","name":"SAVINGS"}]}',
    );
    dio.httpClientAdapter = adapter;
  });

  tearDown(() {
    dio.httpClientAdapter = originalAdapter;
  });

  test('loads documented savings products', () async {
    final products = await ProductCatalogService().getProducts(
      endpoint: ApiEndpoints.getSavingsProducts,
    );

    expect(adapter.request!.method, 'GET');
    expect(adapter.request!.uri.toString(), ApiEndpoints.getSavingsProducts);
    expect(products, [
      {'id': '4', 'name': 'SAVINGS'},
    ]);
  });

  test('loads documented share products', () async {
    adapter = _ProductCatalogResponseAdapter(
      '{"status":1,"products":[{"id":"5","name":"PROJECT SHARES"}]}',
    );
    dio.httpClientAdapter = adapter;

    final products = await ProductCatalogService().getProducts(
      endpoint: ApiEndpoints.getSharesProducts,
    );

    expect(adapter.request!.method, 'GET');
    expect(adapter.request!.uri.toString(), ApiEndpoints.getSharesProducts);
    expect(products, [
      {'id': '5', 'name': 'PROJECT SHARES'},
    ]);
  });
}
