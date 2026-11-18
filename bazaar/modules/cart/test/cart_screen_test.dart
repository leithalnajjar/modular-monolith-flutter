import 'package:cart/cart.dart';
import 'package:cart_api/cart_api.dart';
import 'package:catalog_api/catalog_api.dart';
import 'package:catalog_api/testing.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:material_ui/material_ui.dart';
import 'package:module_contract/module_contract.dart';

const _lamp = Product(
    id: ProductId('lamp'),
    name: 'Lamp',
    price: Money(4900, 'USD'),
    inStock: true);

/// The catalog's contract, faked: the cart's tests never need the real one.
final class _FakeCatalogModule extends FeatureModule {
  @override
  String get name => 'catalog';

  @override
  void register(GetIt di) {
    di
      ..registerSingleton<ProductCatalog>(FakeProductCatalog([_lamp]))
      ..registerSingleton<ProductActions>(FakeProductActions());
  }
}

void main() {
  late ModuleHost host;

  setUp(() async {
    host = await ModuleHost.start(
      modules: [_FakeCatalogModule(), CartModule()],
      initialLocation: CartRoutes.cart,
    );
  });

  tearDown(() => host.stop());

  Widget app() => MaterialApp.router(routerConfig: host.router);

  testWidgets('an empty cart says so', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Your cart is empty'), findsOneWidget);
  });

  testWidgets('quantities change, totals follow, zero removes the line',
      (tester) async {
    await host.di<CartCommands>().add(_lamp.id);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text(r'Total $49.00'), findsOneWidget);

    await tester.tap(find.byTooltip('One more'));
    await tester.pumpAndSettle();
    expect(find.text(r'Total $98.00'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('qty-lamp'))).data, '2');

    await tester.tap(find.byTooltip('One less'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('One less'));
    await tester.pumpAndSettle();
    expect(find.text('Your cart is empty'), findsOneWidget);
  });

  testWidgets('the cart contributes a Cart entry with a live badge',
      (tester) async {
    final entry = host.destinations.single;
    expect(entry.label, 'Cart');
    expect(entry.badge!.value, 0);

    await host.di<CartCommands>().add(_lamp.id, quantity: 3);
    await tester.pump(); // let the cart's change reach the badge

    expect(entry.badge!.value, 3);
  });
}
