import 'package:catalog/catalog.dart';
import 'package:catalog_api/catalog_api.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

const _lamp = Product(
  id: ProductId('p-1'),
  name: 'Brass Desk Lamp',
  price: Money(4900, 'USD'),
  inStock: true,
);
const _mug = Product(
  id: ProductId('p-2'),
  name: 'Stoneware Mug',
  price: Money(1250, 'USD'),
  inStock: false,
);

void main() {
  // Tests use only the public surface: createProductCatalog and the
  // ProductCatalog contract. If the internals are rewritten, these tests
  // stay the same.
  final catalog = createProductCatalog(seed: [_lamp, _mug]);

  test('finds a product by id', () async {
    final result = await catalog.getProduct(const ProductId('p-1'));
    expect(result.valueOrNull, _lamp);
  });

  test('reports NotFound for an unknown id', () async {
    final result = await catalog.getProduct(const ProductId('nope'));
    expect(result, isA<Err<Product>>());
    expect((result as Err<Product>).failure, isA<NotFound>());
  });

  test('searches by name, case-insensitively', () async {
    final result = await catalog.search('MUG');
    expect(result.valueOrNull, [_mug]);
  });

  test('rejects a non-positive limit', () async {
    final result = await catalog.search('a', limit: 0);
    expect((result as Err<List<Product>>).failure, isA<RuleViolation>());
  });

  test('callers can switch on failure kinds (Chapter 5 example)', () async {
    String describe(Result<Product> result) {
      switch (result) {
        case Ok(:final value):
          return 'show ${value.name}';
        case Err(failure: NotFound()):
          return 'removed';
        case Err(failure: Unavailable()):
          return 'retry';
        case Err(:final failure):
          return 'error: ${failure.message}';
      }
    }

    expect(describe(await catalog.getProduct(const ProductId('p-1'))),
        'show Brass Desk Lamp');
    expect(describe(await catalog.getProduct(const ProductId('x'))),
        'removed');
    expect(describe(const Result.err(Unavailable('offline'))), 'retry');
  });

  test('product routes are built from ids, not hard-coded strings', () {
    expect(CatalogRoutes.productDetails(const ProductId('p-1')),
        '/products/p-1');
  });
}
