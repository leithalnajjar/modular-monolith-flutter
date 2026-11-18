// modules/notifications/lib/src/inbox.dart
import 'package:material_ui/material_ui.dart';

/// One message, in the inbox's own words. It replaced the app's
/// AppNotification here, which removed the module's last dependency on
/// the app.
final class InboxMessage {
  InboxMessage(this.title, this.body, {this.read = false});

  final String title;
  final String body;
  final bool read;

  InboxMessage markRead() => InboxMessage(title, body, read: true);
}

/// The inbox, moved out of AppState.
class Inbox extends ChangeNotifier {
  final _items = <InboxMessage>[];

  List<InboxMessage> get items => List.unmodifiable(_items);

  int get unreadCount => _items.where((n) => !n.read).length;

  void replaceAll(Iterable<InboxMessage> items) {
    _items
      ..clear()
      ..addAll(items);
    notifyListeners();
  }

  void add(InboxMessage item) {
    _items.add(item);
    notifyListeners();
  }

  void markAllRead() {
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].markRead();
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
