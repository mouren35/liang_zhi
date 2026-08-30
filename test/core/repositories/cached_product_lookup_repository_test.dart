import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/core/database/app_database.dart';
import 'package:liangzhi/core/database/default_data.dart';
import 'package:liangzhi/core/errors/app_exception.dart';
import 'package:liangzhi/core/repositories/cached_product_lookup_repository.dart';
import 'package:liangzhi/shared/constants/default_ids.dart';
import 'package:liangzhi/shared/models/product_barcode.dart';
import 'package:liangzhi/shared/models/product_lookup.dart';
import 'package:liangzhi/shared/repositories/product_lookup_repository.dart';

void main() {
  late AppDatabase database;
  late ProductBarcode barcode;
  late DateTime now;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    barcode = ProductBarcode.tryParse(
      '6901234567892',
      ProductBarcodeFormat.ean13,
    )!;
    now = DateTime.utc(2026, 7, 26, 9);
    await initializeDefaultData(database, now: now);
  });

  tearDown(() => database.close());

  test('首次访问远程并缓存，第二次命中本地', () async {
    final _FakeRemote remote = _FakeRemote(_found(barcode.value));
    final CachedProductLookupRepository repository = CachedProductLookupRepository(
      database: database,
      remote: remote,
      now: () => now,
    );

    expect((await repository.lookup(barcode)).source, ProductLookupSource.remote);
    expect((await repository.lookup(barcode)).source, ProductLookupSource.cache);
    expect(remote.calls, 1);
    expect(await database.select(database.barcodeProductCache).get(), hasLength(1));
  });

  test('过期缓存刷新失败时返回需确认的旧命中', () async {
    await database
        .into(database.barcodeProductCache)
        .insert(
          BarcodeProductCacheCompanion.insert(
            barcode: barcode.value,
            lookupStatus: 'found',
            productName: const Value<String>('旧名称'),
            fetchedAt: now.subtract(const Duration(days: 31)).millisecondsSinceEpoch,
            expiresAt: now.subtract(const Duration(days: 1)).millisecondsSinceEpoch,
          ),
        );
    final CachedProductLookupRepository repository = CachedProductLookupRepository(
      database: database,
      remote: _FakeRemote.error(const NetworkUnavailableException()),
      now: () => now,
    );

    final ProductLookupResult result = await repository.lookup(barcode);

    expect(result.source, ProductLookupSource.staleCache);
    expect(result.requiresConfirmation, isTrue);
    expect(result.product?.name, '旧名称');
  });

  test('已保存食品优先复用且不会访问远程', () async {
    await database
        .into(database.foods)
        .insert(
          FoodsCompanion.insert(
            id: 'food-1',
            barcode: Value<String>(barcode.value),
            name: '用户确认名称',
            brand: const Value<String>('本地品牌'),
            categoryId: const Value<String>(DefaultIds.categorySnacks),
            quantity: 1,
            expiryInputType: 'direct',
            expiryDate: '2026-08-01',
            status: 'active',
            createdAt: 1,
            updatedAt: 2,
          ),
        );
    final _FakeRemote remote = _FakeRemote(_found(barcode.value));
    final CachedProductLookupRepository repository = CachedProductLookupRepository(
      database: database,
      remote: remote,
      now: () => now,
    );

    final ProductLookupResult result = await repository.lookup(barcode);

    expect(result.source, ProductLookupSource.localFood);
    expect(result.product?.name, '用户确认名称');
    expect(result.product?.suggestedCategoryId, DefaultIds.categorySnacks);
    expect(remote.calls, 0);
  });
}

ProductLookupResult _found(String barcode) {
  return ProductLookupResult.found(
    ProductSuggestion(
      barcode: barcode,
      name: '远程名称',
      categoryTags: const <String>['en:snacks'],
      suggestedCategoryId: DefaultIds.categorySnacks,
    ),
    source: ProductLookupSource.remote,
  );
}

final class _FakeRemote implements ProductLookupRepository {
  _FakeRemote(this.result) : error = null;

  _FakeRemote.error(this.error) : result = null;

  final ProductLookupResult? result;
  final Object? error;
  int calls = 0;

  @override
  Future<ProductLookupResult> lookup(ProductBarcode barcode) async {
    calls += 1;
    if (error case final Object value) {
      throw value;
    }
    return result!;
  }
}
