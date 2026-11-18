import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../widgets/price_label.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    if (state.cart.isEmpty) return const Center(child: Text('Cart is empty'));
    return ListView(
      children: [
        for (final item in state.cart)
          ListTile(
            title: Text(item.product.name),
            subtitle: Text('x${item.quantity}'),
            trailing: PriceLabel(item.product.price * item.quantity),
          ),
        ListTile(
          title: const Text('Total'),
          trailing: PriceLabel(state.cartTotal),
        ),
        FilledButton(
          onPressed: state.placeOrder,
          child: const Text('Place order'),
        ),
      ],
    );
  }
}
