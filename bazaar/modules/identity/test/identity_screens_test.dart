import 'package:flutter_test/flutter_test.dart';
import 'package:identity/identity.dart';
import 'package:identity_api/identity_api.dart';
import 'package:material_ui/material_ui.dart';
import 'package:module_contract/module_contract.dart';

void main() {
  late ModuleHost host;

  setUp(() async {
    host = await ModuleHost.start(
      modules: [const IdentityModule()],
      initialLocation: IdentityRoutes.account,
    );
  });

  tearDown(() => host.stop());

  Widget app() => MaterialApp.router(routerConfig: host.router);

  testWidgets('account is guarded; signing in returns to it', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // The guard sent us to sign in.
    expect(find.text('Sign in'), findsWidgets);

    await tester.enterText(find.byKey(const Key('email')), 'demo@bazaar.dev');
    await tester.enterText(find.byKey(const Key('password')), 'wrong');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Wrong email or password'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('password')), 'bazaar123');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    // Back where we wanted to go.
    expect(find.text('Signed in as Demo Shopper'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(host.di<Session>().isSignedIn, isFalse);
    expect(find.byKey(const Key('email')), findsOneWidget);
  });
}
