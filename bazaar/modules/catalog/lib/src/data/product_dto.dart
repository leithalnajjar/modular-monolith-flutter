import 'package:catalog_api/catalog_api.dart';
import 'package:core/core.dart';

/// The server's JSON for a product, translated into the catalog's model.
///
/// This is the only place that knows the wire format. If the backend
/// renames `price_minor`, this file changes and nothing else does.
///
/// Throws [FormatException] for anything that does not match, so the
/// caller can turn bad data into a single, clear failure.
Product productFromJson(Object? json) {
  if (json is! Map<String, Object?>) {
    throw const FormatException('A product must be a JSON object');
  }
  T field<T>(String key) {
    final value = json[key];
    if (value is! T) {
      throw FormatException('Product field "$key" is missing or not $T');
    }
    return value;
  }

  final currency = field<String>('currency');
  if (currency.length != 3) {
    throw FormatException('Invalid currency "$currency"');
  }
  return Product(
    id: ProductId(field<String>('id')),
    name: field<String>('name'),
    price: Money(field<int>('price_minor'), currency),
    inStock: field<bool>('in_stock'),
    imageUrl: json['image_url'] as String?,
  );
}
