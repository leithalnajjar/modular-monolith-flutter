import 'package:catalog_api/catalog_api.dart' show ProductId;
import 'package:core/core.dart';

import 'cart.dart';

/// Changes to the cart. Every command validates its input and returns the
/// new cart, or a [Failure] that explains why nothing changed.
abstract interface class CartCommands {
  /// Adds [quantity] of a product, pricing it with the catalog's current
  /// price. Adding a product that is already in the cart increases its
  /// quantity.
  Future<Result<Cart>> add(ProductId productId, {int quantity = 1});

  /// Sets the quantity of a line. A quantity of 0 removes the line.
  Future<Result<Cart>> changeQuantity(ProductId productId, int quantity);
}
