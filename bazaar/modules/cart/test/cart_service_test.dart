import 'package:cart/src/cart_service.dart';
import 'package:cart/src/catalog_pricing.dart';
import 'package:cart_api/cart_api.dart';
import 'package:catalog_api/catalog_api.dart';
import 'package:catalog_api/testing.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

const _lamp = Product(
    id: ProductId('lamp'),
    name: 'Lamp',
    price: Money(4900, 'USD'),
    inStock: true);
const _mug = Product(
    id: ProductId('mug'),
    name: 'Mug',
    price: Money(1250, 'USD'),
    inStock: false);

CartService _service() => CartService(
      CatalogPricing(FakeProductCatalog([_lamp, _mug])),
      currency: 'USD',
    );

void main() {
  test('adding a product prices it from the catalog', () async {
    final cart = _service();
    final result = await cart.add(const ProductId('lamp'), quantity: 2);

    final value = result.valueOrNull!;
    expect(value.lines.single.unitPrice, const Money(4900, 'USD'));
    expect(value.total, const Money(9800, 'USD'));
    expect(value.itemCount, 2);
  });

  test('adding the same product again increases its quantity', () async {
    final cart = _service();
    await cart.add(const ProductId('lamp'));
    await cart.add(const ProductId('lamp'));
    expect(cart.current.lines.single.quantity, 2);
  });

  test('an out-of-stock product is a rule violation, not a crash', () async {
    final result = await _service().add(const ProductId('mug'));
    final failure = (result as Err<Cart>).failure;
    expect(failure, isA<RuleViolation>());
    expect(failure.message, 'Mug is out of stock');
  });

  test("the catalog's NotFound passes through unchanged", () async {
    final result = await _service().add(const ProductId('ghost'));
    expect((result as Err<Cart>).failure, isA<NotFound>());
  });

  test('quantity 0 removes the line; negative is rejected', () async {
    final cart = _service();
    await cart.add(const ProductId('lamp'));

    final negative = await cart.changeQuantity(const ProductId('lamp'), -1);
    expect((negative as Err<Cart>).failure, isA<RuleViolation>());

    await cart.changeQuantity(const ProductId('lamp'), 0);
    expect(cart.current.isEmpty, isTrue);
  });

  test('every change is announced on the changes stream', () async {
    final cart = _service();
    final counts = <int>[];
    cart.changes.listen((c) => counts.add(c.itemCount));

    await cart.add(const ProductId('lamp'));
    await cart.changeQuantity(const ProductId('lamp'), 3);
    cart.clear();
    await Future<void>.delayed(Duration.zero);

    expect(counts, [1, 3, 0]);
    await cart.dispose();
  });

  test('an unavailable catalog leaves the cart unchanged', () async {
    final catalog = FakeProductCatalog([_lamp])
      ..failWith = const Unavailable('offline');
    final cart = CartService(CatalogPricing(catalog), currency: 'USD');

    final result = await cart.add(const ProductId('lamp'));

    expect((result as Err<Cart>).failure, isA<Unavailable>());
    expect(cart.current.isEmpty, isTrue);
  });
}
