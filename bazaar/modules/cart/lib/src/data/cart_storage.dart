// modules/cart/lib/src/data/cart_storage.dart
import 'package:cart_api/cart_api.dart';
import 'package:catalog_api/catalog_api.dart';
import 'package:core/core.dart';
import 'package:storage/storage.dart';

/// The cart's saved state, in the cart's own scope of the app's storage.
///
/// The format is private to the cart. No other module reads it: checkout
/// asks [CartReader], never this document.
final class CartStorage {
  CartStorage(ScopedStore store)
      : _document = VersionedDocument(store, 'cart',
            version: 2, migrations: {1: _fromVersion1});

  final VersionedDocument _document;

  /// The saved cart, or null when there is none or it cannot be used: it
  /// is unreadable, or it was saved in a different currency than the app
  /// now uses (its prices would be wrong).
  Future<Cart?> load({required String currency}) async {
    final data = await _document.read();
    if (data
        case {'currency': final String saved, 'lines': final List<Object?> raw}
        when saved == currency) {
      final lines = <CartLine>[];
      for (final line in raw) {
        if (line
            case {
              'productId': final String id,
              'name': final String name,
              'unitPrice': final int minorUnits,
              'quantity': final int quantity,
            } when quantity > 0) {
          lines.add(CartLine(
            productId: ProductId(id),
            name: name,
            unitPrice: Money(minorUnits, currency),
            quantity: quantity,
          ));
        } else {
          return null; // one bad line: distrust the whole document
        }
      }
      return Cart(lines: lines, currency: currency);
    }
    return null;
  }

  Future<void> save(Cart cart) => _document.write({
        'currency': cart.currency,
        'lines': [
          for (final line in cart.lines)
            {
              'productId': line.productId.value,
              'name': line.name,
              'unitPrice': line.unitPrice.minorUnits,
              'quantity': line.quantity,
            },
        ],
      });

  Future<void> clear() => _document.delete();

  /// An example of a schema change. Version 1 (an imagined first release)
  /// stored prices as decimal numbers and used shorter field names.
  /// Version 2 stores integer minor units, like [Money].
  static Map<String, Object?> _fromVersion1(Map<String, Object?> v1) => {
        'currency': v1['currency'],
        'lines': [
          for (final item in (v1['items'] as List<Object?>?) ?? const [])
            if (item
                case {
                  'id': final String id,
                  'name': final String name,
                  'price': final num price,
                  'qty': final int qty
                })
              {
                'productId': id,
                'name': name,
                // 19.99 * 100 is 1998.9999999999998: round, never truncate.
                'unitPrice': (price * 100).round(),
                'quantity': qty,
              },
        ],
      };
}
