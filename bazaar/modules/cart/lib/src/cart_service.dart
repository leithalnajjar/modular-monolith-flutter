import 'dart:async';

import 'package:cart_api/cart_api.dart';
import 'package:catalog_api/catalog_api.dart';
import 'package:core/core.dart';

import 'catalog_pricing.dart';

/// The cart's state and rules. Implements both halves of the contract:
/// [CartReader] for modules that only look, [CartCommands] for those that
/// change it.
final class CartService implements CartReader, CartCommands {
  CartService(this._pricing, {required String currency})
      : _cart = Cart.empty(currency);

  final CatalogPricing _pricing;
  final _changes = StreamController<Cart>.broadcast();
  Cart _cart;

  @override
  Cart get current => _cart;

  @override
  Stream<Cart> get changes => _changes.stream;

  @override
  Future<Result<Cart>> add(ProductId productId, {int quantity = 1}) async {
    if (quantity <= 0) {
      return const Result.err(RuleViolation('Quantity must be at least 1'));
    }
    final existing = _lineFor(productId);
    if (existing != null) {
      // Keep the price the user saw when they first added it.
      return Result.ok(
          _replace(existing.withQuantity(existing.quantity + quantity)));
    }
    final priced = await _pricing.price(productId);
    return priced.map((p) => _append(CartLine(
          productId: p.id,
          name: p.name,
          unitPrice: p.unitPrice,
          quantity: quantity,
        )));
  }

  @override
  Future<Result<Cart>> changeQuantity(ProductId productId, int quantity) async {
    final existing = _lineFor(productId);
    if (existing == null) {
      return Result.err(NotFound('${productId.value} is not in the cart'));
    }
    if (quantity < 0) {
      return const Result.err(RuleViolation('Quantity cannot be negative'));
    }
    if (quantity == 0) {
      return Result.ok(_emit(Cart(
        lines: [
          for (final line in _cart.lines)
            if (line.productId != productId) line,
        ],
        currency: _cart.currency,
      )));
    }
    return Result.ok(_replace(existing.withQuantity(quantity)));
  }

  /// Replaces the cart with one saved earlier (Chapter 20). Not part of the
  /// public contract: only the cart's persistence calls it, at startup.
  void restore(Cart saved) => _emit(saved);

  /// Empties the cart. Not part of the public contract: only the cart's own
  /// event handlers call it (after an order is placed, or on sign-out).
  void clear() => _emit(Cart.empty(_cart.currency));

  Future<void> dispose() => _changes.close();

  CartLine? _lineFor(ProductId id) {
    for (final line in _cart.lines) {
      if (line.productId == id) return line;
    }
    return null;
  }

  Cart _append(CartLine line) => _emit(
      Cart(lines: [..._cart.lines, line], currency: _cart.currency));

  Cart _replace(CartLine updated) => _emit(Cart(
        lines: [
          for (final line in _cart.lines)
            line.productId == updated.productId ? updated : line,
        ],
        currency: _cart.currency,
      ));

  Cart _emit(Cart cart) {
    _cart = cart;
    _changes.add(cart);
    return cart;
  }
}
