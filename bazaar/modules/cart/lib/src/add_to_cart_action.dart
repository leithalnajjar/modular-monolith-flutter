import 'package:cart_api/cart_api.dart';
import 'package:catalog_api/catalog_api.dart';
import 'package:core/core.dart';

/// The cart's contribution to the catalog's product page.
final class AddToCartAction implements ProductAction {
  AddToCartAction(this._cart);

  final CartCommands _cart;

  @override
  String get label => 'Add to cart';

  @override
  Future<Result<String>> run(ProductId productId) async {
    final result = await _cart.add(productId);
    return result.map((cart) {
      final line = cart.lines.firstWhere((l) => l.productId == productId);
      return 'Added ${line.name} to your cart';
    });
  }
}
