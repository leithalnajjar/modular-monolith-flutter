import 'package:boundary_check/boundary_check.dart';
import 'package:test/test.dart';

void main() {
  final app = WorkspacePackage(name: 'shop', dir: 'apps/shop', imports: const [
    ImportRef(file: 'apps/shop/lib/a.dart', line: 1, uri: '../app_state.dart'),
    ImportRef(
        file: 'apps/shop/lib/b.dart',
        line: 1,
        uri: 'package:shop/app_state.dart'),
    ImportRef(file: 'apps/shop/lib/c.dart', line: 1, uri: 'state.dart'),
  ]);
  final inbox = WorkspacePackage(name: 'inbox', dir: 'modules/inbox');

  test('counts imports of a file however they are written', () {
    expect(importsOf([app, inbox], 'app_state.dart'), 2);
  });

  test('shows each package\'s share of the code', () {
    final table = formatSizes([
      PackageSize(app, 9, 750),
      PackageSize(inbox, 3, 250),
    ]);
    expect(table, contains('75%'));
    expect(table, contains('25%'));
  });
}
