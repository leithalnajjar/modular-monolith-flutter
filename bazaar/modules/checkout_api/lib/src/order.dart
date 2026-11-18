import 'package:core/core.dart';

import 'order_id.dart';

/// One line of a placed order: a permanent record of what was bought, at
/// what price. It never changes, even if the product is renamed, repriced
/// or deleted from the catalog.
final class OrderLine {
  const OrderLine({
    required this.name,
    required this.unitPrice,
    required this.quantity,
  });

  final String name;
  final Money unitPrice;
  final int quantity;

  Money get total => unitPrice.times(quantity);
}

/// A placed and paid order.
final class Order {
  const Order({
    required this.id,
    required this.lines,
    required this.total,
    required this.placedAt,
    required this.paymentReference,
  });

  final OrderId id;
  final List<OrderLine> lines;
  final Money total;
  final DateTime placedAt;

  /// The payment provider's identifier, for support and refunds.
  final String paymentReference;

  int get itemCount => lines.fold(0, (sum, line) => sum + line.quantity);
}

/// Placing orders. Checkout's own screen is the only caller in Bazaar.
abstract interface class CheckoutCommands {
  /// Charges the current cart and records it as an order.
  ///
  /// Fails with [Unauthorized] when nobody is signed in, [RuleViolation]
  /// for an empty cart or a declined payment, and [Unavailable] when the
  /// payment could not be confirmed (it is then safe to try again).
  Future<Result<Order>> placeOrder();
}

/// The signed-in user's past orders, newest first.
abstract interface class OrderHistory {
  List<Order> get orders;
}
