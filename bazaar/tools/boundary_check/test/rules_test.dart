import 'package:boundary_check/boundary_check.dart';
import 'package:test/test.dart';

/// A small workspace shaped like Bazaar, built in memory.
List<WorkspacePackage> workspace({
  Set<String> cartDeps = const {'core', 'cart_api', 'catalog_api'},
  Set<String> cartDevDeps = const {},
  List<ImportRef> cartImports = const [],
  Set<String> cartApiDeps = const {'core', 'catalog_api'},
  List<ImportRef> cartApiImports = const [],
  Set<String> coreDeps = const {},
}) =>
    [
      WorkspacePackage(
          name: 'core', dir: 'shared/core', dependencies: coreDeps),
      WorkspacePackage(
          name: 'catalog_api',
          dir: 'modules/catalog_api',
          dependencies: {'core'}),
      WorkspacePackage(
          name: 'catalog',
          dir: 'modules/catalog',
          dependencies: {'core', 'catalog_api'}),
      WorkspacePackage(
          name: 'cart_api',
          dir: 'modules/cart_api',
          dependencies: cartApiDeps,
          imports: cartApiImports),
      WorkspacePackage(
          name: 'cart',
          dir: 'modules/cart',
          dependencies: cartDeps,
          devDependencies: cartDevDeps,
          imports: cartImports),
      WorkspacePackage(
          name: 'app',
          dir: 'apps/app',
          dependencies: {'core', 'catalog', 'cart'}),
    ];

ImportRef import(String file, String uri, {List<String> shown = const []}) =>
    ImportRef(file: file, line: 1, uri: uri, shown: shown);

List<String> rulesBroken(List<WorkspacePackage> packages) =>
    checkBoundaries(packages).map((v) => v.rule).toList();

void main() {
  test('a workspace that follows the rules is clean', () {
    expect(
        checkBoundaries(workspace(
          cartImports: [
            import('modules/cart/lib/src/cart_service.dart',
                'package:catalog_api/catalog_api.dart'),
            import('modules/cart/lib/src/cart_service.dart', '../cart.dart'),
          ],
          cartApiImports: [
            import('modules/cart_api/lib/src/cart.dart',
                'package:catalog_api/catalog_api.dart',
                shown: ['ProductId']),
          ],
        )),
        isEmpty);
  });

  test('a module may not depend on another module\'s implementation', () {
    final [violation] =
        checkBoundaries(workspace(cartDeps: {'core', 'catalog'}));
    expect(violation.rule, 'layers');
    expect(violation.location, 'modules/cart/pubspec.yaml');
    expect(violation.message, contains('Depend on catalog_api instead.'));
  });

  test('the layer rule covers dev_dependencies too', () {
    expect(rulesBroken(workspace(cartDevDeps: {'catalog'})), ['layers']);
  });

  test('shared code may not depend on any module', () {
    final violations = checkBoundaries(workspace(coreDeps: {'cart_api'}));
    expect(violations.first.rule, 'layers');
    expect(violations.first.message,
        contains('Shared code sits below every module'));
    // cart_api already depends on core, so this also closes a cycle.
    expect(violations.skip(1).map((v) => v.rule), everyElement('cycles'));
  });

  test('a contract may not depend on an implementation', () {
    expect(
        rulesBroken(workspace(cartApiDeps: {'core', 'catalog'})), ['layers']);
  });

  test('every imported workspace package must be declared', () {
    expect(
        rulesBroken(workspace(cartImports: [
          import('modules/cart/lib/cart.dart', 'package:catalog/catalog.dart'),
        ])),
        ['declared']);
  });

  test('tests may use dev_dependencies, library code may not', () {
    final packages = workspace(
      cartDeps: {'core', 'cart_api'},
      cartDevDeps: {'catalog_api'},
      cartImports: [
        import('modules/cart/test/cart_test.dart',
            'package:catalog_api/catalog_api.dart'),
        import('modules/cart/lib/cart.dart',
            'package:catalog_api/catalog_api.dart'),
      ],
    );
    final [violation] = checkBoundaries(packages);
    expect(violation.location, 'modules/cart/lib/cart.dart:1');
  });

  test('another package\'s src/ is private', () {
    expect(
        rulesBroken(workspace(cartImports: [
          import('modules/cart/lib/cart.dart',
              'package:catalog_api/src/product.dart'),
        ])),
        ['private']);
  });

  test('a package may import its own src/', () {
    expect(
        rulesBroken(workspace(cartImports: [
          import('modules/cart/test/cart_test.dart',
              'package:cart/src/cart_service.dart'),
        ])),
        isEmpty);
  });

  test('relative imports may not leave the package', () {
    final [violation] = checkBoundaries(workspace(cartImports: [
      import('modules/cart/lib/src/cart_service.dart',
          '../../../catalog/lib/src/stored_product_catalog.dart'),
    ]));
    expect(violation.rule, 'outside');
  });

  test('testing.dart libraries are for tests only', () {
    final [violation] = checkBoundaries(workspace(cartImports: [
      import('modules/cart/test/cart_test.dart',
          'package:catalog_api/testing.dart'),
      import('modules/cart/lib/cart.dart', 'package:catalog_api/testing.dart'),
    ]));
    expect(violation.rule, 'testing');
    expect(violation.location, 'modules/cart/lib/cart.dart:1');
  });

  test('contracts name what they use from other contracts', () {
    expect(
        rulesBroken(workspace(cartApiImports: [
          import('modules/cart_api/lib/src/cart.dart',
              'package:catalog_api/catalog_api.dart'),
        ])),
        ['show']);
  });

  test('cycles are reported once', () {
    final packages = [
      WorkspacePackage(
          name: 'a_api', dir: 'modules/a_api', dependencies: {'b_api'}),
      WorkspacePackage(
          name: 'b_api', dir: 'modules/b_api', dependencies: {'a_api'}),
    ];
    final [violation] = checkBoundaries(packages);
    expect(violation.rule, 'cycles');
    expect(violation.message, contains('a_api -> b_api -> a_api'));
  });

  test('the baseline tolerates known violations and only shrinks', () {
    final violations =
        checkBoundaries(workspace(cartDeps: {'core', 'catalog'}));
    const baseline = Baseline({'layers cart -> catalog', 'layers old -> gone'});

    final (:fresh, :known, :fixed) = baseline.apply(violations);
    expect(fresh, isEmpty);
    expect(known.single.key, 'layers cart -> catalog');
    expect(fixed, ['layers old -> gone']);
  });
}
