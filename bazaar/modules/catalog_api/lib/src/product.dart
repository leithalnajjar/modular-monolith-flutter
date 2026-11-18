import 'package:core/core.dart';

/// Identifies a product. A distinct type, so a `ProductId` can never be
/// passed where an `OrderId` or a plain `String` is expected.
extension type const ProductId(String value) {}

/// A product as other modules see it: what you need to show it and price it.
///
/// This is the catalog's *public* view. The catalog's internal model can
/// have many more fields (suppliers, stock per warehouse, SEO text) without
/// any other module knowing or caring.
final class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.inStock,
    this.imageUrl,
  });

  final ProductId id;
  final String name;
  final Money price;
  final bool inStock;
  final String? imageUrl;

  @override
  bool operator ==(Object other) =>
      other is Product &&
      other.id == id &&
      other.name == name &&
      other.price == price &&
      other.inStock == inStock &&
      other.imageUrl == imageUrl;

  @override
  int get hashCode => Object.hash(id, name, price, inStock, imageUrl);

  @override
  String toString() => 'Product($id, $name, $price)';
}
