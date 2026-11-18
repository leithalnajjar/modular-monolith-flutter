import 'package:catalog_api/catalog_api.dart';
import 'package:catalog_api/testing.dart';
import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  test('the fake keeps every promise of the ProductCatalog contract',
      () async {
    expect(await checkProductCatalogContract(FakeProductCatalog.new), isEmpty);
  });

  test('failWith makes every call fail, for testing callers', () async {
    final catalog = FakeProductCatalog()
      ..failWith = const Unavailable('offline');
    final result = await catalog.getProduct(const ProductId('p-1'));
    expect((result as Err<Product>).failure, isA<Unavailable>());
  });

  test('records which products were requested', () async {
    final catalog = FakeProductCatalog();
    await catalog.getProduct(const ProductId('p-1'));
    await catalog.getProduct(const ProductId('p-1'));
    expect(catalog.requested, [const ProductId('p-1'), const ProductId('p-1')]);
  });
}
