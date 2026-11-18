import 'package:boundary_check/boundary_check.dart';
import 'package:test/test.dart';

void main() {
  test('lists layers, owners, dependencies and dependents', () {
    final map = moduleMap([
      WorkspacePackage(name: 'core', dir: 'shared/core'),
      WorkspacePackage(
          name: 'cart', dir: 'modules/cart', dependencies: {'core', 'http'}),
    ], CodeOwners.parse('/modules/cart/ @your-org/cart'));

    expect(map, contains('| `shared/core` | shared |  |  | cart |'));
    expect(map,
        contains('| `modules/cart` | module | @your-org/cart | core |  |'));
  });
}
