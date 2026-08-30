import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:liangzhi/core/database/app_database.dart';
import 'package:liangzhi/core/database/barcode_cache_policy.dart';
import 'package:liangzhi/core/network/product_category_mapper.dart';
import 'package:liangzhi/shared/constants/default_ids.dart';
import 'package:liangzhi/shared/models/product_barcode.dart';
import 'package:liangzhi/shared/models/product_lookup.dart';
import 'package:liangzhi/shared/repositories/product_lookup_repository.dart';

typedef Clock = DateTime Function();

final class CachedProductLookupRepository implements ProductLookupRepository {
  const CachedProductLookupRepository({
    required AppDatabase database,
    required ProductLookupRepository remote,
    Clock now = DateTime.now,
  }) : _database = database,
       _remote = remote,
       _now = now;

  final AppDatabase _database;
  final ProductLookupRepository _remote;
  final Clock _now;

  @override
  Future<ProductLookupResult> lookup(ProductBarcode barcode) async {
    final Food? savedFood = await _latestSavedFood(barcode.value);
    if (savedFood != null) {
      return ProductLookupResult.found(
        ProductSuggestion(
          barcode: barcode.value,
          name: savedFood.name,
          brand: savedFood.brand,
          specification: savedFood.specification,
          imageUrl: _httpsUri(savedFood.imageRemoteUrl),
          categoryTags: const <String>[],
          suggestedCategoryId: savedFood.categoryId ?? DefaultIds.categoryOther,
        ),
        source: ProductLookupSource.localFood,
      );
    }

    final BarcodeProductCacheData? cached = await _cache(barcode.value);
    final DateTime now = _now().toUtc();
    if (cached != null &&
        !BarcodeCachePolicy.isExpired(
          expiresAtUtcMillis: cached.expiresAt,
          now: now,
        )) {
      return _fromCache(cached, source: ProductLookupSource.cache);
    }

    try {
      final ProductLookupResult result = await _remote.lookup(barcode);
      await _save(barcode.value, result, now);
      return result;
    } on Object {
      if (cached != null && cached.lookupStatus == 'found') {
        final ProductLookupResult stale = _fromCache(
          cached,
          source: ProductLookupSource.staleCache,
        );
        return ProductLookupResult.found(
          stale.product!,
          source: ProductLookupSource.staleCache,
          requiresConfirmation: true,
        );
      }
      rethrow;
    }
  }

  Future<Food?> _latestSavedFood(String barcode) {
    final SimpleSelectStatement<$FoodsTable, Food> query = _database.select(_database.foods)
      ..where(
        (Foods table) =>
            table.barcode.equals(barcode) &
            table.status.equals('active') &
            table.deletedAt.isNull(),
      )
      ..orderBy(<OrderingTerm Function($FoodsTable)>[
        (Foods table) => OrderingTerm.desc(table.updatedAt),
      ])
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<BarcodeProductCacheData?> _cache(String barcode) {
    return (_database.select(
      _database.barcodeProductCache,
    )..where((BarcodeProductCache table) => table.barcode.equals(barcode))).getSingleOrNull();
  }

  ProductLookupResult _fromCache(
    BarcodeProductCacheData data, {
    required ProductLookupSource source,
  }) {
    if (data.lookupStatus == 'not_found') {
      return ProductLookupResult.notFound(source: source);
    }
    final List<String> tags = _decodeTags(data.categoryTagsJson);
    return ProductLookupResult.found(
      ProductSuggestion(
        barcode: data.barcode,
        name: data.productName,
        brand: data.brand,
        specification: data.quantityText,
        imageUrl: _httpsUri(data.imageUrl),
        categoryTags: tags,
        suggestedCategoryId: ProductCategoryMapper.suggest(tags),
      ),
      source: source,
    );
  }

  Future<void> _save(
    String barcode,
    ProductLookupResult result,
    DateTime fetchedAt,
  ) {
    final ProductSuggestion? product = result.product;
    final String status = result.isFound ? 'found' : 'not_found';
    final DateTime expiresAt = BarcodeCachePolicy.expiresAt(
      lookupStatus: status,
      fetchedAt: fetchedAt,
    );
    return _database
        .into(_database.barcodeProductCache)
        .insertOnConflictUpdate(
          BarcodeProductCacheCompanion.insert(
            barcode: barcode,
            lookupStatus: status,
            productName: Value<String?>(product?.name),
            brand: Value<String?>(product?.brand),
            quantityText: Value<String?>(product?.specification),
            imageUrl: Value<String?>(product?.imageUrl?.toString()),
            categoryTagsJson: Value<String?>(
              product == null ? null : jsonEncode(product.categoryTags),
            ),
            fetchedAt: fetchedAt.millisecondsSinceEpoch,
            expiresAt: expiresAt.millisecondsSinceEpoch,
          ),
        );
  }
}

List<String> _decodeTags(String? value) {
  if (value == null) {
    return const <String>[];
  }
  try {
    return (jsonDecode(value) as List<Object?>).whereType<String>().toList(growable: false);
  } on Object {
    return const <String>[];
  }
}

Uri? _httpsUri(String? value) {
  final Uri? uri = value == null ? null : Uri.tryParse(value);
  return uri?.scheme == 'https' ? uri : null;
}
