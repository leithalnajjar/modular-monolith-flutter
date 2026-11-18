import 'package:core/core.dart';
import 'package:event_bus/event_bus.dart';

import 'order_id.dart';

/// An order was placed and paid for. Published by the checkout module.
///
/// It carries only what listeners need: the cart clears itself, the
/// notifications inbox shows "Order confirmed: 3 items, USD 72.50". It does
/// not carry the order lines, the user or payment details. Listeners that
/// need more ask checkout through its contract.
final class OrderPlaced extends DomainEvent {
  const OrderPlaced({
    required this.orderId,
    required this.itemCount,
    required this.total,
    required DateTime at,
  }) : super(at);

  final OrderId orderId;
  final int itemCount;
  final Money total;
}
