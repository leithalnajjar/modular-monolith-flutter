import 'package:catalog_api/catalog_api.dart';

/// The catalog's own storage. Private to the module: no other module can
/// import it, so no other module can read or change products behind the
/// catalog's back.
final class CatalogStore {
  CatalogStore(Iterable<Product> seed)
      : _byId = {for (final p in seed) p.id: p};

  final Map<ProductId, Product> _byId;

  Product? find(ProductId id) => _byId[id];

  Iterable<Product> get all => _byId.values;
}
