import 'package:checkout_api/checkout_api.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_kit/ui_kit.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key, required this.history});

  final OrderHistory history;

  @override
  Widget build(BuildContext context) {
    final orders = history.orders;
    return Scaffold(
      appBar: AppBar(title: const Text('Your orders')),
      body: orders.isEmpty
          ? const EmptyState(
              message: 'No orders yet',
              icon: Icons.receipt_long_outlined,
            )
          : ListView(
              children: [
                for (final order in orders)
                  ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: PriceText(order.total),
                    subtitle: Text('${order.itemCount} items · '
                        '${formatDate(order.placedAt)}'),
                  ),
              ],
            ),
    );
  }
}
