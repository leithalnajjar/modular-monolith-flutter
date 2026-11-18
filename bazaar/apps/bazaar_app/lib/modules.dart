// apps/bazaar_app/lib/modules.dart
//
// The composition root: the one place in Bazaar that knows every module.
// Adding a module to the app means adding one line to this list.
import 'package:cart/cart.dart';
import 'package:catalog/catalog.dart';
import 'package:catalog_api/catalog_api.dart';
import 'package:checkout/checkout.dart';
import 'package:feature_flags/feature_flags.dart';
import 'package:http/http.dart' as http;
import 'package:identity/identity.dart';
import 'package:module_contract/module_contract.dart';
import 'package:notifications/notifications.dart';
import 'package:payments/payments.dart';
import 'package:storage/storage.dart';

import 'config.dart';
import 'demo_data.dart';
import 'shell.dart';

/// Every module of this build, configured for [config].
List<FeatureModule> bazaarModules([
  BazaarConfig config = const BazaarConfig(),
]) => [
  // The demo gateway accepts demo@bazaar.dev / bazaar123. A release
  // build passes an adapter for the real backend here instead.
  const IdentityModule(gateway: DemoAuthGateway()),
  switch (config.catalogUrl) {
    final url? => CatalogModule(remote: CatalogRemote(url, http.Client())),
    null => const CatalogModule(seed: demoProducts),
  },
  CartModule(currency: 'USD'),
  // No real money in the sample app. Production passes a real provider.
  PaymentsModule(gateway: FakePaymentGateway()),
  const CheckoutModule(),
  if (config.flags.isOn(AppFlags.inbox)) NotificationsModule(),
];

/// Every flag this app knows about: its own switches, and the flags of
/// every module it can include (with every optional module switched on).
List<Flag> declaredFlags() => [
  ...AppFlags.all,
  for (final module in bazaarModules(
    BazaarConfig(
      flags: FlagValues({for (final flag in AppFlags.all) flag.name: true}),
    ),
  ))
    ...module.flags,
];

/// Starts Bazaar: every module, inside the app's navigation shell.
///
/// [storage] is where modules keep data between launches. The app passes
/// the device's preferences; tests leave it out and get memory.
Future<ModuleHost> startBazaar({
  BazaarConfig config = const BazaarConfig(),
  String initialLocation = CatalogRoutes.products,
  KeyValueStore? storage,
}) async {
  late final ModuleHost host;
  host = await ModuleHost.start(
    modules: bazaarModules(config),
    flags: config.flags,
    storage: storage,
    initialLocation: initialLocation,
    shell: (context, state, child) => BazaarShell(
      destinations: host.destinations,
      location: state.uri.path,
      child: child,
    ),
  );
  return host;
}
