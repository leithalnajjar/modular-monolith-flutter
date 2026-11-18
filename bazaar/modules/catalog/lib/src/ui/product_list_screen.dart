import 'package:catalog_api/catalog_api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_kit/ui_kit.dart';

import 'product_list_cubit.dart';

/// Lists products. Private to the catalog module: other modules reach it
/// only by navigating to [CatalogRoutes.products].
class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key, required this.catalog});

  final ProductCatalog catalog;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductListCubit(catalog)..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Products')),
        body: BlocBuilder<ProductListCubit, ProductListState>(
          builder: (context, state) => switch (state) {
            ProductListLoading() =>
              const Center(child: CircularProgressIndicator()),
            ProductListFailed(:final message) => ErrorState(
                message: message,
                onRetry: () => context.read<ProductListCubit>().load(),
              ),
            ProductListLoaded(products: []) => const EmptyState(
                message: 'No products yet',
                icon: Icons.storefront_outlined,
              ),
            ProductListLoaded(:final products, :final hasMore) => ListView(
                children: [
                  for (final product in products)
                    ListTile(
                      title: Text(product.name),
                      subtitle: PriceText(product.price),
                      trailing:
                          product.inStock ? null : const Text('Out of stock'),
                      onTap: () => context
                          .push(CatalogRoutes.productDetails(product.id)),
                    ),
                  if (hasMore)
                    TextButton(
                      onPressed: () =>
                          context.read<ProductListCubit>().loadMore(),
                      child: const Text('Load more'),
                    ),
                ],
              ),
          },
        ),
      ),
    );
  }
}
