import 'dart:convert';

import 'package:storage/storage.dart';
import 'package:test/test.dart';

void main() {
  group('ScopedStore', () {
    test('keeps each module in its own part of the store', () async {
      final store = InMemoryKeyValueStore();
      final cart = store.scope('cart');
      final inbox = store.scope('notifications');

      await cart.write('state', 'two lamps');
      await inbox.write('state', 'three messages');

      expect(await cart.read('state'), 'two lamps');
      expect(await store.keys(), {'cart/state', 'notifications/state'});
    });

    test('clear removes one scope and nothing else', () async {
      final store = InMemoryKeyValueStore();
      await store.scope('cart').write('state', 'x');
      await store.scope('cart').write('draft', 'y');
      await store.scope('checkout').write('state', 'z');

      await store.scope('cart').clear();

      expect(await store.keys(), {'checkout/state'});
    });
  });

  group('VersionedDocument', () {
    // Version 1 stored prices as decimals; version 2 as minor units.
    Map<String, Object?> v1ToV2(Map<String, Object?> data) => {
          'price': ((data['price']! as num) * 100).round(),
        };

    test('writes the version next to the data', () async {
      final store = InMemoryKeyValueStore();
      await VersionedDocument(store, 'doc', version: 2).write({'price': 1999});
      expect(jsonDecode((await store.read('doc'))!), {
        'v': 2,
        'data': {'price': 1999}
      });
    });

    test('upgrades old documents once, and saves the result', () async {
      final store = InMemoryKeyValueStore({
        'doc': jsonEncode({
          'v': 1,
          'data': {'price': 19.99}
        }),
      });
      final doc =
          VersionedDocument(store, 'doc', version: 2, migrations: {1: v1ToV2});

      // 19.99 * 100 is 1998.9999999999998 in floating point: round, never
      // truncate.
      expect(await doc.read(), {'price': 1999});
      expect(jsonDecode((await store.read('doc'))!), containsPair('v', 2));
    });

    test('unreadable, unknown or newer documents read as nothing', () async {
      final store = InMemoryKeyValueStore({
        'broken': '{not json',
        'shape': jsonEncode([1, 2, 3]),
        'newer': jsonEncode({'v': 3, 'data': <String, Object?>{}}),
        'gap': jsonEncode({'v': 0, 'data': <String, Object?>{}}),
      });
      for (final key in ['broken', 'shape', 'newer', 'gap', 'missing']) {
        final doc =
            VersionedDocument(store, key, version: 2, migrations: {1: v1ToV2});
        expect(await doc.read(), isNull, reason: key);
      }
    });
  });
}
