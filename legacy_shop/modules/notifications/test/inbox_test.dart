import 'package:flutter_test/flutter_test.dart';
import 'package:notifications/notifications.dart';

/// Tests that could not exist before the inbox left AppState: no sign-in,
/// no API, no screens. Just the inbox's own rules.
void main() {
  test('counts unread messages and marks them read', () {
    final inbox = Inbox()
      ..add(InboxMessage('Welcome back', 'Hi'))
      ..add(InboxMessage('Order confirmed', '1 items'));
    expect(inbox.unreadCount, 2);

    inbox.markAllRead();

    expect(inbox.unreadCount, 0);
    expect(inbox.items.every((m) => m.read), isTrue);
  });

  test('clear forgets everything and tells listeners', () {
    var notified = 0;
    final inbox = Inbox()
      ..add(InboxMessage('Welcome back', 'Hi'))
      ..addListener(() => notified++);

    inbox.clear();

    expect(inbox.items, isEmpty);
    expect(notified, 1);
  });
}
