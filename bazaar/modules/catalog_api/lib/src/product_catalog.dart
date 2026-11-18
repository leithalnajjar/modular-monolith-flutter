import 'package:core/core.dart';

import 'product.dart';

/// What other modules may ask the catalog. Deliberately small.
///
/// The cart uses [getProduct] to price a line. Search screens live inside
/// the catalog module itself, so [search] is here mainly for other modules
/// that need suggestions (for example, "you might also like" in checkout).
abstract interface class ProductCatalog {
  /// Returns the product, or [NotFound] if the ID is unknown.
  Future<Result<Product>> getProduct(ProductId id);

  /// Returns up to [limit] products whose name contains [query], ignoring
  /// case, skipping the first [offset] matches (for paging through long
  /// lists). No matches is an empty list, not a failure.
  ///
  /// Fails with [RuleViolation] when [limit] is not positive or [offset]
  /// is negative.
  ///
  /// The checks in `package:catalog_api/testing.dart` spell out every
  /// promise of this contract; implementations and fakes must pass them.
  Future<Result<List<Product>>> search(String query,
      {int limit = 20, int offset = 0});
}
