import 'package:cart_api/cart_api.dart';
import 'package:checkout_api/checkout_api.dart';
import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class CheckoutState {
  const CheckoutState();
}

/// Showing the summary, waiting for "Place order".
final class CheckoutReady extends CheckoutState {
  const CheckoutReady(this.cart, {this.error});
  final Cart cart;

  /// Why the last attempt failed, if it did.
  final String? error;
}

final class CheckoutPlacing extends CheckoutState {
  const CheckoutPlacing(this.cart);
  final Cart cart;
}

final class CheckoutDone extends CheckoutState {
  const CheckoutDone(this.order);
  final Order order;
}

final class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit(CartReader cart, this._commands)
      : super(CheckoutReady(cart.current));

  final CheckoutCommands _commands;

  Future<void> placeOrder() async {
    final current = state;
    if (current is! CheckoutReady) return;
    emit(CheckoutPlacing(current.cart));
    final result = await _commands.placeOrder();
    emit(switch (result) {
      Ok(value: final order) => CheckoutDone(order),
      Err(:final failure) => CheckoutReady(current.cart, error: failure.message),
    });
  }
}
