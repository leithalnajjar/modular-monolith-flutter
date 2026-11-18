import 'dart:convert';

import 'package:catalog/catalog.dart';
import 'package:catalog_api/catalog_api.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:module_contract/module_contract.dart';

void main() {
  test('with a remote, the catalog loads products from the server', () async {
    final server = MockClient((request) async {
      if (request.url.path == '/v1/products/p-9') {
        return http.Response(
            jsonEncode({
              'id': 'p-9',
              'name': 'Walnut Tray',
              'price_minor': 3200,
              'currency': 'USD',
              'in_stock': true,
            }),
            200);
      }
      return http.Response('', 404);
    });

    final host = await ModuleHost.start(modules: [
      CatalogModule(
        remote: CatalogRemote(Uri.parse('https://api.example.com/v1/'), server),
      ),
    ]);
    addTearDown(host.stop);

    final catalog = host.di<ProductCatalog>();
    final found = await catalog.getProduct(const ProductId('p-9'));
    final missing = await catalog.getProduct(const ProductId('p-0'));

    expect(found.valueOrNull?.name, 'Walnut Tray');
    expect((missing as Err<Product>).failure, isA<NotFound>());
  });
}
