import 'package:flutter_test/flutter_test.dart';
import 'package:liangzhi/core/network/product_category_mapper.dart';
import 'package:liangzhi/shared/constants/default_ids.dart';

void main() {
  test('稳定关键词映射到全部本地分类', () {
    const Map<String, String> cases = <String, String>{
      'en:breads': DefaultIds.categoryStaple,
      'en:poultry': DefaultIds.categoryMeatPoultry,
      'en:fishes': DefaultIds.categorySeafood,
      'en:vegetables': DefaultIds.categoryVegetables,
      'en:fruits': DefaultIds.categoryFruits,
      'en:dairy-products': DefaultIds.categoryDairy,
      'en:beverages': DefaultIds.categoryBeverages,
      'en:sweets': DefaultIds.categorySnacks,
      'en:sauces': DefaultIds.categoryCondiments,
      'en:frozen-foods': DefaultIds.categoryFrozen,
    };

    for (final MapEntry<String, String> entry in cases.entries) {
      expect(ProductCategoryMapper.suggest(<String>[entry.key]), entry.value);
    }
  });

  test('未知或空标签回退其他', () {
    expect(
      ProductCategoryMapper.suggest(const <String>['en:unknown']),
      DefaultIds.categoryOther,
    );
    expect(
      ProductCategoryMapper.suggest(const <String>[]),
      DefaultIds.categoryOther,
    );
  });
}
