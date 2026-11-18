import 'package:checkout_api/checkout_api.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/foundation.dart';
import 'package:identity_api/identity_api.dart';
import 'package:payments_api/payments_api.dart';
import 'package:ui_kit/ui_kit.dart';

/// One message in the inbox.
final class InboxItem {
  const InboxItem({
    required this.title,
    required this.body,
    required this.at,
    this.read = false,
  });

  final String title;
  final String body;
  final DateTime at;
  final bool read;

  InboxItem markRead() => InboxItem(title: title, body: body, at: at, read: true);
}

/// The inbox: a list of messages built only from events. It never calls
/// another module to *do* anything; it only listens, and once asks the
/// session for a display name.
final class Inbox {
  Inbox(this._session);

  final Session _session;
  final _items = <InboxItem>[];
  final _subscriptions = <Subscription>[];

  /// Unread messages, for the navigation badge.
  final unread = ValueNotifier<int>(0);

  /// Newest first.
  List<InboxItem> get items => List.unmodifiable(_items.reversed);

  void listenTo(EventBus bus) {
    _subscriptions
      ..add(bus.on<UserSignedIn>((e) => _add(
            'Welcome back',
            'Signed in as ${_session.currentUser?.displayName ?? 'you'}.',
            e.occurredAt,
          )))
      ..add(bus.on<OrderPlaced>((e) => _add(
            'Order confirmed',
            '${e.itemCount} items · ${formatMoney(e.total)}',
            e.occurredAt,
          )))
      ..add(bus.on<PaymentFailed>((e) => _add(
            'Payment declined',
            '${e.reason}. Nothing was charged.',
            e.occurredAt,
          )))
      // Another person may use this phone next: forget everything.
      ..add(bus.on<UserSignedOut>((_) => _clear()));
  }

  void markAllRead() {
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].markRead();
    }
    _refreshCount();
  }

  void stop() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();
  }

  void _add(String title, String body, DateTime at) {
    _items.add(InboxItem(title: title, body: body, at: at));
    _refreshCount();
  }

  void _clear() {
    _items.clear();
    _refreshCount();
  }

  void _refreshCount() => unread.value = _items.where((i) => !i.read).length;
}
