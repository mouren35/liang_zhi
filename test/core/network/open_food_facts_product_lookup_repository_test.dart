import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:liangzhi/core/errors/app_exception.dart';
import 'package:liangzhi/core/network/open_food_facts_product_lookup_repository.dart';
import 'package:liangzhi/shared/constants/default_ids.dart';
import 'package:liangzhi/shared/models/product_barcode.dart';
import 'package:liangzhi/shared/models/product_lookup.dart';

void main() {
  final ProductBarcode barcode = ProductBarcode.tryParse(
    '6901234567892',
    ProductBarcodeFormat.ean13,
  )!;

  test('只发送条码、本地化参数和最小字段并映射命中结果', () async {
    late http.Request captured;
    final MockClient client = MockClient((http.Request request) async {
      captured = request;
      return http.Response(
        '''
        {
          "status": 1,
          "product": {
            "product_name": "测试牛奶",
            "brands": "粮知牧场",
            "quantity": "250 ml",
            "image_front_url": "https://images.example/milk.jpg",
            "categories_tags": ["en:dairy-products"]
          }
        }
        ''',
        200,
        headers: const <String, String>{
          'content-type': 'application/json; charset=utf-8',
        },
      );
    });

    final ProductLookupResult result = await OpenFoodFactsProductLookupRepository(
      client: client,
      baseUri: Uri.parse('https://world.openfoodfacts.org'),
    ).lookup(barcode);

    expect(result.status, ProductLookupStatus.found);
    expect(result.product?.name, '测试牛奶');
    expect(result.product?.suggestedCategoryId, DefaultIds.categoryDairy);
    expect(captured.method, 'GET');
    expect(captured.url.path, '/api/v2/product/6901234567892.json');
    expect(captured.url.queryParameters['cc'], 'cn');
    expect(captured.url.queryParameters['lc'], 'zh');
    expect(captured.url.queryParameters['tags_lc'], 'zh');
    expect(
      captured.url.queryParameters['fields'],
      OpenFoodFactsProductLookupRepository.fields,
    );
    expect(
      captured.headers['user-agent'],
      OpenFoodFactsProductLookupRepository.userAgent,
    );
    final String requestText = captured.url.toString();
    for (final String forbidden in <String>[
      'inventory',
      'quantity_value',
      'production_date',
      'expiry_date',
      'note',
    ]) {
      expect(requestText, isNot(contains(forbidden)));
    }
  });

  test('未收录商品返回未命中而不是 HTTP 类型', () async {
    final ProductLookupResult result = await OpenFoodFactsProductLookupRepository(
      client: MockClient(
        (http.Request request) async => http.Response('{"status":0}', 200),
      ),
      baseUri: Uri.parse('https://example.com'),
    ).lookup(barcode);

    expect(result.status, ProductLookupStatus.notFound);
    expect(result.product, isNull);
  });

  test('限流与服务错误转换为统一异常', () async {
    for (final (int status, Matcher matcher) in <(int, Matcher)>[
      (429, isA<RemoteRateLimitedException>()),
      (500, isA<RemoteServiceException>()),
      (404, isNot(isA<AppException>())),
    ]) {
      final OpenFoodFactsProductLookupRepository repository = OpenFoodFactsProductLookupRepository(
        client: MockClient(
          (http.Request request) async => http.Response('{}', status),
        ),
        baseUri: Uri.parse('https://example.com'),
      );
      if (status == 404) {
        expect((await repository.lookup(barcode)).status, ProductLookupStatus.notFound);
      } else {
        expect(repository.lookup(barcode), throwsA(matcher));
      }
    }
  });

  test('超时与无网络转换为统一异常', () async {
    final OpenFoodFactsProductLookupRepository timeoutRepository =
        OpenFoodFactsProductLookupRepository(
          client: MockClient(
            (http.Request request) => Completer<http.Response>().future,
          ),
          baseUri: Uri.parse('https://example.com'),
          timeout: const Duration(milliseconds: 1),
        );
    final OpenFoodFactsProductLookupRepository offlineRepository =
        OpenFoodFactsProductLookupRepository(
          client: MockClient(
            (http.Request request) async => throw const SocketException('offline'),
          ),
          baseUri: Uri.parse('https://example.com'),
        );

    expect(
      timeoutRepository.lookup(barcode),
      throwsA(isA<NetworkTimeoutException>()),
    );
    expect(
      offlineRepository.lookup(barcode),
      throwsA(isA<NetworkUnavailableException>()),
    );
  });

  test('拒绝非 HTTPS 服务地址', () {
    expect(
      () => OpenFoodFactsProductLookupRepository(
        client: MockClient(
          (http.Request request) async => http.Response('{}', 200),
        ),
        baseUri: Uri.parse('http://example.com'),
      ),
      throwsArgumentError,
    );
  });
}
