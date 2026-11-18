import 'package:event_bus/event_bus.dart';
import 'package:test/test.dart';

final _t = DateTime.utc(2027, 1, 1);

class UserSignedOut extends DomainEvent {
  UserSignedOut(this.userId) : super(_t);
  final String userId;
}

class OrderPlaced extends DomainEvent {
  OrderPlaced(this.orderId) : super(_t);
  final String orderId;
}

void main() {
  test('delivers only the event types a subscriber asked for', () async {
    final bus = EventBus();
    final signedOut = <String>[];
    final orders = <String>[];

    bus.on<UserSignedOut>((e) => signedOut.add(e.userId));
    bus.on<OrderPlaced>((e) => orders.add(e.orderId));

    await bus.publish(UserSignedOut('u1'));
    await bus.publish(OrderPlaced('o1'));

    expect(signedOut, ['u1']);
    expect(orders, ['o1']);
  });

  test('subscribing to DomainEvent receives everything', () async {
    final bus = EventBus();
    final all = <DomainEvent>[];
    bus.on<DomainEvent>(all.add);

    await bus.publish(UserSignedOut('u1'));
    await bus.publish(OrderPlaced('o1'));

    expect(all, hasLength(2));
  });

  test('a failing subscriber does not stop the others', () async {
    final errors = <Object>[];
    final bus = EventBus(onSubscriberError: (_, error, __) => errors.add(error));
    final received = <String>[];

    bus.on<OrderPlaced>((_) => throw StateError('notifications is broken'));
    bus.on<OrderPlaced>((e) => received.add(e.orderId));

    await bus.publish(OrderPlaced('o1'));

    expect(received, ['o1']);
    expect(errors.single, isA<StateError>());
  });

  test('waits for async handlers in subscription order', () async {
    final bus = EventBus();
    final log = <String>[];

    bus.on<OrderPlaced>((e) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      log.add('cart cleared');
    });
    bus.on<OrderPlaced>((e) => log.add('notification added'));

    await bus.publish(OrderPlaced('o1'));

    expect(log, ['cart cleared', 'notification added']);
  });

  test('cancelled subscriptions stop receiving events', () async {
    final bus = EventBus();
    var count = 0;
    final sub = bus.on<OrderPlaced>((_) => count++);

    await bus.publish(OrderPlaced('o1'));
    sub.cancel();
    sub.cancel(); // safe twice
    await bus.publish(OrderPlaced('o2'));

    expect(count, 1);
    expect(bus.subscriberCount, 0);
  });

  test('publishing on a closed bus is a programming error', () {
    final bus = EventBus()..close();
    expect(() => bus.publish(OrderPlaced('o1')), throwsStateError);
  });
}
