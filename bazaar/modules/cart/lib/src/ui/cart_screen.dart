import 'package:cart_api/cart_api.dart';
import 'package:catalog_api/catalog_api.dart';
import 'package:checkout_api/checkout_api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_kit/ui_kit.dart';

import 'cart_cubit.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key, required this.reader, required this.commands});

  final CartReader reader;
  final CartCommands commands;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CartCubit(reader, commands),
      child: BlocConsumer<CartCubit, CartViewState>(
        listenWhen: (_, next) => next.message != null,
        listener: (context, state) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(state.message!))),
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Your cart')),
          body: state.cart.isEmpty
              ? const EmptyState(
                  message: 'Your cart is empty',
                  icon: Icons.shopping_cart_outlined,
                )
              : ListView(
                  children: [
                    for (final line in state.cart.lines)
                      _CartLineTile(line: line),
                  ],
                ),
          bottomNavigationBar: state.cart.isEmpty
              ? null
              : _CheckoutBar(total: formatMoney(state.cart.total)),
        ),
      ),
    );
  }
}

class _CartLineTile extends StatelessWidget {
  const _CartLineTile({required this.line});

  final CartLine line;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CartCubit>();
    return ListTile(
      title: Text(line.name),
      subtitle: Text('${formatMoney(line.unitPrice)} each'),
      // Tapping a line shows the product, owned by the catalog module.
      onTap: () => context.push(CatalogRoutes.productDetails(line.productId)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'One less',
            icon: const Icon(Icons.remove),
            onPressed: () =>
                cubit.setQuantity(line.productId, line.quantity - 1),
          ),
          Text('${line.quantity}', key: Key('qty-${line.productId.value}')),
          IconButton(
            tooltip: 'One more',
            icon: const Icon(Icons.add),
            onPressed: () =>
                cubit.setQuantity(line.productId, line.quantity + 1),
          ),
        ],
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.total});

  final String total;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.m),
        child: Row(
          children: [
            Expanded(
              child: Text('Total $total',
                  key: const Key('cart-total'),
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            // Checkout owns this location (Chapter 14).
            FilledButton(
              onPressed: () => context.push(CheckoutRoutes.checkout),
              child: const Text('Checkout'),
            ),
          ],
        ),
      ),
    );
  }
}
