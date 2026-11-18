import 'package:catalog/src/caching_product_catalog.dart';
import 'package:catalog/src/data/product_source.dart';
import 'package:catalog_api/catalog_api.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

const _lamp = Product(
    id: ProductId('p-1'),
    name: 'Lamp',
    price: Money(4900, 'USD'),
    inStock: true);

/// A source we can switch between "working", "down" and "deleted".
final class _ScriptedSource implements ProductSource {
  Result<Product> next = const Result.ok(_lamp);
  int fetches = 0;

  @override
  Future<Result<Product>> fetch(ProductId id) async {
    fetches++;
    return next;
  }

  @override
  Future<Result<List<Product>>> search(String query,
          {required int limit, required int offset}) async =>
      const Result.ok([_lamp]);
}

void main() {
  late _ScriptedSource source;
  late FixedClock clock;
  late CachingProductCatalog catalog;

  setUp(() {
    source = _ScriptedSource();
    clock = FixedClock(DateTime.utc(2027, 1, 1));
    catalog = CachingProductCatalog(source, clock,
        maxAge: const Duration(minutes: 5));
  });

  test('a fresh product is served from the cache', () async {
    await catalog.getProduct(_lamp.id);
    await catalog.getProduct(_lamp.id);
    expect(source.fetches, 1);
  });

  test('an expired product is fetched again', () async {
    await catalog.getProduct(_lamp.id);
    clock.advance(const Duration(minutes: 6));
    await catalog.getProduct(_lamp.id);
    expect(source.fetches, 2);
  });

  test('when the server is down, the last known product is served', () async {
    await catalog.getProduct(_lamp.id);
    clock.advance(const Duration(hours: 1));
    source.next = const Result.err(Unavailable('offline'));

    final result = await catalog.getProduct(_lamp.id);

    expect(result.valueOrNull, _lamp);
  });

  test('a deleted product is forgotten, even when the server goes down',
      () async {
    await catalog.getProduct(_lamp.id);
    clock.advance(const Duration(hours: 1));
    source.next = const Result.err(NotFound('deleted'));
    await catalog.getProduct(_lamp.id);

    source.next = const Result.err(Unavailable('offline'));
    final result = await catalog.getProduct(_lamp.id);

    expect((result as Err<Product>).failure, isA<Unavailable>());
  });

  test('search results warm the cache', () async {
    await catalog.search('');
    await catalog.getProduct(_lamp.id);
    expect(source.fetches, 0);
  });

  test('negative offsets are rejected before reaching the source', () async {
    final result = await catalog.search('', offset: -1);
    expect((result as Err<List<Product>>).failure, isA<RuleViolation>());
  });
}
