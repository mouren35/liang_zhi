import 'package:liangzhi/shared/constants/default_ids.dart';

abstract final class ProductCategoryMapper {
  static String suggest(Iterable<String> tags) {
    final String normalized = tags.join(' ').toLowerCase();
    for (final (List<String> keywords, String categoryId) in _rules) {
      if (keywords.any(normalized.contains)) {
        return categoryId;
      }
    }
    return DefaultIds.categoryOther;
  }
}

const List<(List<String>, String)> _rules = <(List<String>, String)>[
  (<String>['cereals', 'rice', 'pasta', 'bread'], DefaultIds.categoryStaple),
  (<String>['meats', 'poultry'], DefaultIds.categoryMeatPoultry),
  (<String>['seafood', 'fish'], DefaultIds.categorySeafood),
  (<String>['vegetables'], DefaultIds.categoryVegetables),
  (<String>['fruits'], DefaultIds.categoryFruits),
  (<String>['dairy'], DefaultIds.categoryDairy),
  (<String>['beverages'], DefaultIds.categoryBeverages),
  (<String>['snacks', 'sweets'], DefaultIds.categorySnacks),
  (<String>['condiments', 'sauces', 'spices'], DefaultIds.categoryCondiments),
  (<String>['frozen'], DefaultIds.categoryFrozen),
];
