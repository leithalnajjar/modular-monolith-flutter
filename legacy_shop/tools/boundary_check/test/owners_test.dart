import 'package:boundary_check/boundary_check.dart';
import 'package:test/test.dart';

final _packages = [
  WorkspacePackage(name: 'core', dir: 'shared/core'),
  WorkspacePackage(name: 'cart_api', dir: 'modules/cart_api'),
  WorkspacePackage(name: 'cart', dir: 'modules/cart'),
];

List<String> _problems(String codeowners) => [
      for (final v in checkOwners(_packages, CodeOwners.parse(codeowners)))
        v.message,
    ];

void main() {
  test('every package with an owner of its own is fine', () {
    expect(_problems('''
# Everything else
*                   @your-org/architecture
/shared/            @your-org/architecture
/modules/cart/      @your-org/cart
/modules/cart_api/  @your-org/cart
'''), isEmpty);
  });

  test('the catch-all line is not an owner of its own', () {
    expect(_problems('''
*                   @your-org/architecture
/shared/            @your-org/architecture
/modules/cart/      @your-org/cart
'''), [contains('modules/cart_api has no owner of its own')]);
  });

  test('the last matching line wins, as on GitHub', () {
    final owners = CodeOwners.parse('''
/modules/           @your-org/everyone
/modules/cart/      @your-org/cart
''');
    expect(owners.ruleFor('modules/cart')?.owners, ['@your-org/cart']);
    expect(owners.ruleFor('modules/cart_api')?.owners, ['@your-org/everyone']);
  });

  test('a line for a package that no longer exists is reported', () {
    expect(_problems('''
/shared/            @your-org/architecture
/modules/           @your-org/shop
/modules/wishlist/  @your-org/wishlist
'''), [contains('/modules/wishlist/ matches no package')]);
  });
}
