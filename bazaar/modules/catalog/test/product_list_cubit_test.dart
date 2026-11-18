import 'package:catalog/src/ui/product_list_cubit.dart';
import 'package:catalog_api/catalog_api.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

Product _product(int i) => Product(
    id: ProductId('p-$i'),
    name: 'Product $i',
    price: const Money(100, 'USD'),
    inStock: true);

/// Five products, served in pages; can be told to fail once.
final class _PagedCatalog implements ProductCatalog {
  final all = [for (var i = 0; i < 5; i++) _product(i)];
  bool failNext = false;

  @override
  Future<Result<Product>> getProduct(ProductId id) async =>
      const Result.err(NotFound('unused'));

  @override
  Future<Result<List<Product>>> search(String query,
      {int limit = 20, int offset = 0}) async {
    if (failNext) {
      failNext = false;
      return const Result.err(Unavailable('No connection'));
    }
    return Result.ok(all.skip(offset).take(limit).toList());
  }
}

void main() {
  test('loads the first page', () async {
    final cubit = ProductListCubit(_PagedCatalog(), pageSize: 2);
    await cubit.load();

    final state = cubit.state as ProductListLoaded;
    expect(state.products.map((p) => p.name), ['Product 0', 'Product 1']);
    expect(state.hasMore, isTrue);
    await cubit.close();
  });

  test('a failure shows a message, and Retry recovers', () async {
    final catalog = _PagedCatalog()..failNext = true;
    final cubit = ProductListCubit(catalog, pageSize: 2);

    await cubit.load();
    expect((cubit.state as ProductListFailed).message, 'No connection');

    await cubit.load();
    expect(cubit.state, isA<ProductListLoaded>());
    await cubit.close();
  });

  test('loadMore appends pages until there are no more', () async {
    final cubit = ProductListCubit(_PagedCatalog(), pageSize: 2);
    await cubit.load();
    await cubit.loadMore();
    await cubit.loadMore();

    final state = cubit.state as ProductListLoaded;
    expect(state.products, hasLength(5));
    expect(state.hasMore, isFalse);
    await cubit.close();
  });
}
