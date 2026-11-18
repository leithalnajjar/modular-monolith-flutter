// modules/catalog_api/lib/src/testing/fake_product_catalog.dart
import 'package:core/core.dart';

import '../product.dart';
import '../product_actions.dart';
import '../product_catalog.dart';

/// An in-memory [ProductCatalog] for other modules' tests.
///
/// It lives next to the contract and is maintained by the catalog's owners,
/// and its tests run [checkProductCatalogContract], the same checks as the
/// real catalog's. A test that passes against this fake means something.
final class FakeProductCatalog implements ProductCatalog {
  FakeProductCatalog([Iterable<Product> products = const []]) {
    products.forEach(put);
  }

  final _products = <ProductId, Product>{};

  /// Every id passed to [getProduct], in order, for tests that care how
  /// often the catalog was asked.
  final requested = <ProductId>[];

  /// When set, every call fails with this, to test how callers cope with
  /// an unavailable catalog.
  Failure? failWith;

  /// Adds [product], or replaces the product with the same id (to simulate
  /// a price change, for example).
  void put(Product product) => _products[product.id] = product;

  void remove(ProductId id) => _products.remove(id);

  @override
  Future<Result<Product>> getProduct(ProductId id) async {
    requested.add(id);
    if (failWith case final failure?) return Result.err(failure);
    return switch (_products[id]) {
      final product? => Result.ok(product),
      null => Result.err(NotFound('No product with id ${id.value}')),
    };
  }

  @override
  Future<Result<List<Product>>> search(String query,
      {int limit = 20, int offset = 0}) async {
    if (failWith case final failure?) return Result.err(failure);
    if (limit <= 0) {
      return const Result.err(RuleViolation('limit must be positive'));
    }
    if (offset < 0) {
      return const Result.err(RuleViolation('offset cannot be negative'));
    }
    final needle = query.trim().toLowerCase();
    return Result.ok(_products.values
        .where((p) => p.name.toLowerCase().contains(needle))
        .skip(offset)
        .take(limit)
        .toList(growable: false));
  }
}

/// A [ProductActions] that simply collects what modules add to it.
final class FakeProductActions implements ProductActions {
  final _all = <ProductAction>[];

  @override
  void add(ProductAction action) => _all.add(action);

  @override
  List<ProductAction> get all => List.unmodifiable(_all);
}
