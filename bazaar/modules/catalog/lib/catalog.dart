/// The catalog module.
///
/// Only the app (the composition root) imports this library. It exposes the
/// module, its configuration, and one factory for tests; every class that
/// does real work stays in `lib/src/` and is invisible from outside.
library;

import 'package:catalog_api/catalog_api.dart';
import 'package:core/core.dart';

import 'src/caching_product_catalog.dart';
import 'src/data/catalog_store.dart';
import 'src/data/seeded_product_source.dart';

export 'src/catalog_module.dart' show CatalogModule, CatalogRemote;

/// Creates the catalog's implementation of [ProductCatalog] over an
/// in-memory list of products.
ProductCatalog createProductCatalog({
  List<Product> seed = const [],
  Clock clock = const SystemClock(),
}) =>
    CachingProductCatalog(SeededProductSource(CatalogStore(seed)), clock);
