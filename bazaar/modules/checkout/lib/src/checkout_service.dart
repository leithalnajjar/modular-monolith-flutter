import 'package:cart_api/cart_api.dart';
import 'package:checkout_api/checkout_api.dart';
import 'package:core/core.dart';
import 'package:event_bus/event_bus.dart';
import 'package:identity_api/identity_api.dart';
import 'package:payments_api/payments_api.dart';

/// Checkout orchestrates three other modules, through their contracts only:
/// it reads the cart, asks payments to charge, and records the order. Then
/// it announces OrderPlaced and lets everyone else react.
final class CheckoutService implements CheckoutCommands, OrderHistory {
  CheckoutService({
    required Session session,
    required CartReader cart,
    required Payments payments,
    required EventBus bus,
    required Clock clock,
  })  : _session = session,
        _cart = cart,
        _payments = payments,
        _bus = bus,
        _clock = clock;

  final Session _session;
  final CartReader _cart;
  final Payments _payments;
  final EventBus _bus;
  final Clock _clock;

  final _ordersByUser = <UserId, List<Order>>{};
  var _sequence = 0;
  var _placing = false;

  /// An order ID that was charged with an unclear outcome. A retry for the
  /// same cart total reuses it, so the payment provider can recognise the
  /// retry and never charge twice.
  ({OrderId id, Money total})? _pending;

  @override
  List<Order> get orders {
    final user = _session.currentUser;
    if (user == null) return const [];
    return List.unmodifiable((_ordersByUser[user.id] ?? const []).reversed);
  }

  @override
  Future<Result<Order>> placeOrder() async {
    if (_placing) {
      return const Result.err(RuleViolation('Your order is already on its way'));
    }
    final user = _session.currentUser;
    if (user == null) {
      return const Result.err(Unauthorized('Sign in to place an order'));
    }
    final cart = _cart.current;
    if (cart.isEmpty) {
      return const Result.err(RuleViolation('Your cart is empty'));
    }

    _placing = true;
    try {
      final pending = _pending;
      final orderId = pending != null && pending.total == cart.total
          ? pending.id
          : _newOrderId();
      _pending = (id: orderId, total: cart.total);

      final payment =
          await _payments.charge(cart.total, reference: orderId.value);
      switch (payment) {
        case Err(:final failure):
          return Result.err(failure);
        case Ok(value: final receipt):
          final order = Order(
            id: orderId,
            lines: [
              for (final line in cart.lines)
                OrderLine(
                  name: line.name,
                  unitPrice: line.unitPrice,
                  quantity: line.quantity,
                ),
            ],
            total: cart.total,
            placedAt: _clock.now(),
            paymentReference: receipt.id.value,
          );
          (_ordersByUser[user.id] ??= []).add(order);
          _pending = null;
          // The cart empties itself when it hears this (Chapter 10).
          await _bus.publish(OrderPlaced(
            orderId: order.id,
            itemCount: order.itemCount,
            total: order.total,
            at: order.placedAt,
          ));
          return Result.ok(order);
      }
    } finally {
      _placing = false;
    }
  }

  OrderId _newOrderId() =>
      OrderId('o-${_clock.now().millisecondsSinceEpoch}-${++_sequence}');
}
