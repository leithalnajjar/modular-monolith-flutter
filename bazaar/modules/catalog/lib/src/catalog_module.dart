import 'package:catalog_api/catalog_api.dart';
import 'package:core/core.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:module_contract/module_contract.dart';

import 'caching_product_catalog.dart';
import 'data/catalog_store.dart';
import 'data/http_product_source.dart';
import 'data/product_source.dart';
import 'data/seeded_product_source.dart';
import 'product_action_list.dart';
import 'ui/product_details_screen.dart';
import 'ui/product_list_screen.dart';

/// Where the catalog server lives. The app decides; the catalog obeys.
final class CatalogRemote {
  const CatalogRemote(this.baseUrl, this.client);

  /// For example `https://api.example.com/v1/` (note the trailing slash).
  final Uri baseUrl;
  final http.Client client;
}

/// Plugs the catalog into the app.
final class CatalogModule extends FeatureModule {
  /// Use [remote] to load products from a server, or [seed] to start with
  /// a fixed list (demos and tests). With neither, the catalog is empty.
  const CatalogModule({this.seed = const [], this.remote});

  final List<Product> seed;
  final CatalogRemote? remote;

  @override
  String get name => 'catalog';

  @override
  void register(GetIt di) {
    di
      ..registerLazySingleton<ProductSource>(() => switch (remote) {
            final r? => HttpProductSource(r.client, r.baseUrl),
            null => SeededProductSource(CatalogStore(seed)),
          })
      // Other modules resolve the contract type, never the implementation.
      ..registerLazySingleton<ProductCatalog>(
          () => CachingProductCatalog(di<ProductSource>(), di<Clock>()))
      // The extension point other modules add product-page buttons to.
      ..registerSingleton<ProductActions>(ProductActionList());
  }

  @override
  List<NavDestination> destinations(GetIt di) => const [
        NavDestination(
          label: 'Shop',
          icon: Icons.storefront_outlined,
          location: CatalogRoutes.products,
          order: 10,
        ),
      ];

  /// Links shared before the redesign looked like `/shop/item/p-1`.
  /// They still work: the catalog moves them to the new location.
  @override
  String? redirect(GetIt di, GoRouterState state) {
    final segments = state.uri.pathSegments;
    if (segments.length == 3 && segments[0] == 'shop' && segments[1] == 'item') {
      return CatalogRoutes.productDetails(ProductId(segments[2]));
    }
    return null;
  }

  @override
  List<RouteBase> routes(GetIt di) => [
        GoRoute(
          path: CatalogRoutes.products,
          builder: (context, state) =>
              ProductListScreen(catalog: di<ProductCatalog>()),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) => ProductDetailsScreen(
                catalog: di<ProductCatalog>(),
                actions: di<ProductActions>().all,
                id: ProductId(state.pathParameters['id']!),
              ),
            ),
          ],
        ),
      ];
}
