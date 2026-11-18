import 'dart:async';
import 'dart:convert';

import 'package:catalog_api/catalog_api.dart';
import 'package:core/core.dart';
import 'package:http/http.dart' as http;

import 'product_dto.dart';
import 'product_source.dart';

/// Loads products from the catalog server.
///
/// Expected API, relative to [baseUrl] (which must end with `/`):
///   GET products?q=&limit=&offset=  ->  {"items": [product, ...]}
///   GET products/{id}               ->  product, or 404
///
/// Every HTTP detail stops here. Callers only ever see [Result]s with the
/// four failure kinds from `core`.
final class HttpProductSource implements ProductSource {
  HttpProductSource(
    this._client,
    this._baseUrl, {
    this.timeout = const Duration(seconds: 10),
  }) : assert(_baseUrl.path.endsWith('/'), 'baseUrl must end with /');

  final http.Client _client;
  final Uri _baseUrl;
  final Duration timeout;

  @override
  Future<Result<Product>> fetch(ProductId id) => _get(
        _baseUrl.resolve('products/${Uri.encodeComponent(id.value)}'),
        productFromJson,
      );

  @override
  Future<Result<List<Product>>> search(String query,
          {required int limit, required int offset}) =>
      _get(
        _baseUrl.resolve('products').replace(queryParameters: {
          'q': query,
          'limit': '$limit',
          'offset': '$offset',
        }),
        (json) => switch (json) {
          {'items': final List<Object?> items} =>
            items.map(productFromJson).toList(growable: false),
          _ => throw const FormatException('Expected {"items": [...]}'),
        },
      );

  Future<Result<T>> _get<T>(Uri url, T Function(Object? json) parse) async {
    try {
      final response = await _client.get(url).timeout(timeout);
      return switch (response.statusCode) {
        200 => Result.ok(parse(jsonDecode(response.body))),
        404 => Result.err(NotFound('Not found: ${url.path}')),
        401 || 403 => const Result.err(
            Unauthorized('The catalog refused this request')),
        final code => Result.err(
            Unavailable('Catalog server answered $code')),
      };
    } on TimeoutException catch (e) {
      return Result.err(Unavailable('The catalog took too long', cause: e));
    } on http.ClientException catch (e) {
      return Result.err(Unavailable('Could not reach the catalog', cause: e));
    } on FormatException catch (e) {
      return Result.err(
          Unavailable('The catalog sent data we could not read', cause: e));
    }
  }
}
