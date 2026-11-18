import 'dart:convert';

import 'package:catalog/src/data/http_product_source.dart';
import 'package:catalog_api/catalog_api.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final _base = Uri.parse('https://api.example.com/v1/');

const _lampJson = {
  'id': 'p-1',
  'name': 'Brass Desk Lamp',
  'price_minor': 4900,
  'currency': 'USD',
  'in_stock': true,
};

HttpProductSource _source(MockClientHandler handler,
        {Duration timeout = const Duration(seconds: 10)}) =>
    HttpProductSource(MockClient(handler), _base, timeout: timeout);

void main() {
  test('maps a 200 response to a Product', () async {
    final source = _source((request) async {
      expect(request.url.toString(), 'https://api.example.com/v1/products/p-1');
      return http.Response(jsonEncode(_lampJson), 200);
    });

    final result = await source.fetch(const ProductId('p-1'));

    expect(result.valueOrNull?.price, const Money(4900, 'USD'));
  });

  test('search sends query, limit and offset', () async {
    late Uri seen;
    final source = _source((request) async {
      seen = request.url;
      return http.Response(jsonEncode({'items': [_lampJson]}), 200);
    });

    final result = await source.search('lamp', limit: 10, offset: 20);

    expect(seen.path, '/v1/products');
    expect(seen.queryParameters, {'q': 'lamp', 'limit': '10', 'offset': '20'});
    expect(result.valueOrNull?.single.name, 'Brass Desk Lamp');
  });

  test('404 is NotFound, 500 is Unavailable', () async {
    final missing = _source((_) async => http.Response('', 404));
    final broken = _source((_) async => http.Response('', 500));

    expect((await missing.fetch(const ProductId('x')) as Err).failure,
        isA<NotFound>());
    expect((await broken.fetch(const ProductId('x')) as Err).failure,
        isA<Unavailable>());
  });

  test('data we cannot read is Unavailable, not a crash', () async {
    final source = _source((_) async =>
        http.Response(jsonEncode({'id': 'p-1', 'name': 'No price'}), 200));

    final failure = (await source.fetch(const ProductId('p-1')) as Err).failure;

    expect(failure, isA<Unavailable>());
    expect(failure.message, 'The catalog sent data we could not read');
  });

  test('a slow server times out as Unavailable', () async {
    final source = _source(
      (_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return http.Response(jsonEncode(_lampJson), 200);
      },
      timeout: const Duration(milliseconds: 20),
    );

    final failure = (await source.fetch(const ProductId('p-1')) as Err).failure;

    expect(failure.message, 'The catalog took too long');
  });
}
