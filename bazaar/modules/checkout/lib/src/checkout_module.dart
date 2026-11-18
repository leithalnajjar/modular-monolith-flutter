import 'package:cart_api/cart_api.dart';
import 'package:checkout_api/checkout_api.dart';
import 'package:core/core.dart';
import 'package:event_bus/event_bus.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:identity_api/identity_api.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:module_contract/module_contract.dart';
import 'package:payments_api/payments_api.dart';

import 'checkout_service.dart';
import 'ui/checkout_screen.dart';
import 'ui/orders_screen.dart';

final class CheckoutModule extends FeatureModule {
  const CheckoutModule();

  @override
  String get name => 'checkout';

  @override
  void register(GetIt di) {
    di
      ..registerLazySingleton<CheckoutService>(() => CheckoutService(
            session: di<Session>(),
            cart: di<CartReader>(),
            payments: di<Payments>(),
            bus: di<EventBus>(),
            clock: di<Clock>(),
          ))
      ..registerLazySingleton<CheckoutCommands>(() => di<CheckoutService>())
      ..registerLazySingleton<OrderHistory>(() => di<CheckoutService>());
  }

  @override
  List<NavDestination> destinations(GetIt di) => const [
        NavDestination(
          label: 'Orders',
          icon: Icons.receipt_long_outlined,
          location: CheckoutRoutes.orders,
          order: 30,
        ),
      ];

  @override
  List<RouteBase> routes(GetIt di) => [
        GoRoute(
          path: CheckoutRoutes.checkout,
          redirect: (_, state) => signInRedirect(di<Session>(), state.uri),
          builder: (_, __) => CheckoutScreen(
            cart: di<CartReader>(),
            commands: di<CheckoutCommands>(),
          ),
        ),
        GoRoute(
          path: CheckoutRoutes.orders,
          redirect: (_, state) => signInRedirect(di<Session>(), state.uri),
          builder: (_, __) => OrdersScreen(history: di<OrderHistory>()),
        ),
      ];
}
