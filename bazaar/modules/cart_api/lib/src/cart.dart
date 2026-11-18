import 'package:catalog_api/catalog_api.dart' show ProductId;
import 'package:core/core.dart';

/// One product in the cart, with the price it had when it was added.
///
/// Not the catalog's `Product`: the cart keeps its own copy of the name and
/// the unit price, so the cart does not change under the user's feet when
/// the catalog does.
final class CartLine {
  const CartLine({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
  }) : assert(quantity > 0);

  final ProductId productId;
  final String name;
  final Money unitPrice;
  final int quantity;

  Money get total => unitPrice.times(quantity);

  CartLine withQuantity(int quantity) => CartLine(
        productId: productId,
        name: name,
        unitPrice: unitPrice,
        quantity: quantity,
      );

  @override
  bool operator ==(Object other) =>
      other is CartLine &&
      other.productId == productId &&
      other.name == name &&
      other.unitPrice == unitPrice &&
      other.quantity == quantity;

  @override
  int get hashCode => Object.hash(productId, name, unitPrice, quantity);
}

/// An immutable snapshot of the cart.
final class Cart {
  const Cart({required this.lines, required this.currency});

  const Cart.empty(this.currency) : lines = const [];

  final List<CartLine> lines;
  final String currency;

  bool get isEmpty => lines.isEmpty;

  int get itemCount => lines.fold(0, (sum, line) => sum + line.quantity);

  Money get total =>
      lines.fold(Money.zero(currency), (sum, line) => sum + line.total);
}
