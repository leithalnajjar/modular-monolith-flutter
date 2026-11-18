import 'dart:async';

import 'package:cart_api/cart_api.dart';
import 'package:catalog_api/catalog_api.dart';
import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the cart screen shows: the cart, and an optional message for the
/// user (for example, why a change was refused).
final class CartViewState {
  const CartViewState(this.cart, {this.message});
  final Cart cart;
  final String? message;
}

/// Follows the cart's changes and forwards the user's edits to it.
final class CartCubit extends Cubit<CartViewState> {
  CartCubit(CartReader reader, this._commands)
      : super(CartViewState(reader.current)) {
    _subscription = reader.changes.listen((cart) => emit(CartViewState(cart)));
  }

  final CartCommands _commands;
  late final StreamSubscription<Cart> _subscription;

  Future<void> setQuantity(ProductId productId, int quantity) async {
    final result = await _commands.changeQuantity(productId, quantity);
    if (result case Err(:final failure)) {
      emit(CartViewState(state.cart, message: failure.message));
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
