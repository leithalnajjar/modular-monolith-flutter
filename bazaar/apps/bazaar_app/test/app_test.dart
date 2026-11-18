import 'package:bazaar_app/main.dart';
import 'package:bazaar_app/modules.dart';
import 'package:cart_api/cart_api.dart';
import 'package:catalog_api/catalog_api.dart';
import 'package:checkout_api/checkout_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity/identity.dart';
import 'package:identity_api/identity_api.dart';
import 'package:material_ui/material_ui.dart' show Key;
import 'package:module_contract/module_contract.dart';

void main() {
  late ModuleHost host;

  setUp(() async {
    host = await startBazaar();
  });

  tearDown(() => host.stop());

  testWidgets('the app opens on the catalog and navigates to a product', (
    tester,
  ) async {
    await tester.pumpWidget(BazaarApp(host: host));
    await tester.pumpAndSettle();

    expect(find.text('Products'), findsOneWidget);
    expect(find.text('Brass Desk Lamp'), findsOneWidget);
    expect(find.text('Out of stock'), findsOneWidget); // the mug

    await tester.tap(find.text('Linen Notebook'));
    await tester.pumpAndSettle();

    expect(find.text(r'$18.00'), findsOneWidget);
    expect(find.text('In stock'), findsOneWidget);
  });

  testWidgets('the cart adds its button to the catalog product page', (
    tester,
  ) async {
    host.router.go(CatalogRoutes.productDetails(const ProductId('p-1')));
    await tester.pumpWidget(BazaarApp(host: host));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add to cart'));
    await tester.pumpAndSettle();

    expect(find.text('Added Brass Desk Lamp to your cart'), findsOneWidget);
    expect(host.di<CartReader>().current.itemCount, 1);
  });

  testWidgets('signing out empties the cart, though identity knows nothing '
      'about carts', (tester) async {
    await host.di<SessionCommands>().signIn(
      DemoAuthGateway.email,
      DemoAuthGateway.password,
    );
    await host.di<CartCommands>().add(const ProductId('p-1'));
    expect(host.di<CartReader>().current.itemCount, 1);

    host.router.go(IdentityRoutes.account);
    await tester.pumpWidget(BazaarApp(host: host));
    await tester.pumpAndSettle();
    expect(find.text('Signed in as Demo Shopper'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(host.di<CartReader>().current.isEmpty, isTrue);
  });

  testWidgets('the shell shows every module entry, and the cart badge counts', (
    tester,
  ) async {
    await tester.pumpWidget(BazaarApp(host: host));
    await tester.pumpAndSettle();

    expect(find.text('Shop'), findsOneWidget);
    expect(find.text('Cart'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);

    await host.di<CartCommands>().add(const ProductId('p-1'), quantity: 2);
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget); // the badge

    await tester.tap(find.text('Cart'));
    await tester.pumpAndSettle();
    expect(find.text('Your cart'), findsOneWidget);
    expect(find.text(r'Total $98.00'), findsOneWidget);
  });

  testWidgets('a signed-in user checks out; the cart empties itself', (
    tester,
  ) async {
    await host.di<SessionCommands>().signIn(
      DemoAuthGateway.email,
      DemoAuthGateway.password,
    );
    await host.di<CartCommands>().add(const ProductId('p-1'), quantity: 2);

    await tester.pumpWidget(BazaarApp(host: host));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cart'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Checkout'));
    await tester.pumpAndSettle();

    expect(find.text(r'$98.00'), findsWidgets);
    await tester.tap(find.text('Place order'));
    await tester.pumpAndSettle();

    expect(find.text('Thank you! Your order is placed.'), findsOneWidget);
    expect(host.di<CartReader>().current.isEmpty, isTrue);

    await tester.tap(find.text('View orders'));
    await tester.pumpAndSettle();
    expect(find.text('Your orders'), findsOneWidget);
    expect(find.textContaining('2 items'), findsOneWidget);

    // Notifications heard OrderPlaced; nobody called it.
    await tester.tap(find.text('Inbox'));
    await tester.pumpAndSettle();
    expect(find.text('Order confirmed'), findsOneWidget);
  });

  testWidgets('checkout asks signed-out users to sign in first', (
    tester,
  ) async {
    await host.di<CartCommands>().add(const ProductId('p-1'));
    host.router.go(CheckoutRoutes.checkout);
    await tester.pumpWidget(BazaarApp(host: host));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('email')), findsOneWidget);
  });

  testWidgets('old /shop/item links still open the product', (tester) async {
    host.router.go('/shop/item/p-3');
    await tester.pumpWidget(BazaarApp(host: host));
    await tester.pumpAndSettle();

    expect(find.text('Linen Notebook'), findsOneWidget);
    expect(find.text(r'$18.00'), findsOneWidget);
    expect(
      host.router.routeInformationProvider.value.uri.toString(),
      '/products/p-3',
    );
  });

  testWidgets('a deep link to an unknown product shows a friendly message', (
    tester,
  ) async {
    host.router.go(CatalogRoutes.productDetails(const ProductId('gone')));
    await tester.pumpWidget(BazaarApp(host: host));
    await tester.pumpAndSettle();

    expect(find.text('This product is no longer available'), findsOneWidget);
  });
}
