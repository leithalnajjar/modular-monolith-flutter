import 'cart.dart';

/// Read-only access to the cart. Checkout depends on this, and only this.
abstract interface class CartReader {
  /// The cart as it is right now.
  Cart get current;

  /// Emits the new cart after every change.
  Stream<Cart> get changes;
}
