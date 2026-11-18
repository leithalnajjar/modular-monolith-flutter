import 'package:catalog_api/catalog_api.dart';
import 'package:core/core.dart';

/// Where the catalog's products really come from. A port, private to the
/// catalog: the rest of the app only ever sees [ProductCatalog].
abstract interface class ProductSource {
  Future<Result<Product>> fetch(ProductId id);

  Future<Result<List<Product>>> search(String query,
      {required int limit, required int offset});
}
