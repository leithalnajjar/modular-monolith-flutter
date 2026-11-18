import 'dart:async';

import 'package:cart_api/cart_api.dart';
import 'package:catalog_api/catalog_api.dart';
import 'package:checkout_api/checkout_api.dart';
import 'package:event_bus/event_bus.dart';
import 'package:feature_flags/feature_flags.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:identity_api/identity_api.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:module_contract/module_contract.dart';

import 'add_to_cart_action.dart';
import 'cart_service.dart';
import 'catalog_pricing.dart';
import 'data/cart_persistence.dart';
import 'data/cart_storage.dart';
import 'ui/cart_screen.dart';

final class CartModule extends FeatureModule {
  CartModule({this.currency = 'USD'});

  final String currency;
  final _subscriptions = <Subscription>[];
  CartPersistence? _persistence;

  /// The number on the cart icon in the app's navigation bar.
  final _itemCount = ValueNotifier<int>(0);
  StreamSubscription<Cart>? _countSubscription;

  /// A kill switch for Chapter 20's persistence: if saved carts ever cause
  /// trouble in production, switch this off remotely and the cart goes
  /// back to living in memory, without a new release.
  static const persistFlag = Flag(
    'cart.persist',
    description: 'Keep the cart between launches (Chapter 20). Kill switch; '
        'remove once persistence has been stable for two releases.',
    defaultValue: true,
  );

  @override
  String get name => 'cart';

  @override
  List<Flag> get flags => const [persistFlag];

  @override
  void register(GetIt di) {
    // One service, published under the two contract types. Modules that
    // only read the cart cannot change it, because they never see
    // CartCommands.
    di
      ..registerLazySingleton<CartService>(
        () => CartService(CatalogPricing(di<ProductCatalog>()),
            currency: currency),
        dispose: (service) => service.dispose(),
      )
      ..registerLazySingleton<CartReader>(() => di<CartService>())
      ..registerLazySingleton<CartCommands>(() => di<CartService>())
      ..registerLazySingleton<CartStorage>(() => CartStorage(storage(di)));
  }

  @override
  Future<void> start(GetIt di) async {
    final bus = di<EventBus>();
    final cart = di<CartService>();

    // Bring back the cart from the last launch before anyone looks at it.
    if (di<FeatureFlags>().isOn(persistFlag)) {
      _persistence = CartPersistence(di<CartStorage>(), cart);
      await _persistence!.start();
    }

    // The cart decides for itself when to empty. Checkout and identity
    // only announce what happened.
    _subscriptions
      ..add(bus.on<OrderPlaced>((_) => cart.clear()))
      ..add(bus.on<UserSignedOut>((_) => cart.clear()));

    // Contribute the "Add to cart" button to the catalog's product page.
    di<ProductActions>().add(AddToCartAction(di<CartCommands>()));

    // Keep the navigation badge in step with the cart.
    _itemCount.value = cart.current.itemCount;
    _countSubscription =
        cart.changes.listen((c) => _itemCount.value = c.itemCount);
  }

  @override
  List<NavDestination> destinations(GetIt di) => [
        NavDestination(
          label: 'Cart',
          icon: Icons.shopping_cart_outlined,
          location: CartRoutes.cart,
          badge: _itemCount,
          order: 20,
        ),
      ];

  @override
  List<RouteBase> routes(GetIt di) => [
        GoRoute(
          path: CartRoutes.cart,
          builder: (context, state) => CartScreen(
            reader: di<CartReader>(),
            commands: di<CartCommands>(),
          ),
        ),
      ];

  @override
  Future<void> stop() async {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    await _countSubscription?.cancel();
    _countSubscription = null;
    await _persistence?.stop();
    _persistence = null;
  }
}
