import 'dart:convert';

import 'package:cart/src/data/cart_storage.dart';
import 'package:cart_api/cart_api.dart';
import 'package:catalog_api/catalog_api.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage/storage.dart';

const _lamps = Cart(currency: 'USD', lines: [
  CartLine(
    productId: ProductId('p-1'),
    name: 'Brass Desk Lamp',
    unitPrice: Money(4900, 'USD'),
    quantity: 2,
  ),
]);

void main() {
  late InMemoryKeyValueStore store;
  late CartStorage storage;

  setUp(() {
    store = InMemoryKeyValueStore();
    storage = CartStorage(store.scope('cart'));
  });

  test('a saved cart comes back the same', () async {
    await storage.save(_lamps);
    final loaded = await storage.load(currency: 'USD');
    expect(loaded?.lines, _lamps.lines);
    expect(await store.keys(), {'cart/cart'});
  });

  test('a cart saved in another currency is not restored', () async {
    await storage.save(_lamps);
    expect(await storage.load(currency: 'EUR'), isNull);
  });

  test('one damaged line means the document is not trusted', () async {
    await store.write(
        'cart/cart',
        jsonEncode({
          'v': 2,
          'data': {
            'currency': 'USD',
            'lines': [
              {
                'productId': 'p-1',
                'name': 'Lamp',
                'unitPrice': 4900,
                'quantity': 0
              },
            ],
          },
        }));
    expect(await storage.load(currency: 'USD'), isNull);
  });

  test('a version 1 cart is upgraded on first read', () async {
    await store.write(
        'cart/cart',
        jsonEncode({
          'v': 1,
          'data': {
            'currency': 'USD',
            'items': [
              {'id': 'p-9', 'name': 'Linen Notebook', 'price': 19.99, 'qty': 1},
            ],
          },
        }));

    final loaded = await storage.load(currency: 'USD');

    expect(loaded?.lines.single.unitPrice, const Money(1999, 'USD'));
    // Truncating would have lost a cent.
    expect((19.99 * 100).toInt(), 1998);
    final saved = jsonDecode((await store.read('cart/cart'))!);
    expect(saved, containsPair('v', 2));
  });
}
