import 'package:material_ui/material_ui.dart';
import 'package:notifications/notifications.dart';

import '../app_state.dart';
import '../widgets/price_label.dart';
import 'cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.state});
  final AppState state;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var _tab = 0;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final pages = [
      ListView(
        children: [
          for (final p in state.products)
            ListTile(
              title: Text(p.name),
              subtitle: PriceLabel(p.price),
              trailing: IconButton(
                tooltip: 'Add ${p.name}',
                icon: const Icon(Icons.add_shopping_cart),
                onPressed: () => state.addToCart(p),
              ),
            ),
        ],
      ),
      CartScreen(state: state),
      InboxScreen(inbox: state.inbox),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text('Hello, ${state.currentUser?.name}'),
        actions: [
          TextButton(onPressed: state.logout, child: const Text('Sign out')),
        ],
      ),
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) {
          setState(() => _tab = i);
          if (i == 2) state.markNotificationsRead();
        },
        destinations: [
          const NavigationDestination(icon: Icon(Icons.store), label: 'Shop'),
          NavigationDestination(
            icon: const Icon(Icons.shopping_cart),
            label: 'Cart (${state.cart.length})',
          ),
          NavigationDestination(
            icon: const Icon(Icons.mail),
            label: 'Inbox (${state.unreadCount})',
          ),
        ],
      ),
    );
  }
}
