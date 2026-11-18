import 'package:checkout_api/checkout_api.dart';
import 'package:core/core.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_api/identity_api.dart';
import 'package:notifications/src/inbox.dart';
import 'package:payments_api/payments_api.dart';

final _at = DateTime.utc(2027, 6, 1, 10);

final class _Session implements Session {
  @override
  SignedInUser? get currentUser =>
      const SignedInUser(id: UserId('u-1'), displayName: 'Sara');

  @override
  bool get isSignedIn => true;

  @override
  Stream<SignedInUser?> get changes => const Stream.empty();
}

void main() {
  late EventBus bus;
  late Inbox inbox;

  setUp(() {
    bus = EventBus();
    inbox = Inbox(_Session())..listenTo(bus);
  });

  test('builds messages from other modules\' events, newest first', () async {
    await bus.publish(UserSignedIn(const UserId('u-1'), at: _at));
    await bus.publish(OrderPlaced(
        orderId: const OrderId('o-1'),
        itemCount: 3,
        total: const Money(7250, 'USD'),
        at: _at));
    await bus.publish(PaymentFailed(
        reference: 'o-2', reason: 'Insufficient funds', at: _at));

    expect(inbox.items.map((i) => i.title),
        ['Payment declined', 'Order confirmed', 'Welcome back']);
    expect(inbox.items[1].body, r'3 items · $72.50');
    expect(inbox.items[2].body, 'Signed in as Sara.');
    expect(inbox.unread.value, 3);
  });

  test('marking read clears the badge', () async {
    await bus.publish(UserSignedIn(const UserId('u-1'), at: _at));
    inbox.markAllRead();
    expect(inbox.unread.value, 0);
    expect(inbox.items.single.read, isTrue);
  });

  test('signing out forgets everything', () async {
    await bus.publish(UserSignedIn(const UserId('u-1'), at: _at));
    await bus.publish(UserSignedOut(const UserId('u-1'), at: _at));
    expect(inbox.items, isEmpty);
    expect(inbox.unread.value, 0);
  });

  test('stop cancels every subscription', () {
    expect(bus.subscriberCount, 4);
    inbox.stop();
    expect(bus.subscriberCount, 0);
  });
}
