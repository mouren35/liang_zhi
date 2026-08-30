enum ProductLookupStatus { found, notFound }

enum ProductLookupSource { localFood, cache, remote, staleCache }

final class ProductSuggestion {
  const ProductSuggestion({
    required this.barcode,
    required this.categoryTags,
    required this.suggestedCategoryId,
    this.name,
    this.brand,
    this.specification,
    this.imageUrl,
  });

  final String barcode;
  final String? name;
  final String? brand;
  final String? specification;
  final Uri? imageUrl;
  final List<String> categoryTags;
  final String suggestedCategoryId;
}

final class ProductLookupResult {
  const ProductLookupResult.found(
    ProductSuggestion this.product, {
    required this.source,
    this.requiresConfirmation = false,
  }) : status = ProductLookupStatus.found;

  const ProductLookupResult.notFound({
    required this.source,
  }) : status = ProductLookupStatus.notFound,
       product = null,
       requiresConfirmation = false;

  final ProductLookupStatus status;
  final ProductSuggestion? product;
  final ProductLookupSource source;
  final bool requiresConfirmation;

  bool get isFound => status == ProductLookupStatus.found;
}
