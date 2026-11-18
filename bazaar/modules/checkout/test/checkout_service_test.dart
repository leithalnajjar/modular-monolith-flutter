import 'dart:async';

import 'package:cart_api/cart_api.dart';
import 'package:catalog_api/catalog_api.dart';
import 'package:checkout/src/checkout_service.dart';
import 'package:checkout_api/checkout_api.dart';
import 'package:core/core.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_api/identity_api.dart';
import 'package:payments_api/payments_api.dart';

// ---- Fakes of the three contracts checkout depends on ----

final class _Session implements Session {
  SignedInUser? user =
      const SignedInUser(id: UserId('u-1'), displayName: 'Test User');

  @override
  SignedInUser? get currentUser => user;

  @override
  bool get isSignedIn => user != null;

  @override
  Stream<SignedInUser?> get changes => const Stream.empty();
}

final class _Cart implements CartReader {
  Cart cart = const Cart.empty('USD');

  @override
  Cart get current => cart;

  @override
  Stream<Cart> get changes => const Stream.empty();
}

final class _Payments implements Payments {
  final references = <String>[];
  Result<PaymentReceipt> Function(Money amount)? answer;
  Completer<void>? gate;

  @override
  Future<Result<PaymentReceipt>> charge(Money amount,
      {required String reference}) async {
    references.add(reference);
    await gate?.future;
    return answer?.call(amount) ??
        Result.ok(PaymentReceipt(
            id: PaymentId('pay-${references.length}'),
            amount: amount,
            at: DateTime.utc(2027)));
  }
}

const _lampLine = CartLine(
    productId: ProductId('lamp'),
    name: 'Lamp',
    unitPrice: Money(4900, 'USD'),
    quantity: 2);

void main() {
  late _Session session;
  late _Cart cart;
  late _Payments payments;
  late List<DomainEvent> published;
  late CheckoutService checkout;

  setUp(() {
    session = _Session();
    cart = _Cart()..cart = const Cart(lines: [_lampLine], currency: 'USD');
    payments = _Payments();
    final bus = EventBus();
    published = [];
    bus.on<DomainEvent>(published.add);
    checkout = CheckoutService(
      session: session,
      cart: cart,
      payments: payments,
      bus: bus,
      clock: FixedClock(DateTime.utc(2027, 5, 1, 12)),
    );
  });

  test('places an order: charges the total, records it, announces it',
      () async {
    final order = (await checkout.placeOrder()).valueOrNull!;

    expect(order.total, const Money(9800, 'USD'));
    expect(order.lines.single.name, 'Lamp');
    expect(order.paymentReference, 'pay-1');
    expect(checkout.orders.single.id, order.id);

    final event = published.single as OrderPlaced;
    expect(event.orderId, order.id);
    expect(event.itemCount, 2);
    expect(event.total, const Money(9800, 'USD'));
  });

  test('signed-out users and empty carts never reach payments', () async {
    session.user = null;
    expect((await checkout.placeOrder() as Err).failure, isA<Unauthorized>());

    session.user =
        const SignedInUser(id: UserId('u-1'), displayName: 'Test User');
    cart.cart = const Cart.empty('USD');
    expect((await checkout.placeOrder() as Err).failure, isA<RuleViolation>());

    expect(payments.references, isEmpty);
  });

  test('a declined payment records nothing and announces nothing', () async {
    payments.answer =
        (_) => const Result.err(RuleViolation('Payment declined: no funds'));

    final failure = (await checkout.placeOrder() as Err).failure;

    expect(failure.message, 'Payment declined: no funds');
    expect(checkout.orders, isEmpty);
    expect(published, isEmpty);
  });

  test('a retry after an unclear payment reuses the same order ID', () async {
    payments.answer = (_) => const Result.err(Unavailable('timeout'));
    await checkout.placeOrder();

    payments.answer = null;
    await checkout.placeOrder();

    expect(payments.references, hasLength(2));
    expect(payments.references[0], payments.references[1]);
  });

  test('a double tap places one order', () async {
    payments.gate = Completer<void>();
    final first = checkout.placeOrder();
    final second = await checkout.placeOrder();
    payments.gate!.complete();
    await first;

    expect((second as Err).failure.message, 'Your order is already on its way');
    expect(payments.references, hasLength(1));
  });

  test('history belongs to the signed-in user', () async {
    await checkout.placeOrder();
    session.user = const SignedInUser(id: UserId('u-2'), displayName: 'Other');
    expect(checkout.orders, isEmpty);
  });
}
