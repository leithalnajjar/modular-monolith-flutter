import 'package:boundary_check/boundary_check.dart';
import 'package:test/test.dart';

final _packages = [
  WorkspacePackage(name: 'core', dir: 'shared/core'),
  WorkspacePackage(
      name: 'ui_kit', dir: 'shared/ui_kit', dependencies: {'core'}),
  WorkspacePackage(
      name: 'catalog_api', dir: 'modules/catalog_api', dependencies: {'core'}),
  WorkspacePackage(
      name: 'catalog',
      dir: 'modules/catalog',
      dependencies: {'core', 'catalog_api', 'ui_kit'}),
  WorkspacePackage(
      name: 'cart',
      dir: 'modules/cart',
      dependencies: {'core', 'catalog_api', 'ui_kit'}),
  WorkspacePackage(
      name: 'app', dir: 'apps/app', dependencies: {'catalog', 'cart'}),
];

List<String> affected(List<String> files) =>
    [for (final p in affectedPackages(_packages, files)) p.name];

void main() {
  test('a change inside a module affects it and the app', () {
    expect(
        affected(['modules/cart/lib/src/cart_service.dart']), ['cart', 'app']);
  });

  test('a contract change reaches every module that uses it', () {
    expect(affected(['modules/catalog_api/lib/src/product.dart']),
        ['catalog_api', 'catalog', 'cart', 'app']);
  });

  test('shared code affects nearly everything', () {
    expect(affected(['shared/ui_kit/lib/src/theme.dart']),
        ['ui_kit', 'catalog', 'cart', 'app']);
  });

  test('a workspace-wide file affects everything', () {
    expect(affected(['pubspec.lock']), hasLength(_packages.length));
  });

  test('Windows separators and blank lines are fine', () {
    expect(affected([r'modules\cart\test\x_test.dart', '']), ['cart', 'app']);
  });
}
