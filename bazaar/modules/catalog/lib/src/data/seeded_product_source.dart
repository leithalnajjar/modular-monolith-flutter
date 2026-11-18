import 'package:catalog_api/catalog_api.dart';
import 'package:core/core.dart';

import 'catalog_store.dart';
import 'product_source.dart';

/// Products held in memory: for demos, tests, and the first chapters.
final class SeededProductSource implements ProductSource {
  SeededProductSource(this._store);

  final CatalogStore _store;

  @override
  Future<Result<Product>> fetch(ProductId id) async {
    final product = _store.find(id);
    return product == null
        ? Result.err(NotFound('No product with id ${id.value}'))
        : Result.ok(product);
  }

  @override
  Future<Result<List<Product>>> search(String query,
      {required int limit, required int offset}) async {
    final needle = query.trim().toLowerCase();
    return Result.ok(_store.all
        .where((p) => p.name.toLowerCase().contains(needle))
        .skip(offset)
        .take(limit)
        .toList(growable: false));
  }
}
