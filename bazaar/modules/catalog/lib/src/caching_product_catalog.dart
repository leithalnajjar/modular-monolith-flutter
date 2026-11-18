import 'package:catalog_api/catalog_api.dart';
import 'package:core/core.dart';

import 'data/product_source.dart';

/// The catalog's implementation of its public contract.
///
/// It validates input, remembers products it has seen, and keeps the app
/// usable when the server is briefly unreachable by serving the last known
/// version of a product. Where the products come from is the
/// [ProductSource]'s business.
final class CachingProductCatalog implements ProductCatalog {
  CachingProductCatalog(
    this._source,
    this._clock, {
    this.maxAge = const Duration(minutes: 5),
  });

  final ProductSource _source;
  final Clock _clock;

  /// How long a cached product counts as fresh.
  final Duration maxAge;

  final _cache = <ProductId, ({Product product, DateTime storedAt})>{};

  @override
  Future<Result<Product>> getProduct(ProductId id) async {
    final cached = _cache[id];
    if (cached != null && _isFresh(cached.storedAt)) {
      return Result.ok(cached.product);
    }

    final result = await _source.fetch(id);
    switch (result) {
      case Ok(:final value):
        _remember(value);
      case Err(failure: NotFound()):
        _cache.remove(id); // it was deleted: never show it again
      case Err(failure: Unavailable()) when cached != null:
        return Result.ok(cached.product); // stale beats nothing
      case Err():
        break;
    }
    return result;
  }

  @override
  Future<Result<List<Product>>> search(String query,
      {int limit = 20, int offset = 0}) async {
    if (limit <= 0) {
      return const Result.err(RuleViolation('limit must be positive'));
    }
    if (offset < 0) {
      return const Result.err(RuleViolation('offset cannot be negative'));
    }
    final result =
        await _source.search(query, limit: limit, offset: offset);
    if (result case Ok(:final value)) {
      value.forEach(_remember); // opening a listed product is instant
    }
    return result;
  }

  bool _isFresh(DateTime storedAt) =>
      _clock.now().difference(storedAt) < maxAge;

  void _remember(Product product) =>
      _cache[product.id] = (product: product, storedAt: _clock.now());
}
