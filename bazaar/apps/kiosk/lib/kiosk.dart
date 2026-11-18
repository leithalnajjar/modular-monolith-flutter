// apps/kiosk/lib/kiosk.dart
//
// The kiosk's composition root. Same catalog module as the shopping app,
// different app around it: one module, no sign-in, no cart, another brand.
import 'package:catalog/catalog.dart';
import 'package:catalog_api/catalog_api.dart';
import 'package:core/core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:module_contract/module_contract.dart';
import 'package:ui_kit/ui_kit.dart';

/// The kiosk's brand colour: same design system, different seed.
const kioskBrand = Color(0xFF5B3E96);

/// What the showroom has on display. In a store, the kiosk would load the
/// full range from the catalog server instead (CatalogModule(remote: ...)).
const showroom = [
  Product(
    id: ProductId('p-1'),
    name: 'Brass Desk Lamp',
    price: Money(4900, 'USD'),
    inStock: true,
  ),
  Product(
    id: ProductId('p-3'),
    name: 'Linen Notebook',
    price: Money(1800, 'USD'),
    inStock: true,
  ),
];

List<FeatureModule> kioskModules() => [const CatalogModule(seed: showroom)];

Future<ModuleHost> startKiosk() => ModuleHost.start(
  modules: kioskModules(),
  initialLocation: CatalogRoutes.products,
);

class KioskApp extends StatelessWidget {
  const KioskApp({super.key, required this.host});

  final ModuleHost host;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Bazaar Kiosk',
      theme: bazaarTheme(seed: kioskBrand),
      routerConfig: host.router,
    );
  }
}
