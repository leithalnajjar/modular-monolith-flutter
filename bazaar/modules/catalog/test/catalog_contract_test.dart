import 'dart:convert';

import 'package:catalog/catalog.dart';
import 'package:catalog/src/caching_product_catalog.dart';
import 'package:catalog/src/data/http_product_source.dart';
import 'package:catalog_api/catalog_api.dart';
import 'package:catalog_api/testing.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A pretend catalog server holding [products]. It answers the two
/// endpoints HttpProductSource uses, the way the real server does.
MockClient _server(List<Product> products) {
  Map<String, Object?> json(Product p) => {
        'id': p.id.value,
        'name': p.name,
        'price_minor': p.price.minorUnits,
        'currency': p.price.currency,
        'in_stock': p.inStock,
      };

  return MockClient((request) async {
    final path = request.url.pathSegments; // [v1, products] or [v1, products, id]
    if (path.length == 3) {
      final match = products.where((p) => p.id.value == path[2]);
      return match.isEmpty
          ? http.Response('', 404)
          : http.Response(jsonEncode(json(match.single)), 200);
    }
    final query = request.url.queryParameters;
    final needle = query['q']!.toLowerCase();
    final items = products
        .where((p) => p.name.toLowerCase().contains(needle))
        .skip(int.parse(query['offset']!))
        .take(int.parse(query['limit']!))
        .map(json)
        .toList();
    return http.Response(jsonEncode({'items': items}), 200);
  });
}

void main() {
  test('the in-memory catalog keeps the ProductCatalog contract', () async {
    final broken = await checkProductCatalogContract(
        (products) => createProductCatalog(seed: products));
    expect(broken, isEmpty);
  });

  test('the HTTP-backed catalog keeps the ProductCatalog contract', () async {
    final broken = await checkProductCatalogContract(
      (products) => CachingProductCatalog(
        HttpProductSource(
            _server(products), Uri.parse('https://api.example.com/v1/')),
        const SystemClock(),
      ),
    );
    expect(broken, isEmpty);
  });
}
