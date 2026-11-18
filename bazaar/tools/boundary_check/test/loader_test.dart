import 'dart:io';

import 'package:boundary_check/boundary_check.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;

  void write(String path, String content) =>
      (File('${root.path}/$path')..createSync(recursive: true))
          .writeAsStringSync(content);

  setUp(() {
    root = Directory.systemTemp.createTempSync('boundary_check_');
    write('pubspec.yaml', '''
name: demo
workspace:
  - modules/cart
  - modules/catalog_api
''');
    write('modules/catalog_api/pubspec.yaml', 'name: catalog_api\n');
    write('modules/cart/pubspec.yaml', '''
name: cart
dependencies:
  catalog_api:
dev_dependencies:
  test: ^1.25.0
''');
    write('modules/cart/lib/cart.dart', '''
// A comment mentioning import 'package:nope/nope.dart'; is not an import.
import 'dart:async';
import 'package:catalog_api/catalog_api.dart' show ProductId, Product;
import 'src/web.dart' if (dart.library.io) 'src/io.dart';

export 'src/cart_service.dart';
''');
  });

  tearDown(() => root.deleteSync(recursive: true));

  test('reads members, dependencies and every kind of directive', () {
    final [cart, catalogApi] = loadWorkspace(root);

    expect(catalogApi.layer, Layer.contract);
    expect(cart.layer, Layer.module);
    expect(cart.dependencies, {'catalog_api'});
    expect(cart.devDependencies, {'test'});
    expect(cart.imports.map((i) => i.uri), [
      'dart:async',
      'package:catalog_api/catalog_api.dart',
      'src/web.dart',
      'src/io.dart', // the conditional import counts too
      'src/cart_service.dart', // and so do exports
    ]);
    final catalogImport = cart.imports[1];
    expect(catalogImport.line, 3);
    expect(catalogImport.shown, ['ProductId', 'Product']);
    expect(catalogImport.file, 'modules/cart/lib/cart.dart');
  });

  test('finds the workspace root from inside a member', () {
    final found = findWorkspaceRoot(Directory('${root.path}/modules/cart/lib'));
    expect(found?.path, root.absolute.path);
  });
}
