import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:liangzhi/app/app_info.dart';
import 'package:liangzhi/core/errors/app_exception.dart';
import 'package:liangzhi/core/network/product_category_mapper.dart';
import 'package:liangzhi/shared/models/product_barcode.dart';
import 'package:liangzhi/shared/models/product_lookup.dart';
import 'package:liangzhi/shared/repositories/product_lookup_repository.dart';

final class OpenFoodFactsProductLookupRepository implements ProductLookupRepository {
  OpenFoodFactsProductLookupRepository({
    required http.Client client,
    required Uri baseUri,
    Duration timeout = const Duration(seconds: 8),
  }) : _client = client,
       _baseUri = _requireHttps(baseUri),
       _timeout = timeout;

  static const String userAgent =
      'LiangZhi/${AppInfo.version} (https://github.com/mouren35/liang_zhi)';
  static const String fields = 'code,product_name,brands,quantity,image_front_url,categories_tags';

  final http.Client _client;
  final Uri _baseUri;
  final Duration _timeout;

  @override
  Future<ProductLookupResult> lookup(ProductBarcode barcode) async {
    final Uri uri = _buildUri(barcode.value);
    try {
      final http.Response response = await _client
          .get(uri, headers: const <String, String>{'User-Agent': userAgent})
          .timeout(_timeout);
      return _mapResponse(response, barcode.value);
    } on TimeoutException {
      throw const NetworkTimeoutException();
    } on SocketException {
      throw const NetworkUnavailableException();
    } on http.ClientException {
      throw const NetworkUnavailableException();
    } on FormatException {
      throw const RemoteServiceException('商品服务返回了无法识别的数据');
    }
  }

  Uri _buildUri(String barcode) {
    final List<String> segments = <String>[
      ..._baseUri.pathSegments.where((String segment) => segment.isNotEmpty),
      'api',
      'v2',
      'product',
      '$barcode.json',
    ];
    return _baseUri.replace(
      pathSegments: segments,
      queryParameters: const <String, String>{
        'cc': 'cn',
        'lc': 'zh',
        'tags_lc': 'zh',
        'fields': fields,
      },
    );
  }

  ProductLookupResult _mapResponse(http.Response response, String barcode) {
    if (response.statusCode == 404) {
      return const ProductLookupResult.notFound(
        source: ProductLookupSource.remote,
      );
    }
    if (response.statusCode == 429) {
      throw const RemoteRateLimitedException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const RemoteServiceException();
    }

    final Object? decoded = jsonDecode(response.body);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException();
    }
    if (decoded['status'] != 1) {
      return const ProductLookupResult.notFound(
        source: ProductLookupSource.remote,
      );
    }
    final Object? productValue = decoded['product'];
    if (productValue is! Map<String, Object?>) {
      throw const FormatException();
    }
    final List<String> categoryTags = switch (productValue['categories_tags']) {
      final List<Object?> values =>
        values
            .whereType<String>()
            .map((String value) => value.trim())
            .where((String value) => value.isNotEmpty)
            .toList(growable: false),
      _ => const <String>[],
    };
    return ProductLookupResult.found(
      ProductSuggestion(
        barcode: barcode,
        name: _optionalString(productValue['product_name']),
        brand: _optionalString(productValue['brands']),
        specification: _optionalString(productValue['quantity']),
        imageUrl: _httpsUri(productValue['image_front_url']),
        categoryTags: categoryTags,
        suggestedCategoryId: ProductCategoryMapper.suggest(categoryTags),
      ),
      source: ProductLookupSource.remote,
    );
  }
}

Uri _requireHttps(Uri uri) {
  if (uri.scheme != 'https' || uri.host.isEmpty) {
    throw ArgumentError.value(uri, 'baseUri', 'Open Food Facts 地址必须使用 HTTPS');
  }
  return uri;
}

String? _optionalString(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    return null;
  }
  return value.trim();
}

Uri? _httpsUri(Object? value) {
  final String? raw = _optionalString(value);
  if (raw == null) {
    return null;
  }
  final Uri? uri = Uri.tryParse(raw);
  return uri?.scheme == 'https' && uri?.host.isNotEmpty == true ? uri : null;
}
