import 'package:bazaar_kiosk/kiosk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:module_contract/module_contract.dart';

void main() {
  late ModuleHost host;

  setUp(() async => host = await startKiosk());
  tearDown(() => host.stop());

  testWidgets('the kiosk shows the showroom, with no navigation bar', (
    tester,
  ) async {
    await tester.pumpWidget(KioskApp(host: host));
    await tester.pumpAndSettle();

    expect(find.text('Brass Desk Lamp'), findsOneWidget);
    expect(find.text('Linen Notebook'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('product pages have no "Add to cart": no cart is installed', (
    tester,
  ) async {
    await tester.pumpWidget(KioskApp(host: host));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Brass Desk Lamp'));
    await tester.pumpAndSettle();

    expect(find.text(r'$49.00'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('the kiosk wears its own brand, from the same design system', (
    tester,
  ) async {
    await tester.pumpWidget(KioskApp(host: host));
    await tester.pumpAndSettle();
    final theme = Theme.of(tester.element(find.byType(Scaffold).first));
    expect(
      theme.colorScheme.primary,
      ColorScheme.fromSeed(seedColor: kioskBrand).primary,
    );
  });

  test('every service the kiosk registers can be built', () {
    expect(
      host.di.findAll<Object>(
        instantiateLazySingletons: true,
        callFactories: true,
      ),
      isNotEmpty,
    );
  });
}
