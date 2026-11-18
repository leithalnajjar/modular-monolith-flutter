import 'product.dart';

/// Route locations owned by the catalog module.
///
/// Other modules navigate with these helpers instead of hard-coding paths,
/// so the catalog can change its URLs in one place.
abstract final class CatalogRoutes {
  static const products = '/products';
  static const productDetailsPattern = '/products/:id';

  static String productDetails(ProductId id) => '/products/${id.value}';
}
