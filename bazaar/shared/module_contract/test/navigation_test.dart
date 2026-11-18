import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:module_contract/module_contract.dart';

/// Stands in for identity_api's session contract (Chapter 11).
final class _FakeSession {
  bool signedIn = false;
}

/// A module whose /account route is guarded: signed-out users are sent to
/// /sign-in, which remembers where they wanted to go.
final class _AccountModule extends FeatureModule {
  _AccountModule(this.session);
  final _FakeSession session;

  @override
  String get name => 'account';

  @override
  void register(GetIt di) {}

  @override
  List<RouteBase> routes(GetIt di) => [
        GoRoute(
          path: '/sign-in',
          builder: (_, state) =>
              Text('Sign in to continue to ${state.uri.queryParameters['from']}'),
        ),
        GoRoute(
          path: '/account',
          redirect: (_, state) => session.signedIn
              ? null
              : Uri(path: '/sign-in', queryParameters: {
                  'from': state.uri.toString(),
                }).toString(),
          builder: (_, __) => const Text('My account'),
        ),
      ];
}

/// A module that lets *another* module pick a value and get it back.
final class _PickerModule extends FeatureModule {
  @override
  String get name => 'picker';

  @override
  void register(GetIt di) {}

  @override
  List<RouteBase> routes(GetIt di) => [
        GoRoute(
          path: '/pick-colour',
          builder: (context, _) => GestureDetector(
            onTap: () => context.pop('teal'),
            child: const Text('teal'),
          ),
        ),
      ];
}

/// The caller: pushes the picker by location and awaits the result.
final class _HomeModule extends FeatureModule {
  @override
  String get name => 'home';

  @override
  void register(GetIt di) {}

  @override
  List<RouteBase> routes(GetIt di) =>
      [GoRoute(path: '/', builder: (_, __) => const _Home())];
}

class _Home extends StatefulWidget {
  const _Home();

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  String _colour = 'none';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await context.push<String>('/pick-colour');
        if (picked != null) setState(() => _colour = picked);
      },
      child: Text('Colour: $_colour'),
    );
  }
}

Widget _app(ModuleHost host) => WidgetsApp.router(
      routerConfig: host.router,
      color: const Color(0xFF2E7D6B),
    );

void main() {
  testWidgets('a guarded route sends signed-out users to sign in',
      (tester) async {
    final session = _FakeSession();
    final host = await ModuleHost.start(
        modules: [_AccountModule(session)], initialLocation: '/account');
    addTearDown(host.stop);

    await tester.pumpWidget(_app(host));
    await tester.pumpAndSettle();
    expect(find.text('Sign in to continue to /account'), findsOneWidget);

    session.signedIn = true;
    host.router.go('/account');
    await tester.pumpAndSettle();
    expect(find.text('My account'), findsOneWidget);
  });

  testWidgets('a module can return a result to another module',
      (tester) async {
    final host =
        await ModuleHost.start(modules: [_HomeModule(), _PickerModule()]);
    addTearDown(host.stop);

    await tester.pumpWidget(_app(host));
    await tester.pumpAndSettle();
    expect(find.text('Colour: none'), findsOneWidget);

    await tester.tap(find.text('Colour: none'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('teal'));
    await tester.pumpAndSettle();

    expect(find.text('Colour: teal'), findsOneWidget);
  });
}
