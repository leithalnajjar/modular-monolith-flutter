import 'package:cart_api/cart_api.dart';
import 'package:checkout_api/checkout_api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_kit/ui_kit.dart';

import 'checkout_cubit.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key, required this.cart, required this.commands});

  final CartReader cart;
  final CheckoutCommands commands;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CheckoutCubit(cart, commands),
      child: Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: BlocBuilder<CheckoutCubit, CheckoutState>(
          builder: (context, state) => switch (state) {
            CheckoutDone(:final order) => _Confirmation(order: order),
            CheckoutPlacing(:final cart) => _Summary(cart: cart, busy: true),
            CheckoutReady(:final cart, :final error) =>
              _Summary(cart: cart, error: error),
          },
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.cart, this.busy = false, this.error});

  final Cart cart;
  final bool busy;
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (cart.isEmpty) {
      return const EmptyState(message: 'Your cart is empty');
    }
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(Spacing.m),
      children: [
        for (final line in cart.lines)
          ListTile(
            title: Text(line.name),
            subtitle: Text('${line.quantity} × ${formatMoney(line.unitPrice)}'),
            trailing: PriceText(line.total),
          ),
        const Divider(),
        ListTile(
          title: Text('Total', style: theme.textTheme.titleMedium),
          trailing: PriceText(cart.total,
              key: const Key('checkout-total'),
              style: theme.textTheme.titleMedium),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.s),
            child: Text(error!, style: TextStyle(color: theme.colorScheme.error)),
          ),
        const SizedBox(height: Spacing.m),
        FilledButton(
          onPressed: busy ? null : () => context.read<CheckoutCubit>().placeOrder(),
          child: Text(busy ? 'Placing order…' : 'Place order'),
        ),
      ],
    );
  }
}

class _Confirmation extends StatelessWidget {
  const _Confirmation({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 64),
            const SizedBox(height: Spacing.m),
            Text('Thank you! Your order is placed.',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: Spacing.s),
            Text('${order.itemCount} items · ${formatMoney(order.total)}'),
            const SizedBox(height: Spacing.l),
            OutlinedButton(
              onPressed: () => context.go(CheckoutRoutes.orders),
              child: const Text('View orders'),
            ),
          ],
        ),
      ),
    );
  }
}
