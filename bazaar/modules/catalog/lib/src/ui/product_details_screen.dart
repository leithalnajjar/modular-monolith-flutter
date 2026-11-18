import 'package:catalog_api/catalog_api.dart';
import 'package:core/core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_kit/ui_kit.dart';

/// Shows one product. Built from an ID taken from the URL, so it works the
/// same whether the user tapped a list item, followed a deep link or came
/// from another module.
class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({
    super.key,
    required this.catalog,
    required this.id,
    this.actions = const [],
  });

  final ProductCatalog catalog;
  final ProductId id;

  /// Buttons contributed by other modules. The catalog does not know who
  /// they are.
  final List<ProductAction> actions;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late final Future<Result<Product>> _product =
      widget.catalog.getProduct(widget.id);

  Future<void> _run(ProductAction action) async {
    final result = await action.run(widget.id);
    if (!mounted) return;
    final message = switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => failure.message,
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder(
        future: _product,
        builder: (context, snapshot) => switch (snapshot.data) {
          null => const Center(child: CircularProgressIndicator()),
          Ok(value: final product) => Padding(
              padding: const EdgeInsets.all(Spacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: Spacing.s),
                  PriceText(product.price,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: Spacing.m),
                  Text(product.inStock ? 'In stock' : 'Out of stock'),
                  const SizedBox(height: Spacing.l),
                  for (final action in widget.actions)
                    FilledButton(
                      onPressed: () => _run(action),
                      child: Text(action.label),
                    ),
                ],
              ),
            ),
          Err(failure: NotFound()) => const EmptyState(
              message: 'This product is no longer available',
              icon: Icons.search_off,
            ),
          Err(:final failure) => ErrorState(message: failure.message),
        },
      ),
    );
  }
}
