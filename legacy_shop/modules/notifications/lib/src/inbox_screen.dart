import 'package:material_ui/material_ui.dart';

import 'inbox.dart';

/// Moved from the app's screens/ folder. It now needs the inbox only,
/// not the whole AppState.
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key, required this.inbox});
  final Inbox inbox;

  @override
  Widget build(BuildContext context) {
    final items = inbox.items.reversed.toList();
    if (items.isEmpty) return const Center(child: Text('No messages'));
    return ListView(
      children: [
        for (final n in items)
          ListTile(
            title: Text(n.title,
                style: n.read
                    ? null
                    : const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(n.body),
          ),
      ],
    );
  }
}
