import 'package:core/core.dart';

import 'product.dart';

/// Something another module offers on the product page, such as
/// "Add to cart" or "Add to wish list".
///
/// The catalog shows a button for every action it is given, without
/// knowing which modules provided them. That keeps the dependency pointing
/// the right way: the cart depends on the catalog's contract, never the
/// other way round.
abstract interface class ProductAction {
  /// The button text.
  String get label;

  /// Runs the action for [productId]. Returns a short confirmation for the
  /// user, or a [Failure] explaining why nothing happened.
  Future<Result<String>> run(ProductId productId);
}

/// The extension point. The catalog registers one instance; other modules
/// add their actions to it in their `start` method.
abstract interface class ProductActions {
  void add(ProductAction action);

  List<ProductAction> get all;
}
