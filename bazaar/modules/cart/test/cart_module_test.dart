import 'package:cart/cart.dart';
import 'package:cart_api/cart_api.dart';
import 'package:catalog_api/catalog_api.dart';
import 'package:catalog_api/testing.dart';
import 'package:checkout_api/checkout_api.dart';
import 'package:core/core.dart';
import 'package:event_bus/event_bus.dart';
import 'package:feature_flags/feature_flags.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:identity_api/identity_api.dart';
import 'package:module_contract/module_contract.dart';
import 'package:storage/storage.dart';

final _at = DateTime.utc(2027, 1, 1);

const _lamp = Product(
    id: ProductId('lamp'),
    name: 'Lamp',
    price: Money(4900, 'USD'),
    inStock: true);

/// Stands in for the real catalog module. The cart's tests depend only on
/// the catalog's *contract*, so they register their own implementation of
/// it, exactly like the real module would.
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
    host = await ModuleHost.start(modules: [
      _FakeCatalogModule(),
      CartModule(),
    ]);
  });

  tearDown(() => host.stop());

  Future<void> addLamp() =>
      host.di<CartCommands>().add(const ProductId('lamp'));

  test('the cart empties itself when an order is placed', () async {
    await addLamp();
    expect(host.di<CartReader>().current.itemCount, 1);

    await host.di<EventBus>().publish(OrderPlaced(
          orderId: const OrderId('o-1'),
          itemCount: 1,
          total: const Money(4900, 'USD'),
          at: _at,
        ));

    expect(host.di<CartReader>().current.isEmpty, isTrue);
  });

  test('the cart empties itself when the user signs out', () async {
    await addLamp();
    await host
        .di<EventBus>()
        .publish(UserSignedOut(const UserId('u-1'), at: _at));
    expect(host.di<CartReader>().current.isEmpty, isTrue);
  });

  test('reader and commands are the same cart', () async {
    await addLamp();
    expect(host.di<CartReader>().current.lines.single.name, 'Lamp');
  });

  test('the cart adds "Add to cart" to the product page', () async {
    final actions = host.di<ProductActions>().all;
    expect(actions.map((a) => a.label), ['Add to cart']);

    final message = await actions.single.run(const ProductId('lamp'));
    expect(message.valueOrNull, 'Added Lamp to your cart');
  });

  test("stop cancels the cart's subscriptions", () async {
    final bus = host.di<EventBus>();
    expect(bus.subscriberCount, 2);

    await host.modules.whereType<CartModule>().single.stop();

    expect(bus.subscriberCount, 0);
  });

  group('persistence', () {
    Future<ModuleHost> startWith(KeyValueStore store) => ModuleHost.start(
          modules: [_FakeCatalogModule(), CartModule()],
          storage: store,
        );

    test('the cart survives a restart', () async {
      final store = InMemoryKeyValueStore();
      final first = await startWith(store);
      await first.di<CartCommands>().add(const ProductId('lamp'), quantity: 2);
      await first.stop(); // waits for the last write

      final second = await startWith(store);
      addTearDown(second.stop);

      expect(second.di<CartReader>().current.itemCount, 2);
    });

    test('with cart.persist off, nothing is saved', () async {
      final store = InMemoryKeyValueStore();
      final app = await ModuleHost.start(
        modules: [_FakeCatalogModule(), CartModule()],
        storage: store,
        flags: const FlagValues({'cart.persist': false}),
      );
      await app.di<CartCommands>().add(const ProductId('lamp'));
      await app.stop();

      expect(await store.keys(), isEmpty);
    });

    test('signing out leaves nothing of the cart in storage', () async {
      final store = InMemoryKeyValueStore();
      final app = await startWith(store);
      await app.di<CartCommands>().add(const ProductId('lamp'));
      await app
          .di<EventBus>()
          .publish(UserSignedOut(const UserId('u-1'), at: _at));
      await app.stop();

      expect(await store.keys(), isEmpty);
    });
  });
}
