import 'package:flutter_test/flutter_test.dart';
import 'package:shop/app_state.dart';
import 'package:shop/main.dart';
import 'package:shop/services/api_service.dart';

/// The characterization test: what the app does today, before anything
/// moves. Written first, kept green through every step of the migration.
void main() {
  setUp(ApiService.instance.reset);

  testWidgets('sign in, buy, get a message, sign out', (tester) async {
    final state = AppState();
    await tester.pumpWidget(ShopApp(state: state));
    await tester.tap(find.text('Sign in as demo'));
    await tester.pumpAndSettle();
    expect(find.text('Hello, Demo Shopper'), findsOneWidget);

    await tester.tap(find.byTooltip('Add Brass Desk Lamp'));
    await tester.tap(find.byTooltip('Add Brass Desk Lamp'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cart (1)'));
    await tester.pumpAndSettle();
    expect(find.text(r'$98.00'), findsWidgets);

    await tester.tap(find.text('Place order'));
    await tester.pumpAndSettle();
    expect(find.text('Inbox (2)'), findsOneWidget);

    await tester.tap(find.text('Inbox (2)'));
    await tester.pumpAndSettle();
    expect(find.text('Order confirmed'), findsOneWidget);
    expect(find.text(r'1 items, $98.00'), findsOneWidget);
    expect(find.text('Inbox (0)'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in as demo'), findsOneWidget);
    expect(state.notifications, isEmpty);
    expect(state.cart, isEmpty);
  });
}
