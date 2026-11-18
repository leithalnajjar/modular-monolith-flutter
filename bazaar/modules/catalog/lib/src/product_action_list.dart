import 'package:catalog_api/catalog_api.dart';

/// The catalog's implementation of the [ProductActions] extension point.
final class ProductActionList implements ProductActions {
  final _actions = <ProductAction>[];

  @override
  void add(ProductAction action) => _actions.add(action);

  @override
  List<ProductAction> get all => List.unmodifiable(_actions);
}
