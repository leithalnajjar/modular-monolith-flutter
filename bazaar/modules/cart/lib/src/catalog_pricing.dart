import 'package:catalog_api/catalog_api.dart';
import 'package:core/core.dart';

/// What the cart needs to know about a product: nothing more.
final class PricedProduct {
  const PricedProduct(this.id, this.name, this.unitPrice);
  final ProductId id;
  final String name;
  final Money unitPrice;
}

/// The cart's anti-corruption layer in front of the catalog.
///
/// This is the only class in the cart that talks to [ProductCatalog]. It
/// translates the catalog's model and rules into the cart's: a product the
/// catalog has but cannot sell is, for the cart, a rule violation.
final class CatalogPricing {
  CatalogPricing(this._catalog);

  final ProductCatalog _catalog;

  Future<Result<PricedProduct>> price(ProductId id) async {
    final result = await _catalog.getProduct(id);
    return switch (result) {
      Ok(value: Product(inStock: false, :final name)) =>
        Result.err(RuleViolation('$name is out of stock')),
      Ok(:final value) =>
        Result.ok(PricedProduct(value.id, value.name, value.price)),
      Err(:final failure) => Result.err(failure),
    };
  }
}
