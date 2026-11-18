import 'package:material_ui/material_ui.dart';
import 'package:ui_kit/ui_kit.dart';

import '../inbox.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key, required this.inbox});

  final Inbox inbox;

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  late final List<InboxItem> _items = widget.inbox.items;

  @override
  void initState() {
    super.initState();
    // Opening the inbox reads everything; the list keeps showing which
    // messages were new when the user arrived. After the first frame:
    // the unread count drives the navigation badge, and changing it while
    // the screen is still being built would rebuild the shell mid-build.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => widget.inbox.markAllRead());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      body: _items.isEmpty
          ? const EmptyState(
              message: 'No messages yet',
              icon: Icons.notifications_none,
            )
          : ListView(
              children: [
                for (final item in _items)
                  ListTile(
                    leading: Icon(item.read
                        ? Icons.mark_email_read_outlined
                        : Icons.mark_email_unread_outlined),
                    title: Text(item.title,
                        style: item.read
                            ? null
                            : const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(item.body),
                  ),
              ],
            ),
    );
  }
}
