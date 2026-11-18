import 'dart:convert';
import 'dart:io';

import 'package:bazaar_app/config.dart';
import 'package:bazaar_app/modules.dart';
import 'package:catalog/catalog.dart';
import 'package:feature_flags/feature_flags.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reads a config file the way `--dart-define-from-file` does.
BazaarConfig _load(File file) {
  final values = (jsonDecode(file.readAsStringSync()) as Map<String, Object?>)
      .map((key, value) => MapEntry(key, '$value'));
  return BazaarConfig.parse(
    environment: values['BAZAAR_ENV'] ?? '',
    catalogUrl: values['BAZAAR_CATALOG_URL'] ?? '',
    flags: values['BAZAAR_FLAGS'] ?? '',
  );
}

void main() {
  test('no configuration means the demo', () {
    final config = BazaarConfig.parse();
    expect(config.environment, BazaarEnvironment.demo);
    expect(config.catalogUrl, isNull);
  });

  test('mistakes fail at startup, with a message', () {
    expect(
      () => BazaarConfig.parse(environment: 'prod'),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => BazaarConfig.parse(environment: 'staging'),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => BazaarConfig.parse(catalogUrl: 'http://api.example.com/v1'),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => BazaarConfig.parse(flags: 'app.inbox=maybe'),
      throwsA(isA<FormatException>()),
    );
  });

  test('every shipped config file is valid and sets only declared flags', () {
    final files = Directory('config')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList();
    expect(files, isNotEmpty);

    for (final file in files) {
      final config = _load(file);
      expect(
        config.flags.undeclared(declaredFlags()),
        isEmpty,
        reason: '${file.path} sets a flag no module declares',
      );
    }
  });

  test('staging loads products from the configured server', () {
    final staging = _load(File('config/staging.json'));
    final catalog = bazaarModules(staging).whereType<CatalogModule>().single;
    expect(catalog.remote?.baseUrl.host, 'staging.api.example.com');
  });

  test('switching the inbox off removes it, and nothing breaks', () async {
    final host = await startBazaar(
      config: const BazaarConfig(flags: FlagValues({'app.inbox': false})),
    );
    addTearDown(host.stop);

    expect(host.destinations.map((d) => d.label), isNot(contains('Inbox')));
    // The same check as the startup test: every service can still be built.
    expect(
      host.di.findAll<Object>(
        instantiateLazySingletons: true,
        callFactories: true,
      ),
      isNotEmpty,
    );
  });
}
