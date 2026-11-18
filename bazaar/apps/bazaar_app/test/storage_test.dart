import 'package:bazaar_app/modules.dart';
import 'package:bazaar_app/preferences_store.dart';
import 'package:cart_api/cart_api.dart';
import 'package:catalog_api/catalog_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity/identity.dart';
import 'package:identity_api/identity_api.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:storage/storage.dart';

void main() {
  test('the preferences adapter reads, writes, lists and deletes', () async {
    // The plugin's own in-memory stand-in for the platform side.
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final store = PreferencesStore();

    await store.write('cart/cart', '{"v":2}');
    expect(await store.read('cart/cart'), '{"v":2}');
    expect(await store.keys(), {'cart/cart'});

    await store.delete('cart/cart');
    expect(await store.keys(), isEmpty);
  });

  test(
    'every stored key belongs to a module, and sign-out clears them',
    () async {
      final store = InMemoryKeyValueStore();
      final host = await startBazaar(storage: store);
      addTearDown(host.stop);

      await host.di<SessionCommands>().signIn(
        DemoAuthGateway.email,
        DemoAuthGateway.password,
      );
      await host.di<CartCommands>().add(const ProductId('p-1'));
      await pumpEventQueue();

      // A storage audit: the first part of every key names its owner.
      final owners = {for (final m in host.modules) m.name};
      final keys = await store.keys();
      expect(keys, isNotEmpty);
      expect(keys.map((k) => k.split('/').first), everyElement(isIn(owners)));

      await host.di<SessionCommands>().signOut();
      await pumpEventQueue();
      expect(
        await store.keys(),
        isEmpty,
        reason: 'nothing of the previous user may stay on the device',
      );
    },
  );
}
