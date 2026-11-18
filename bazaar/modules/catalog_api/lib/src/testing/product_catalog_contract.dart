// modules/catalog_api/lib/src/testing/product_catalog_contract.dart
import 'dart:async';

import 'package:core/core.dart';

import '../product.dart';
import '../product_catalog.dart';

/// The promises every [ProductCatalog] makes, as executable checks.
///
/// [create] must return a catalog that holds exactly the products it is
/// given. The result lists every broken promise; an empty list means the
/// catalog keeps them all.
///
/// Plain Dart, no test framework: the real catalog's tests (`flutter test`)
/// and the fake's tests (`dart test`) both run the same checks.
Future<List<String>> checkProductCatalogContract(
    FutureOr<ProductCatalog> Function(List<Product> products) create) async {
  const lamp = Product(
      id: ProductId('contract-lamp'),
      name: 'Brass Desk Lamp',
      price: Money(4900, 'USD'),
      inStock: true);
  const mug = Product(
      id: ProductId('contract-mug'),
      name: 'Stoneware Mug',
      price: Money(1250, 'USD'),
      inStock: false);
  const shade = Product(
      id: ProductId('contract-shade'),
      name: 'Linen Lamp Shade',
      price: Money(1800, 'USD'),
      inStock: true);
  final catalog = await create([lamp, mug, shade]);

  final broken = <String>[];
  Future<void> promise(String description, Future<bool> Function() kept) async {
    try {
      if (!await kept()) broken.add(description);
    } on Object catch (error) {
      broken.add('$description (threw ${error.runtimeType})');
    }
  }

  await promise('getProduct returns a known product',
      () async => (await catalog.getProduct(lamp.id)).valueOrNull == lamp);

  await promise('getProduct returns products that are out of stock',
      () async => (await catalog.getProduct(mug.id)).valueOrNull == mug);

  await promise('getProduct fails with NotFound for an unknown id', () async {
    final result = await catalog.getProduct(const ProductId('contract-none'));
    return result is Err<Product> && result.failure is NotFound;
  });

  await promise('search matches names ignoring case, and nothing else',
      () async {
    final ids = _ids(await catalog.search('LAMP'));
    return ids.toSet().containsAll([lamp.id, shade.id]) && !ids.contains(mug.id);
  });

  await promise('search with no matches succeeds with an empty list',
      () async {
    final result = await catalog.search('teapot');
    return result is Ok<List<Product>> && result.value.isEmpty;
  });

  await promise('search returns at most limit products',
      () async => _ids(await catalog.search('lamp', limit: 1)).length == 1);

  await promise('search pages do not overlap', () async {
    final first = _ids(await catalog.search('lamp', limit: 1));
    final second = _ids(await catalog.search('lamp', limit: 1, offset: 1));
    return first.length == 1 &&
        second.length == 1 &&
        first.single != second.single;
  });

  await promise('search fails with RuleViolation when limit is not positive',
      () async {
    final result = await catalog.search('lamp', limit: 0);
    return result is Err<List<Product>> && result.failure is RuleViolation;
  });

  await promise('search fails with RuleViolation when offset is negative',
      () async {
    final result = await catalog.search('lamp', offset: -1);
    return result is Err<List<Product>> && result.failure is RuleViolation;
  });

  return broken;
}

List<ProductId> _ids(Result<List<Product>> result) => switch (result) {
      Ok(:final value) => [for (final p in value) p.id],
      Err() => const [],
    };
